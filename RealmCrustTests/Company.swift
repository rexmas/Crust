import Crust
import JSONValueRX
import Realm

enum CodingKey<K: KeyPath> {
    case field(K)
    case nested(K, CodingKey<)
}


enum EmployeeKeys: String, Keypath {
    case uuid
    
    var keyPath: String {
        return self.rawValue
    }
}

enum CompanyKeys: RawRepresentable, Keypath {
    case uuid
    case employees([Any])
    case founder
    case name
    case foundingDate
    case pendingLawsuits
    
    var keyPath: String {
        return self.rawValue
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "uuid":
            self = .uuid
        case "employees":
            self = .employees([])
        case "founder":
            self = .founder
        case "name":
            self = .name
        case "foundingDate":
            self = .foundingDate
        case "pendingLawsuits":
            self = .pendingLawsuits
        }
    }
    
    public var rawValue: String {
        switch self {
        case .uuid:
            return "uuid"
        default:
            return ""
        }
    }
}
//
//struct MappingDescriber<ToMap> {
//    let fields: [String : ] = [
//        
//    ]
//}

protocol MappingDescriptionT: Mapping {
    associatedtype toMap
    
    
}

indirect enum MappingDescription<ToMap> {
    case field((inout ToMap, MappingContext) -> MappingContext)
    case nested(String, MappingDescription)
}

let employeeMappingDescription: [String : MappingDescription<Employee>] = [
    "name" : .field({ (toMap: inout Employee, context: MappingContext) in toMap.name <- ("name", context) }),
    "uuid" : .field({ (toMap: inout Employee, context: MappingContext) in toMap.uuid <- ("uuid", context) }),
    "salary" : .field({ (toMap: inout Employee, context: MappingContext) in toMap.salary <- ("salary", context) }),
]

public class CompanyMapping : RealmMapping {
    
    public var adapter: RealmAdapter
    public var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.uuid", nil) ]
    }
    
    public required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    public func mapping(toMap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adapter: self.adapter)
        
        //toMap.employees             <- (Binding.collectionMapping("employees", employeeMapping, (.append, true, false)), context)
        toMap.founder               <- .mapping("founder", employeeMapping) >*< context
        toMap.name                  <- "name" >*<
        toMap.foundingDate          <- "data.founding_date"  >*<
        toMap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
    
    let mappingKeys: [CompanyKeys : MappingDescription<Company>] = [
        .name : .field({ (toMap: inout Company, context: MappingContext) in toMap.name <- ("name", context) }),
        .founder : .nested("founder", employeeMappingDescription)
    ]
}

//{
//    let employeeMapping = EmployeeMapping(adapter: self.adapter)
//    return $0.founder <- .mapping("founder", employeeMapping)
//}

public class CompanyMappingWithDupes : CompanyMapping {
    
    public override func mapping(toMap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adapter: self.adapter)
        
        toMap.employees             <- (.collectionMapping("employees", employeeMapping, (.append, false, false)), context)
        toMap.founder               <- Binding.mapping("founder", employeeMapping) >*<
        toMap.uuid                  <- "data.uuid" >*<
        toMap.name                  <- "name" >*<
        toMap.foundingDate          <- "data.founding_date"  >*<
        toMap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}
