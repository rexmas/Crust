/// Include this file and `RLMSupport.swift` in order to use `RealmMapping` and `RealmAdaptor` and map to `RLMObject` using `Crust`.

import Foundation
import Crust
import JSONValueRX
import Realm
import RealmSwift

public let RealmAdaptorDomain = "RealmAdaptorDomain"

public class RealmAdaptor: Adaptor {
    
    public typealias BaseType = RLMObject
    public typealias ResultsType = [BaseType]
    
    private var cache: Set<BaseType>
    public let realm: RLMRealm
    public var requiresPrimaryKeys = false
    
    public init(realm: RLMRealm) {
        self.realm = realm
        self.cache = []
    }
    
    public convenience init() throws {
        self.init(realm: RLMRealm.default())
    }
    
    public func mappingBegins() throws {
        self.realm.beginWriteTransaction()
    }
    
    public func mappingEnded() throws {
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
                    let userInfo = [ NSLocalizedFailureReasonErrorKey : "Adaptor requires primary keys but obj of type \(type(of: obj)) does not have one" ]
                    throw NSError(domain: RealmAdaptorDomain, code: -1, userInfo: userInfo)
                }
            }
        }
        if self.realm.inWriteTransaction {
            try saveBlock()
        } else {
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
        } else {
            self.realm.beginWriteTransaction()
            deleteBlock()
            try self.realm.commitWriteTransaction()
        }
    }
    
    public func fetchObjects(type: RLMObject.Type, primaryKeyValues: [[String : CVarArg]], isMapping: Bool) -> ResultsType? {
        
        // Really we should be using either a mapping associated with the primary key or the primary key's
        // Type's `fromJson(_:)` method. Unfortunately that method comes from JSONable which you cannot
        // dynamically typecast to and Swift's reflection system doesn't appear fully baked enough to safely
        // get the actual type of the property to call it's conversion method (Optional values aren't
        // properly reflected coming from sources on SO). In the meantime we'll have to convert here on a
        // case-by-case basis and possibly integrate better generics or primary key method mappings in the future.
        
        func sanitize(key: String, value: NSObject) -> NSObject {
            if type.isProperty(key, ofType: NSDate.self), case let value as String = value {
                return Date(isoString: value)! as NSDate
            }
            return type.sanitizeValue(value, fromProperty: key, realm: self.realm)
        }
        
        var totalPredicate = [NSPredicate]()
        
        for keyValues in primaryKeyValues {
            var objectPredicates = [NSPredicate]()
            for (key, var value) in keyValues {
                if case let obj as NSObject = value {
                    value = sanitize(key: key, value: obj)
                }
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
        
        // Since we use this function to fetch existing objects to map to, but we can't remap the primary key,
        // we're going to build an unstored object and update when saving based on the primary key.
        //guard !isMapping || type.primaryKey() == nil else {
        //    return nil
        //}
        
        let results = type.objects(in: realm, with: predicate)
        for obj in results {
            objects.append(obj)
        }
        return objects
    }
}

public protocol RealmMapping: Mapping {
    associatedtype AdaptorKind = RealmAdaptor
    init(adaptor: AdaptorKind)
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

public class RealmSwiftObjectAdaptorBridge<T>: Adaptor {
    public typealias BaseType = T
    public typealias ResultsType = [BaseType]
    
    public let realmObjCAdaptor: RealmAdaptor
    public let rlmObjectType: RLMObject.Type
    
    public init(realmObjCAdaptor: RealmAdaptor, rlmObjectType: RLMObject.Type) {
        self.realmObjCAdaptor = realmObjCAdaptor
        self.rlmObjectType = rlmObjectType
    }
    
    public func mappingBegins() throws {
        try self.realmObjCAdaptor.mappingBegins()
    }
    
    public func mappingEnded() throws {
        try self.realmObjCAdaptor.mappingEnded()
    }
    
    public func mappingErrored(_ error: Error) {
        self.realmObjCAdaptor.mappingErrored(error)
    }
    
    public func createObject(type: BaseType.Type) throws -> BaseType {
        let obj = try self.realmObjCAdaptor.createObject(type: self.rlmObjectType)
        return unsafeBitCast(obj, to: BaseType.self)
    }
    
    public func save(objects: [BaseType]) throws {
        let rlmObjs = objects.map { unsafeBitCast($0, to: type(of: self.realmObjCAdaptor).BaseType.self) }
        try self.realmObjCAdaptor.save(objects: rlmObjs)
    }
    
    public func deleteObject(_ obj: BaseType) throws {
        let rlmObj = unsafeBitCast(obj, to: type(of: self.realmObjCAdaptor).BaseType.self)
        try self.realmObjCAdaptor.deleteObject(rlmObj)
    }
    
    public func fetchObjects(type: BaseType.Type, primaryKeyValues: [[String : CVarArg]], isMapping: Bool) -> ResultsType? {
        guard let rlmObjects = self.realmObjCAdaptor.fetchObjects(type: self.rlmObjectType,
                                                                  primaryKeyValues: primaryKeyValues,
                                                                  isMapping: isMapping)
            else {
                return nil
        }
        
        return rlmObjects.map { unsafeBitCast($0, to: BaseType.self) }
    }
}

/// Subclass this to map RLMObjects.

public class RealmSwiftObjectMappingBridge: Mapping {
    public typealias SequenceKind = ListWrapper<Object>
    
    public let adaptor: RealmSwiftObjectAdaptorBridge<Object>
    public let primaryKeys: [Mapping.PrimaryKeyDescriptor]?
    public let rlmObjectMapping: (inout RLMObject, MappingContext) -> Void
    
    public required init<OGMapping: RealmMapping>(rlmObjectMapping: OGMapping) where OGMapping.MappedObject: RLMObject {
        
        self.adaptor = RealmSwiftObjectAdaptorBridge(realmObjCAdaptor: rlmObjectMapping.adaptor as! RealmAdaptor,
                                                     rlmObjectType: OGMapping.MappedObject.self)
        self.primaryKeys = rlmObjectMapping.primaryKeys
        
        self.rlmObjectMapping = { (obj: inout RLMObject, context: MappingContext) -> Void in
            var rlmObj = obj as! OGMapping.MappedObject
            rlmObjectMapping.mapping(tomap: &rlmObj, context: context)
        }
    }
    
    public final func mapping(tomap: inout Object, context: MappingContext) {
        var ogObject = unsafeDowncast(tomap, to: RLMObject.self)
        self.rlmObjectMapping(&ogObject, context)
    }
}

public class RLMArrayMappingBridge<T: RLMObject>: Mapping {//where S.Iterator.Element == M {
    public typealias MappedObject = T
    public typealias SequenceKind = RLMArrayBridge<MappedObject>
    
    public let adaptor: RealmSwiftObjectAdaptorBridge<MappedObject>
    public let primaryKeys: [Mapping.PrimaryKeyDescriptor]?
    public let rlmObjectMapping: (inout MappedObject, MappingContext) -> Void
    
    public required init<OGMapping: RealmMapping>(rlmObjectMapping: OGMapping) where OGMapping.MappedObject: RLMObject, OGMapping.MappedObject == T {
        
        self.adaptor = RealmSwiftObjectAdaptorBridge(realmObjCAdaptor: rlmObjectMapping.adaptor as! RealmAdaptor,
                                                     rlmObjectType: OGMapping.MappedObject.self)
        self.primaryKeys = rlmObjectMapping.primaryKeys
        
        self.rlmObjectMapping = { (tomap: inout MappedObject, context: MappingContext) -> Void in
            var ogObject = unsafeDowncast(tomap, to: OGMapping.MappedObject.self)
            rlmObjectMapping.mapping(tomap: &ogObject, context: context)
        }
    }
    
    public final func mapping(tomap: inout MappedObject, context: MappingContext) {
        self.rlmObjectMapping(&tomap, context)
    }
}

public extension Binding where M: RealmMapping, M.MappedObject: RLMObject, M.SequenceKind.Iterator.Element == M.MappedObject {
    
    func generateRLMArrayMappingBridge() -> Binding<RLMArrayMappingBridge<M.MappedObject>> {
        
        switch self {
        case .mapping(let keyPath, let mapping):
            let bridge = RLMArrayMappingBridge(rlmObjectMapping: mapping)
            return .mapping(keyPath, bridge)
            
        case .collectionMapping(let keyPath, let mapping, let updatePolicy):
            let bridge = RLMArrayMappingBridge<M.MappedObject>(rlmObjectMapping: mapping)
            
            let bridgedInsert: CollectionInsertionMethod<RLMArrayBridge<M.MappedObject>> = {
                switch updatePolicy.insert {
                    
                case .append:
                    return .append
                    
                case .replace(let deletion):
                    guard let deletion = deletion else {
                        return .replace(delete: nil)
                    }
                    
                    let bridgedDeletion = { (objs: RLMArrayBridge<M.MappedObject>) -> RLMArrayBridge<M.MappedObject> in
                        let rlmObjsToDelete = deletion( objs.map { $0 } as! M.SequenceKind )
                        let listToDelete = RLMArrayBridge<M.MappedObject>()
                        for obj in rlmObjsToDelete {
                            listToDelete.append(obj)
                        }
                        return listToDelete
                    }
                    return .replace(delete: bridgedDeletion)
                }
            }()
            
            return .collectionMapping(keyPath, bridge, (insert: bridgedInsert, unique: updatePolicy.unique))
        }
    }
    
    func generateRealmSwiftObjectMappingBridge() -> Binding<RealmSwiftObjectMappingBridge> {
        
        switch self {
        case .mapping(let keyPath, let mapping):
            let bridge = RealmSwiftObjectMappingBridge(rlmObjectMapping: mapping)
            return .mapping(keyPath, bridge)
            
        case .collectionMapping(let keyPath, let mapping, let updatePolicy):
            let bridge = RealmSwiftObjectMappingBridge(rlmObjectMapping: mapping)
            let bridgedType = M.MappedObject.self
            
            let bridgedInsert: CollectionInsertionMethod<ListWrapper<Object>> = {
                switch updatePolicy.insert {
                    
                case .append:
                    return .append
                    
                case .replace(let deletion):
                    guard let deletion = deletion else {
                        return .replace(delete: nil)
                    }
                    
                    let bridgedDeletion = { (objs: ListWrapper<Object>) -> ListWrapper<Object> in
                        let rlmObjsToDelete = deletion( objs.map { unsafeDowncast($0, to: bridgedType) } as! M.SequenceKind )
                        let listToDelete = ListWrapper<Object>()
                        rlmObjsToDelete.forEach {
                            listToDelete.append(unsafeBitCast($0, to: Object.self))
                        }
                        return listToDelete
                    }
                    return .replace(delete: bridgedDeletion)
                }
            }()
            return .collectionMapping(keyPath, bridge, (insert: bridgedInsert, unique: updatePolicy.unique))
        }
    }
}
/*
func generateRLMArrayMappingBridge<M: RealmMapping>(binding: Binding<M>) -> Binding<RLMArrayMappingBridge<M.MappedObject, RLMArrayBridge<M.MappedObject>>> where M.SequenceKind.Iterator.Element == M.MappedObject, M.MappedObject: Equatable {
    
    switch binding {
    case .mapping(let keyPath, let mapping):
        let bridge = RLMArrayMappingBridge<M.MappedObject, RLMArrayBridge<M.MappedObject>>(rlmObjectMapping: mapping)
        return .mapping(keyPath, bridge)
        
    case .collectionMapping(let keyPath, let mapping, let updatePolicy):
        let bridge = RLMArrayMappingBridge<M.MappedObject, RLMArrayBridge<M.MappedObject>>(rlmObjectMapping: mapping)
        
        let bridgedInsert: CollectionInsertionMethod<RLMArrayBridge<M.MappedObject>> = {
            switch updatePolicy.insert {
                
            case .append:
                return .append
                
            case .replace(let deletion):
                guard let deletion = deletion else {
                    return .replace(delete: nil)
                }
                
                let bridgedDeletion = { (objs: RLMArrayBridge<M.MappedObject>) -> RLMArrayBridge<M.MappedObject> in
                    let rlmObjsToDelete = deletion( objs.map { $0 } as! M.SequenceKind )
                    let listToDelete = RLMArrayBridge<M.MappedObject>()
                    for obj in rlmObjsToDelete {
                        listToDelete.append(obj)
                    }
                    return listToDelete
                }
                return .replace(delete: bridgedDeletion)
            }
        }()
        
        return .collectionMapping(keyPath, bridge, (insert: bridgedInsert, unique: updatePolicy.unique))
    }
}
*/
// TODO: Currently this leads to "Ambiguous use of operator '<-'" conflicting with the `RangeReplaceableCollection` version.
// Considering this is more specialized and that `RLMArray` does not implement `RangeReplaceableCollection` this seems like
// a bug. Report the bug. In the meantime we're forced to break convention and use `map(toRLMArray:using:)` instead of `<-`.

@discardableResult
public func <- <T: RLMObject, U: RealmMapping, C: MappingContext>(field: RLMArray<T>, binding:(key: Binding<U>, context: C)) -> C where U.MappedObject == T, U.SequenceKind.Iterator.Element == U.MappedObject, T: Equatable {
    
    return map(toRLMArray: field, using: binding)
}

@discardableResult
public func map<U: RealmMapping, C: MappingContext>(toRLMArray field: RLMArray<U.MappedObject>, using binding:(key: Binding<U>, context: C)) -> C where U.SequenceKind.Iterator.Element == U.MappedObject, U.MappedObject: Equatable {
    
    //let converted = ObjectiveCSupport.convert(object: field as! RLMArray<RLMObject>)
    //var variableList = ListWrapper<Object>(list: converted)
    var variableList = RLMArrayBridge(rlmArray: field)
    let bridge = binding.key.generateRLMArrayMappingBridge()
    doBridge(binding: bridge)
    print(type(of: variableList))
    print(type(of: variableList).Iterator.Element.self)
    print(type(of: bridge))
    print(type(of: bridge.mapping).SequenceKind.self)
    print(type(of: bridge.mapping).SequenceKind.Iterator.Element.self)
    //return binding.context
    return map(toCollection: &variableList, using: (bridge, binding.context))
}
