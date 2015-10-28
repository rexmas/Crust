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
    return mapField(field, map: map)
}

public func mapField<T: Mappable, U: Mapping, C: MappingContext where U.MappedObject == T>(field: List<T>, map:(key: KeyExtensions<U>, context: C)) -> C {
    
    guard map.context.error == nil else {
        return map.context
    }
    
    guard case .Mapping(let key, let mapping) = map.key else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Must provide a KeyExtension.Mapping to map a List" ]
        map.context.error = NSError(domain: "RealmMappingDomain", code: -1000, userInfo: userInfo)
        return map.context
    }
    
    do {
        switch map.context.dir {
        case .ToJSON:
            let json = map.context.json
            try map.context.json = mapToJson(json, fromField: field, viaKey: key, mapping: mapping)
        case .FromJSON:
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: field, mapping: mapping)
            } else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(map.key) does not exist to map from" ]
                throw NSError(domain: "RealmMappingDomain", code: 0, userInfo: userInfo)
            }
        }
    } catch let error as NSError {
        map.context.error = error
    }
    
    return map.context
}

private func mapToJson<T: Mappable, U: Mapping where U.MappedObject == T>(var json: JSONValue, fromField field: List<T>, viaKey key: CRMappingKey, mapping: U) throws -> JSONValue {
    
    let results = try field.map {
        try CRMapper<T, U>().mapFromObjectToJSON($0, mapping: mapping)
    }
    json[key] = .JSONArray(results)
    
    return json
}

private func mapFromJson<T: Mappable, U: Mapping where U.MappedObject == T>(json: JSONValue, toField field: List<T>, mapping: U) throws {
    
    if case .JSONArray(let xs) = json {
        let mapper = CRMapper<T, U>()
        let results = try xs.map {
            try mapper.mapFromJSONToNewObject($0, mapping: mapping)
        }
        field.appendContentsOf(results)
    } else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Trying to map json of type \(json.dynamicType) to List<\(T.self)>" ]
        throw NSError(domain: "RealmMappingDomain", code: -1, userInfo: userInfo)
    }
}
