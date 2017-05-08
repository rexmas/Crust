import Foundation
import JSONValueRX

public enum MappingDirection {
    case fromJSON
    case toJSON
}

internal let CrustMappingDomain = "CrustMappingDomain"

open class MappingContext<K: Keypath> {
    open internal(set) var json: JSONValue
    open internal(set) var keys: Set<K>
    open internal(set) var object: Any
    open internal(set) var error: Error?
    open internal(set) var parent: MappingContext<AnyKeyPath>? = nil
    open internal(set) var adapterType: String
    open fileprivate(set) var dir: MappingDirection
    
    init(withObject object: Any, json: JSONValue, keys: Set<K>, adapterType: String, direction: MappingDirection) {
        self.object = object
        self.json = json
        self.keys = keys
        self.adapterType = adapterType
        self.dir = direction
    }
    
    internal func typeErased() -> MappingContext<AnyKeyPath> {
        let keys = Set(self.keys.map { AnyKeyPath($0) })
        let parent = MappingContext<AnyKeyPath>(withObject: self.object, json: self.json, keys: keys, adapterType: self.adapterType, direction: self.dir)
        parent.error = self.error
        parent.parent = self.parent
        return parent
    }
}

/// Method caller used to perform mappings.
public struct Mapper {
    
    public init() { }
    
    public func map<M: Mapping, C: RangeReplaceableCollection, K: Keypath>(from json: JSONValue, using binding: Binding<K, M>, keyedBy keys: Set<M.CodingKeys>) throws -> C
    where M.MappedObject == C.Iterator.Element, M.MappedObject: Equatable {
        
        var collection = C()
        let codingKey = NestedCodingKey(rootKey: binding.key, nestedKeys: keys)
        let context = MappingContext(withObject: collection, json: json, keys: [codingKey], adapterType: binding.mapping.adapter.dataBaseTag, direction: MappingDirection.fromJSON)
        let nestedBinding = binding.nestedBinding(for: keys)
        
        try nestedBinding.mapping.start(context: context)
        collection <- (nestedBinding, context)
        try nestedBinding.mapping.completeMapping(collection: collection, context: context)
        
        return collection
    }
    
    public func map<M: Mapping, C: RangeReplaceableCollection, K: Keypath>(from json: JSONValue, using binding: Binding<K, M>, keyedBy keys: Set<M.CodingKeys>) throws -> C
        where M.MappedObject == C.Iterator.Element {
            
            var collection = C()
            let codingKey = NestedCodingKey(rootKey: binding.key, nestedKeys: keys)
            let context = MappingContext(withObject: collection, json: json, keys: [codingKey], adapterType: binding.mapping.adapter.dataBaseTag, direction: MappingDirection.fromJSON)
            let nestedBinding = binding.nestedBinding(for: keys)
            
            try nestedBinding.mapping.start(context: context)
            collection <- (nestedBinding, context)
            try nestedBinding.mapping.completeMapping(collection: collection, context: context)
            
            return collection
    }
    
    public func map<M: Mapping, K: Keypath, KP: Keypath>(from json: JSONValue, using binding: Binding<K, M>, keyedBy keys: Set<M.CodingKeys>, parentContext: MappingContext<KP>? = nil) throws -> M.MappedObject {
        
        // TODO: Figure out better ways to represent `nil` keyPaths than `""`.
        let baseJson = try baseJSON(from: json, via: binding.keyPath, ifIn: [binding.keyPath]) ?? json
        
        var object = try binding.mapping.fetchOrCreateObject(from: baseJson)
        let codingKey = NestedCodingKey(rootKey: binding.key, nestedKeys: keys)
        let context = MappingContext(withObject: object, json: json, keys: [codingKey], adapterType: binding.mapping.adapter.dataBaseTag, direction: MappingDirection.fromJSON)
        let nestedBinding = binding.nestedBinding(for: keys)
        context.parent = parentContext?.typeErased()
        
        let mapping = nestedBinding.mapping
        try mapping.start(context: context)
        object <- (nestedBinding, context)
        try mapping.complete(object: &object, context: context)
        
        return object
    }
    
