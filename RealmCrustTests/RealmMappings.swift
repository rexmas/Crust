/// Include this file and `RLMSupport.swift` in order to use `RealmMapping` and `RealmAdapter` and map to `RLMObject` using `Crust`.

import Foundation
import Crust
import JSONValueRX
import Realm
import RealmSwift

public let RealmAdapterDomain = "RealmAdapterDomain"

public class RealmAdapter: Adapter {
    
    public typealias BaseType = RLMObject
    public typealias ResultsType = [BaseType]
    
    private var cache: Set<BaseType>
    public let realm: RLMRealm
    public let dataBaseTag: String = DefaultDatabaseTag.realm.rawValue
    public var requiresPrimaryKeys = false
    
    public required init(realm: RLMRealm) {
        self.realm = realm
        self.cache = []
    }
    
    public convenience init() throws {
        self.init(realm: RLMRealm.default())
    }
    
    public var isInTransaction: Bool {
        return self.realm.inWriteTransaction
    }
    
    public func mappingWillBegin() throws {
        self.realm.beginWriteTransaction()
    }
    
    public func mappingDidEnd() throws {
        try self.realm.commitWriteTransaction()
        self.cache.removeAll()
    }
    
    public func mappingErrored(_ error: Error) {
        if self.realm.inWriteTransaction {
            self.realm.cancelWriteTransaction()
        }
        self.cache.removeAll()
    }
    
    public func createObject(type: RLMObject.Type) throws -> RLMObject {
        let obj = type.init()
        self.cache.insert(obj)
        return obj
    }
    
    public func save(objects: [BaseType]) throws {
        let saveBlock = {
            for obj in objects {
                self.cache.remove(obj)
                if obj.objectSchema.primaryKeyProperty != nil {
                    self.realm.addOrUpdate(obj)
                }
                else if !self.requiresPrimaryKeys {
                    self.realm.add(obj)
                }
                else {
                    let userInfo = [ NSLocalizedFailureReasonErrorKey : "Adapter requires primary keys but obj of type \(type(of: obj)) does not have one" ]
                    throw NSError(domain: RealmAdapterDomain, code: -1, userInfo: userInfo)
                }
            }
        }
        if self.realm.inWriteTransaction {
            try saveBlock()
        }
        else {
            self.realm.beginWriteTransaction()
            try saveBlock()
            try self.realm.commitWriteTransaction()
        }
    }
    
    public func deleteObject(_ obj: BaseType) throws {
        let deleteBlock = {
            self.cache.remove(obj)
            self.realm.delete(obj)
        }
        if self.realm.inWriteTransaction {
            deleteBlock()
        }
        else {
            self.realm.beginWriteTransaction()
            deleteBlock()
            try self.realm.commitWriteTransaction()
        }
    }
    
    public func sanitize(primaryKeyProperty property: String, forValue value: CVarArg, ofType type: RLMObject.Type) -> CVarArg? {
        
        // Since Date is converted as such so often we won't require implementors to write their own transform.
        if type.isProperty(property, ofType: NSDate.self), case let value as String = value {
            return Date(isoString: value)! as NSDate
        }
        return type.sanitizeValue(value, fromProperty: property, realm: self.realm)
    }
    
    // TODO: This should throw and we should check that the primary key's type and value's sanitized type match.
    // Otherwise we get an exception from Realm here.
    public func fetchObjects(type: RLMObject.Type, primaryKeyValues: [[String : CVarArg]], isMapping: Bool) -> ResultsType? {
        
        var totalPredicate = [NSPredicate]()
        
        for keyValues in primaryKeyValues {
            var objectPredicates = [NSPredicate]()
            for (key, var value) in keyValues {
                value = self.sanitize(primaryKeyProperty: key, forValue: value, ofType: type) ?? value
                let predicate = NSPredicate(format: "%K == %@", key, value)
                objectPredicates.append(predicate)
            }
            let objectPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: objectPredicates)
            totalPredicate.append(objectPredicate)
        }
        
        let orPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: totalPredicate)
        
        return fetchObjects(type: type, predicate: orPredicate, isMapping: isMapping)
    }
    
    public func fetchObjects(type: BaseType.Type, predicate: NSPredicate, isMapping: Bool) -> ResultsType? {
        
        var objects = self.cache.filter {
            type(of: $0) == type
        }
        .filter {
            predicate.evaluate(with: $0)
        }

        if objects.count > 0 {
            return Array(objects)
        }
        
        let results = type.objects(in: realm, with: predicate)
        for obj in results {
            objects.append(obj)
        }
        return objects
    }
}

public protocol RealmMapping: Mapping {
    associatedtype AdapterKind = RealmAdapter
    init(adapter: AdapterKind)
}

extension RLMArray {
    public func findIndex(of object: RLMObject) -> UInt {
        guard case let index as UInt = self.index(ofObjectNonGeneric: object) else {
            return UInt.max
        }
        return index
    }
    
    public typealias Index = UInt
    
    public func append(_ newElement: RLMObject) {
        self.addObjectNonGeneric(newElement)
    }
    
    public func append(contentsOf newElements: [RLMObject]) {
        for obj in newElements {
            self.addObjectNonGeneric(obj)
        }
    }
    
    public func remove(at i: UInt) {
        self.removeObject(at: i)
    }
    
    public func removeAll(keepingCapacity keepCapacity: Bool) {
        self.removeAllObjects()
    }
}

