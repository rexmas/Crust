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
    
    public func mappingBegins() {
        self.realm.beginWrite()
    }
    
    public func mappingEnded() {
        self.realm.commitWrite()
    }
    
    public func mappingErrored(error: ErrorType) {
        self.realm.cancelWrite()
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
            let predicate = NSPredicate(format: "%K == %@", key, value)
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
extension Company: Mappable { }

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
        let companyMapping = CompanyMapping(adaptor: self.adaptor)
        
        tomap.employer              <- .Mapping("company", companyMapping) >*<
        tomap.joinDate              <- "joinDate"  >*<
        tomap.uuid                  <- "uuid" >*<
        tomap.name                  <- "name" >*<
        tomap.salary                <- "data.salary"  >*<
        tomap.isEmployeeOfMonth     <- "data.is_employee_of_month"  >*<
        tomap.percentYearlyRaise    <- "data.percent_yearly_raise" >*<
        context
    }
}

public class CompanyMapping : RealmMapping {
    
    public var adaptor: RealmAdaptor
    public var primaryKeys: Array<CRMappingKey> {
        return [ "uuid" ]
    }
    
    public required init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    public func mapping(tomap: Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adaptor: self.adaptor)
        
        tomap.employees             <- .Mapping("employees", employeeMapping) >*<
        tomap.founder               <- .Mapping("founder", employeeMapping) >*<
        tomap.uuid                  <- "uuid" >*<
        tomap.name                  <- "name" >*<
        tomap.foundingDate          <- "data.founding_date"  >*<
        tomap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}

public func <- <T: Mappable, U: Mapping, C: MappingContext where U.MappedObject == T>(field: List<T>, map:(key: KeyExtensions<U>, context: C)) -> C {
    
    // Realm specifies that List "must be declared with 'let'". Seems to actually work either way in practice, but for safety
    // we're going to include a List mapper that accepts fields with a 'let' declaration and forward to our
    // `RangeReplaceableCollectionType` mapper.
    
    var variableList = field
    return mapField(&variableList, map: map)
}
