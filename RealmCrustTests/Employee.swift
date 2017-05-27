import Crust
import Realm

public enum EmployeeKey: Keypath {
    case employer(Set<CompanyKey>)
    case uuid
    case name
    case joinDate
    case salary
    case isEmployeeOfMonth
    case percentYearlyRaise
    
    public var keyPath: String {
        switch self {
        case .employer(_):          return "company"
        case .uuid:                 return "uuid"
        case .name:                 return "name"
        case .joinDate:             return "joinDate"
        case .salary:               return "data.salary"
        case .isEmployeeOfMonth:    return "data.is_employee_of_month"
        case .percentYearlyRaise:   return "data.percent_yearly_raise"
        }
    }
    
    public func nestedCodingKey<K: Keypath>() -> AnyKeyProvider<K>? {
        switch self {
        case .employer(let companyKeys):
            return AnyKeyProvider.wrapAs(companyKeys)
        default:
            return nil
        }
    }
}

public class EmployeeMapping : RealmMapping {
    
    public var adapter: RealmAdapter
    public var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "uuid", nil) ]
    }
    
    public required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    public func mapping(toMap: inout Employee, context: MappingContext<EmployeeKey>) {
        let companyMapping = CompanyMapping(adapter: self.adapter)
        let key = Binding<EmployeeKey, CompanyMapping>.mapping(.employer([]), companyMapping)
        
        toMap.employer              <- (key, context)
        toMap.joinDate              <- (.joinDate, context)
        toMap.uuid                  <- (.uuid, context)
        toMap.name                  <- (.name, context)
        toMap.salary                <- (.salary, context)
        toMap.isEmployeeOfMonth     <- (.isEmployeeOfMonth, context)
        toMap.percentYearlyRaise    <- (.percentYearlyRaise, context)
    }
}
