import Crust
import Realm

enum EmployeeCodingKey: Keypath {
    case employer(Set<CompanyKey>)
    case uuid
    case name
    case joinDate
    case salary
    case isEmployeeOfMonth
    case percentYearlyRaise
    
    var keyPath: String {
        switch self {
        case .employer(_):
            return "company"
        case .uuid:
            return "uuid"
        case .name:
            return "name"
        case .joinDate:
            return "joinDate"
        case .salary:
            return "data.salary"
        case .isEmployeeOfMonth:
            return "data.is_employee_of_month"
        case .percentYearlyRaise:
            return "data.percent_yearly_raise"
        }
    }
    
    public func nestedCodingKey<P: KeyProvider>() -> P?  {
        switch self {
        case .employer(let companyKeys):
            return companyKeys as? P
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
        let key = Binding.mapping("company", companyMapping)
        
        toMap.employer              <-  key >*<
        toMap.joinDate              <- ("joinDate", context)
        toMap.uuid                  <- "uuid" >*<
        toMap.name                  <- "name" >*<
        toMap.salary                <- "data.salary"  >*<
        toMap.isEmployeeOfMonth     <- "data.is_employee_of_month"  >*<
        toMap.percentYearlyRaise    <- "data.percent_yearly_raise" >*<
        context
    }
}