    public func map<M: Mapping, KP: Keypath>(from json: JSONValue, using mapping: M, keyedBy keys: Set<M.CodingKeys>, parentContext: MappingContext<KP>? = nil) throws -> M.MappedObject {
        let object = try mapping.fetchOrCreateObject(from: json)
        return try map(from: json, to: object, using: mapping, keyedBy: keys, parentContext: parentContext)
    }
    
    public func map<M: Mapping, KP: Keypath>(from json: JSONValue, to object: M.MappedObject, using mapping: M, keyedBy keys: Set<M.CodingKeys>, parentContext: MappingContext<KP>? = nil) throws -> M.MappedObject {
        var object = object
        let context = MappingContext(withObject: object, json: json, keys: keys, adapterType: mapping.adapter.dataBaseTag, direction: MappingDirection.fromJSON)
        context.parent = parentContext?.typeErased()
        try self.perform(mapping, on: &object, with: context)
        return object
    }
    
    public func mapFromObjectToJSON<M: Mapping>(_ object: M.MappedObject, mapping: M, keyedBy keys: Set<M.CodingKeys>) throws -> JSONValue {
        var object = object
        let context = MappingContext(withObject: object, json: JSONValue.object([:]), keys: keys, adapterType: mapping.adapter.dataBaseTag, direction: MappingDirection.toJSON)
        try self.perform(mapping, on: &object, with: context)
        return context.json
    }
    
    internal func perform<M: Mapping>(_ mapping: M, on object: inout M.MappedObject, with context: MappingContext<M.CodingKeys>) throws {
        try mapping.start(context: context)
        mapping.execute(object: &object, context: context)
        try mapping.complete(object: &object, context: context)
    }
}

public extension Mapping {
    public func fetchOrCreateObject(from json: JSONValue) throws -> MappedObject {
        guard let primaryKeyValues = try self.primaryKeyValuePairs(from: json) else {
            return try self.generateNewInstance()
        }
        
        let (object, newInstance) = try { () -> (MappedObject, Bool) in
            guard let object = try self.fetchExistingInstance(json: json, primaryKeyValues: primaryKeyValues) else {
                return try (self.generateNewInstance(), true)
            }
            return (object, false)
        }()
        
        if case let nsObject as NSObject = object, newInstance {
            primaryKeyValues.forEach { (key, value) in
                nsObject.setValue(value, forKey: key)
            }
        }
        
        return object
    }
    
