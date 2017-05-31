import Crust
import Realm

public enum EmployeeKey: MappingKey {
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
    
    public func nestedMappingKeys<Key: MappingKey>() -> AnyKeyCollection<Key>? {
        switch self {
        case .employer(let companyKeys):
            return AnyKeyCollection.wrapAs(companyKeys)
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
    
    public func mapping(toMap: inout Employee, payload: MappingPayload<EmployeeKey>) {
        let companyMapping = CompanyMapping(adapter: self.adapter)
        let key = Binding<EmployeeKey, CompanyMapping>.mapping(.employer([]), companyMapping)
        
        toMap.employer              <- (key, payload)
        toMap.joinDate              <- (.joinDate, payload)
        toMap.uuid                  <- (.uuid, payload)
        toMap.name                  <- (.name, payload)
        toMap.salary                <- (.salary, payload)
        toMap.isEmployeeOfMonth     <- (.isEmployeeOfMonth, payload)
        toMap.percentYearlyRaise    <- (.percentYearlyRaise, payload)
    }
}
