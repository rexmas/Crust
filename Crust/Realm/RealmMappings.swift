import Foundation
import RealmSwift

class RealmAdaptor : Adaptor {
    
    typealias BaseType = Object
    typealias ResultsType = Results<Object>
    
    var realm: Realm
    
    init(realm: Realm) {
        self.realm = realm
    }
    
    convenience init() throws {
        self.init(realm: try Realm())
    }
    
    func createObject(objType: BaseType.Type) -> BaseType {
        return objType.init()
    }
    
    func deleteObject(obj: BaseType) {
        realm.write {
            self.realm.delete(obj)
        }
    }
    
    func fetchObjectWithType(type: BaseType.Type, keyValues: Dictionary<String, CVarArgType>) -> BaseType? {
        
        var predicates = Array<NSPredicate>()
        for (key, value) in keyValues {
            let predicate = NSPredicate(format: "%@ = %@", key, value)
            predicates.append(predicate)
        }
        
        let andPredicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: predicates)
        
        return fetchObjectsWithType(type, predicate: andPredicate).first
    }
    
    func fetchObjectsWithType(type: BaseType.Type, predicate: NSPredicate) -> ResultsType {
        
        return realm.objects(type).filter(predicate)
    }
}

extension Employee: Mappable { }

class EmployeeMapping : Mapping {
    var adaptor: RealmAdaptor
    var primaryKeys: Array<CRMappingKey> {
        return [ "uuid" ]
    }
    
    init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    func mapping(tomap: Employee, context: MappingContext) {
        
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