    public func primaryKeyValuePairs(from json: JSONValue) throws -> [String: CVarArg]? {
        guard let primaryKeys = self.primaryKeys else {
            return nil
        }
        
        try self.checkForAdapterBaseTypeConformance()
        
        var keyValues = [String : CVarArg]()
        try primaryKeys.forEach { (primaryKey, keyPath, transform) in
            let key = keyPath?.keyPath
            let baseJson = key != nil ? json[key!] : json
            if let val = baseJson {
                let transformedVal: CVarArg = try transform?(val) ?? val.valuesAsNSObjects()
                let sanitizedVal = self.adapter.sanitize(primaryKeyProperty: primaryKey,
                                                         forValue: transformedVal,
                                                         ofType: MappedObject.self as! AdapterKind.BaseType.Type)
                
                keyValues[primaryKey] = sanitizedVal ?? transformedVal
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "Primary key of \(String(describing: keyPath)) does not exist in JSON but is expected from mapping \(Self.self)" ]
                throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
            }
        }
        return keyValues
    }
    
    func fetchExistingInstance(json: JSONValue, primaryKeyValues: [String : CVarArg]?) throws -> MappedObject? {
        
        try self.checkForAdapterBaseTypeConformance()
        
        guard let keyValues = try (primaryKeyValues ?? self.primaryKeyValuePairs(from: json)) else {
            return nil
        }
        
        guard let obj = self.adapter.fetchObjects(type: MappedObject.self as! AdapterKind.BaseType.Type, primaryKeyValues: [keyValues], isMapping: true)?.first else {
            return nil
        }
        
        return unsafeBitCast(obj, to: MappedObject.self)
    }
    
    func generateNewInstance() throws -> MappedObject {
        
        try self.checkForAdapterBaseTypeConformance()
        
        let obj = try self.adapter.createObject(type: MappedObject.self as! AdapterKind.BaseType.Type)
        return unsafeBitCast(obj, to: MappedObject.self)
    }
    
    func delete(obj: MappedObject) throws {
        try self.checkForAdapterBaseTypeConformance()
        
        try self.adapter.deleteObject(obj as! AdapterKind.BaseType)
    }
    
    internal func checkForAdapterBaseTypeConformance() throws {
        // NOTE: This sux but `MappedObject: AdapterKind.BaseType` as a type constraint throws a compiler error as of 7.1 Xcode
        // and `MappedObject == AdapterKind.BaseType` doesn't work with sub-types (i.e. expects MappedObject to be that exact type)
        
        guard MappedObject.self is AdapterKind.BaseType.Type else {
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "Type of object \(MappedObject.self) is not a subtype of \(AdapterKind.BaseType.self)" ]
            throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
        }
    }
    
    internal func start<K: Keypath>(context: MappingContext<K>) throws {
        try self.checkForAdapterBaseTypeConformance()
        if context.parent == nil || !self.adapter.isInTransaction {
            var underlyingError: NSError?
            do {
                try self.adapter.mappingWillBegin()
            } catch let err as NSError {    // We can handle NSErrors higher up.
                underlyingError = err
            } catch {
                var userInfo = [AnyHashable : Any]()
                userInfo[NSLocalizedFailureReasonErrorKey] = "Errored during mappingWillBegin for adapter \(self.adapter)"
                userInfo[NSUnderlyingErrorKey] = underlyingError
                throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
            }
        }
    }
    
    internal func endMapping<K: Keypath>(context: MappingContext<K>) throws {
        let shouldCallEndMapping = { () -> Bool in 
            guard context.parent != nil else {
                return true
            }
            
            // Walk parent contexts, if using the same adapter type assume that we'll call end mapping later.
            let adapterType = context.adapterType
            var context: MappingContext<AnyKeyPath> = context.typeErased()
            while let parent = context.parent {
                if parent.adapterType == adapterType {
                    return false
                }
                context = parent
            }
            
            return true
        }()
        
        if shouldCallEndMapping {
            var underlyingError: NSError?
            do {
                try self.adapter.mappingDidEnd()
            } catch let err as NSError {
                underlyingError = err
            } catch {
                var userInfo = [AnyHashable : Any]()
                userInfo[NSLocalizedFailureReasonErrorKey] = "Errored during mappingDidEnd for adapter \(self.adapter)"
                userInfo[NSUnderlyingErrorKey] = underlyingError
                throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
            }
        }
    }
    
    public func execute(object: inout MappedObject, context: MappingContext<CodingKeys>) {
        do {
            try self.mapping(toMap: &object, context: context)
        }
        catch let e {
            context.error = e
        }
    }
    
    internal func complete<K: Keypath>(object: inout MappedObject, context: MappingContext<K>) throws {
        try self.completeMapping(objects: [object], context: context)
        context.object = object
    }
    
    internal func completeMapping<C: Sequence, K: Keypath>(collection: C, context: MappingContext<K>) throws where C.Iterator.Element == MappedObject {
        try self.completeMapping(objects: collection, context: context)
        context.object = collection
    }
    
    internal func completeMapping<C: Sequence, K: Keypath>(objects: C, context: MappingContext<K>) throws where C.Iterator.Element == MappedObject {
        if context.error == nil {
            do {
                try self.checkForAdapterBaseTypeConformance()
                let objects = objects.map { unsafeBitCast($0, to: AdapterKind.BaseType.self) }
                try self.adapter.save(objects: objects)
            }
            catch let error {
                context.error = error
            }
        }
        
        if let error = context.error {
            if context.parent == nil {
                self.adapter.mappingErrored(error)
            }
            throw error
        }
        
        try self.endMapping(context: context)
    }
}