public class RealmSwiftObjectAdapterBridge<T>: Adapter {
    public typealias BaseType = T
    public typealias ResultsType = [BaseType]
    
    public let realmObjCAdapter: RealmAdapter
    public let rlmObjectType: RLMObject.Type
    public let dataBaseTag: String = DefaultDatabaseTag.realm.rawValue
    
    public init(realmObjCAdapter: RealmAdapter, rlmObjectType: RLMObject.Type) {
        self.realmObjCAdapter = realmObjCAdapter
        self.rlmObjectType = rlmObjectType
    }
    
    public var isInTransaction: Bool {
        return self.realmObjCAdapter.isInTransaction
    }
    
    public func mappingWillBegin() throws {
        try self.realmObjCAdapter.mappingWillBegin()
    }
    
    public func mappingDidEnd() throws {
        try self.realmObjCAdapter.mappingDidEnd()
    }
    
    public func mappingErrored(_ error: Error) {
        self.realmObjCAdapter.mappingErrored(error)
    }
    
    public func createObject(type: BaseType.Type) throws -> BaseType {
        let obj = try self.realmObjCAdapter.createObject(type: self.rlmObjectType)
        return unsafeBitCast(obj, to: BaseType.self)
    }
    
    public func save(objects: [BaseType]) throws {
        let rlmObjs = objects.map { unsafeDowncast($0 as AnyObject, to: type(of: self.realmObjCAdapter).BaseType.self) }
        try self.realmObjCAdapter.save(objects: rlmObjs)
    }
    
    public func deleteObject(_ obj: BaseType) throws {
        let rlmObj = unsafeDowncast(obj as AnyObject, to: type(of: self.realmObjCAdapter).BaseType.self)
        try self.realmObjCAdapter.deleteObject(rlmObj)
    }
    
    public func sanitize(primaryKeyProperty property: String, forValue value: CVarArg, ofType type: BaseType.Type) -> CVarArg? {
        return self.realmObjCAdapter.sanitize(primaryKeyProperty: property, forValue: value, ofType: type as! RLMObject.Type)
    }
    
    public func fetchObjects(type: BaseType.Type, primaryKeyValues: [[String : CVarArg]], isMapping: Bool) -> ResultsType? {
        guard let rlmObjects = self.realmObjCAdapter.fetchObjects(type: self.rlmObjectType,
                                                                  primaryKeyValues: primaryKeyValues,
                                                                  isMapping: isMapping)
            else {
                return nil
        }
        
        return rlmObjects.map { unsafeBitCast($0, to: BaseType.self) }
    }
}

/// Wrapper used to map `RLMObjects`. Relies on `RLMArrayBridge` since `RLMArray` does not support `RangeReplaceableCollection`.
public class RLMArrayMappingBridge<T: RLMObject, K: Keypath>: Mapping {
    public typealias MappedObject = T
    
    public let adapter: RealmSwiftObjectAdapterBridge<MappedObject>
    public let primaryKeys: [Mapping.PrimaryKeyDescriptor]?
    public let rlmObjectMapping: (inout MappedObject, MappingContext<K>) throws -> Void
    
    public required init<OGMapping: RealmMapping>(rlmObjectMapping: OGMapping) where OGMapping.MappedObject: RLMObject, OGMapping.MappedObject == T, OGMapping.CodingKeys == K {
        
        self.adapter = RealmSwiftObjectAdapterBridge(realmObjCAdapter: rlmObjectMapping.adapter as! RealmAdapter,
                                                     rlmObjectType: OGMapping.MappedObject.self)
        self.primaryKeys = rlmObjectMapping.primaryKeys
        
        self.rlmObjectMapping = { (toMap: inout MappedObject, context: MappingContext<K>) throws -> Void in
            var ogObject = unsafeDowncast(toMap, to: OGMapping.MappedObject.self)
            try rlmObjectMapping.mapping(toMap: &ogObject, context: context)
        }
    }
    
    public final func mapping(toMap: inout MappedObject, context: MappingContext<K>) throws {
        try self.rlmObjectMapping(&toMap, context)
    }
}

public extension Binding where M: RealmMapping, M.MappedObject: RLMObject {
    
    func generateRLMArrayMappingBridge() -> Binding<K, RLMArrayMappingBridge<M.MappedObject, M.CodingKeys>> {
        
        switch self {
        case .mapping(let keyPath, let mapping):
            let bridge = RLMArrayMappingBridge(rlmObjectMapping: mapping)
            return .mapping(keyPath, bridge)
            
        case .collectionMapping(let keyPath, let mapping, let updatePolicy):
            let bridge = RLMArrayMappingBridge<M.MappedObject, M.CodingKeys>(rlmObjectMapping: mapping)
            return .collectionMapping(keyPath, bridge, updatePolicy)
        }
    }
}

@discardableResult
public func <- <U: RealmMapping, K: Keypath, C: MappingContext<K>>(field: RLMArray<U.MappedObject>, binding:(key: Binding<K, U>, context: C)) -> C {
    
    return map(toRLMArray: field, using: binding)
}

@discardableResult
public func map<U: RealmMapping, K: Keypath, C: MappingContext<K>>(toRLMArray field: RLMArray<U.MappedObject>, using binding:(key: Binding<K, U>, context: C)) -> C {
    
    var variableList = RLMArrayBridge(rlmArray: field)
    let bridge = binding.key.generateRLMArrayMappingBridge()
    return map(toCollection: &variableList, using: (bridge, binding.context))
}
