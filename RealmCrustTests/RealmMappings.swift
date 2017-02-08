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
    init(adaptor: RealmAdaptor)
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

public class RealmSwiftObjectAdaptorBridge: Adaptor {
    public typealias BaseType = Object
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
    
    public func createObject(type: Object.Type) throws -> Object {
        let obj = try self.realmObjCAdaptor.createObject(type: self.rlmObjectType)
        return unsafeBitCast(obj, to: Object.self)
    }
    
    public func save(objects: [BaseType]) throws {
        let rlmObjs = objects.map { unsafeBitCast($0, to: type(of: self.realmObjCAdaptor).BaseType.self) }
        try self.realmObjCAdaptor.save(objects: rlmObjs)
    }
    
    public func deleteObject(_ obj: BaseType) throws {
        let rlmObj = unsafeBitCast(obj, to: type(of: self.realmObjCAdaptor).BaseType.self)
        try self.realmObjCAdaptor.deleteObject(rlmObj)
    }
    
    public func fetchObjects(type: Object.Type, primaryKeyValues: [[String : CVarArg]], isMapping: Bool) -> ResultsType? {
        guard let rlmObjects = self.realmObjCAdaptor.fetchObjects(type: self.rlmObjectType,
                                                                  primaryKeyValues: primaryKeyValues,
                                                                  isMapping: isMapping)
            else {
                return nil
        }
        
        return rlmObjects.map { unsafeBitCast($0, to: Object.self) }
    }
}

/// Subclass this to map RLMObjects.

public class RealmSwiftObjectMappingBridge: Mapping {
    public let adaptor: RealmSwiftObjectAdaptorBridge
    public let primaryKeys: [Mapping.PrimaryKeyDescriptor]?
    public let rlmObjectMapping: (inout RLMObject, MappingContext) -> Void
    
    public required init<Obj: RLMObject, OGMapping: RealmMapping>(adaptor: RealmAdaptor, rlmObjectMapping: OGMapping) where OGMapping.MappedObject == Obj {
        
        self.adaptor = RealmSwiftObjectAdaptorBridge(realmObjCAdaptor: adaptor,
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

public func <- <T: RLMObject, U: RealmMapping, C: MappingContext>(field: RLMArray<T>, map:(key: Binding<U>, context: C)) -> C where U.MappedObject == T {
    
    // Realm specifies that List "must be declared with 'let'". Seems to actually work either way in practice, but for safety
    // we're going to include a List mapper that accepts fields with a 'let' declaration and forward to our
    // `RangeReplaceableCollectionType` mapper.
    
    var variableList = ObjectiveCSupport.convert(object: field as! RLMArray<RLMObject>)
    return Crust.map(toCollection: &variableList, using: map)
}

public func map<T: RLMObject, U: Mapping, C: MappingContext>(field: inout RLMArray<T>, map:(key: Binding<U>, context: C)) -> C where U.MappedObject == T {
    
    var variableList = ObjectiveCSupport.convert(object: field)
    return Crust.map(toCollection: &variableList, using: map)
}
