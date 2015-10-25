import Foundation
import RealmSwift

public class RealmAdaptor : Adaptor {
    
    public typealias BaseType = Object
    public typealias ResultsType = Results<Object>
    
    var realm: Realm
    
    public init(realm: Realm) {
        self.realm = realm
    }
    
    public convenience init() throws {
        self.init(realm: try Realm())
    }
    
    public func createObject(objType: BaseType.Type) -> BaseType {
        return objType.init()
    }
    
    public func saveObjects(objects: [BaseType]) {
        self.realm.write {
            self.realm.add(objects)
        }
    }
    
    public func deleteObject(obj: BaseType) {
        realm.write {
            self.realm.delete(obj)
        }
    }
    
    public func fetchObjectWithType(type: BaseType.Type, keyValues: Dictionary<String, CVarArgType>) -> BaseType? {
        
        var predicates = Array<NSPredicate>()
        for (key, value) in keyValues {
            let predicate = NSPredicate(format: "%@ = %@", key, value)
            predicates.append(predicate)
        }
        
        let andPredicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: predicates)
        
        return fetchObjectsWithType(type, predicate: andPredicate).first
    }
    
    public func fetchObjectsWithType(type: BaseType.Type, predicate: NSPredicate) -> ResultsType {
        
        return realm.objects(type).filter(predicate)
    }
}

extension Employee: Mappable { }

public protocol RealmMapping : Mapping {
    init(adaptor: RealmAdaptor)
}

public class EmployeeMapping : RealmMapping {
    
    public var adaptor: RealmAdaptor
    public var primaryKeys: Array<CRMappingKey> {
        return [ "uuid" ]
    }
    
    public required init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    public func mapping(tomap: Employee, context: MappingContext) {
        
        tomap.joinDate              <- "joinDate"  >*<
        tomap.uuid                  <- "uuid" >*<
        tomap.name                  <- "name" >*<
        tomap.joinDate              <- "joinDate"  >*<
        tomap.salary                <- "data.salary"  >*<
        tomap.isEmployeeOfMonth     <- "data.is_employee_of_month"  >*<
        tomap.percentYearlyRaise    <- "data.percent_yearly_raise" >*<
        context
    }
}
