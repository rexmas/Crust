import Crust
import JSONValueRX
import Realm

public enum CompanyKey: RawRepresentable, Keypath {
    case uuid
    case employees([EmployeeKey])
    case founder
    case name
    case foundingDate
    case pendingLawsuits
    
    public var keyPath: String {
        return self.rawValue
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "data.uuid":               self = .uuid
        case "employees":               self = .employees([])
        case "founder":                 self = .founder
        case "name":                    self = .name
        case "data.founding_date":         self = .foundingDate
        case "data.lawsuits.pending":   self = .pendingLawsuits
        default:
            fatalError()
        }
    }
    
    public var rawValue: String {
        switch self {
        case .uuid:             return "data.uuid"
        case .employees(_):     return "employees"
        case .founder:          return "founder"
        case .name:             return "name"
        case .foundingDate:     return "data.founding_date"
        case .pendingLawsuits:  return "data.lawsuits.pending"
        }
    }
    
    public func nestedMappingKeys<Key: Keypath>() -> AnyKeyCollection<Key>? {
        switch self {
        case .employees(let keys):
            return AnyKeyCollection.wrapAs(keys)
        default:
            return nil
        }
    }
}

public class CompanyMapping : RealmMapping {
    
    public var adapter: RealmAdapter
    public var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.uuid", nil) ]
    }
    
    public required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    public func mapping(toMap: inout Company, context: MappingContext<CompanyKey>) {
        let employeeMapping = EmployeeMapping(adapter: self.adapter)
        
        toMap.employees             <- (Binding.collectionMapping(.employees([]), employeeMapping, (.append, true, false)), context)
        toMap.founder               <- .mapping(.founder, employeeMapping) >*< context
        toMap.name                  <- .name >*<
        toMap.foundingDate          <- .foundingDate  >*<
        toMap.pendingLawsuits       <- .pendingLawsuits  >*<
        context
    }
}

public class CompanyMappingWithDupes : CompanyMapping {
    
    public override func mapping(toMap: inout Company, context: MappingContext<CompanyKey>) {
        let employeeMapping = EmployeeMapping(adapter: self.adapter)
        
        toMap.employees             <- (.collectionMapping(.employees([]), employeeMapping, (.append, false, false)), context)
        toMap.founder               <- Binding.mapping(.founder, employeeMapping) >*<
        toMap.uuid                  <- .uuid >*<
        toMap.name                  <- .name >*<
        toMap.foundingDate          <- .foundingDate  >*<
        toMap.pendingLawsuits       <- .pendingLawsuits  >*<
        context
    }
}
