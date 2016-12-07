import Foundation
import Crust
import Realm

public class RealmAdaptor: Adaptor {
    
    public typealias BaseType = RLMObject
    public typealias ResultsType = [BaseType]
    
    var realm: RLMRealm
    var cache: Set<BaseType>
    
    public init(realm: RLMRealm) {
        self.realm = realm
        self.cache = []
    }
    
    public convenience init() throws {
        self.init(realm: RLMRealm())
    }
    
    public func mappingBegins() throws {
        self.realm.beginWriteTransaction()
    }
    
    public func mappingEnded() throws {
        try self.realm.commitWriteTransaction()
        self.cache.removeAll()
//        self.cache.removeAllObjects()
    }
    
    public func mappingErrored(_ error: Error) {
        if self.realm.inWriteTransaction {
            self.realm.cancelWriteTransaction()
        }
        self.cache.removeAll()
//        self.cache.removeAllObjects()
    }
    
    public func createObject(type: BaseType.Type) throws -> BaseType {
        let obj = type.init()
        self.cache.insert(obj)
//        self.cache.add(obj)
        return obj
    }
    
    public func save(objects: [BaseType]) throws {
        let saveBlock = {
            for obj in objects {
                self.cache.remove(obj)
                self.realm.addOrUpdate(obj)
//                self.realm.add(objects, update: type(of: obj).primaryKey() != nil)
            }
        }
        if self.realm.inWriteTransaction {
            saveBlock()
        } else {
            self.realm.beginWriteTransaction()
            saveBlock()
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
    
    public func fetchObjects(type: BaseType.Type, keyValues: [String : CVarArg]) -> ResultsType? {
        
        var predicates = Array<NSPredicate>()
        for (key, value) in keyValues {
            let predicate = NSPredicate(format: "%K == %@", key, value)
            predicates.append(predicate)
        }
        
        let andPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        return fetchObjects(type: type, predicate: andPredicate)
    }
    
    public func fetchObjects(type: BaseType.Type, predicate: NSPredicate) -> ResultsType? {
        
        let objects = self.cache.filter {
            predicate.evaluate(with: $0)
        }
//        let objects = self.cache.filtered(using: predicate)
        if objects.count > 0 {
            return Array(objects)
        }
        
        if type.primaryKey() != nil {
            // We're going to build an unstored object and update when saving based on the primary key.
            return nil
        }
        
        var finalObjects = [BaseType]()
        let results = type.objects(in: realm, with: predicate)
        for obj in results {
            finalObjects.append(obj)
        }
        return objects
    }
}

/// Instructions:
/// 1. `import Crust` and `import RealmCrust` dependencies.
/// 2. Include this section of code in your app/lib and uncomment.
/// This will allow our `RealmMapping` and `RealmAdaptor` to be used with Crust.

public protocol RealmMapping: Mapping {
    init(adaptor: RealmAdaptor)
}

extension RLMArray: Appendable {
    public func append(_ newElement: RLMObject) {
        self.addObjectNonGeneric(newElement)
    }
    
    public func append(contentsOf newElements: [RLMObject]) {
        for obj in newElements {
            self.addObjectNonGeneric(obj)
        }
    }
}

@discardableResult
public func <- <T, U: Mapping, C: MappingContext>(field: inout RLMArray<T>, map:(key: Spec<U>, context: C)) -> C
    where U.MappedObject == T {

     // Realm specifies that List "must be declared with 'let'". Seems to actually work either way in practice, but for safety
     // we're going to include a List mapper that accepts fields with a 'let' declaration and forward to our
     // `RangeReplaceableCollectionType` mapper.

    var variableList = field.allObjects() as! [T]
    let context = mapCollectionField(&variableList, map: map)
    field.append(contentsOf: variableList)
    return context
}

//public func <- <T, U: Mapping, C: MappingContext>(field: List<T>, map:(key: KeyExtensions<U>, context: C)) -> C
//    where U.MappedObject == T {

//     // Realm specifies that List "must be declared with 'let'". Seems to actually work either way in practice, but for safety
//     // we're going to include a List mapper that accepts fields with a 'let' declaration and forward to our
//     // `RangeReplaceableCollectionType` mapper.
    
//    var variableList = field
//    return mapField(&variableList, map: map)
//}
