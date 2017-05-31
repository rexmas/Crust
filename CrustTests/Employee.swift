import Crust

class Employee {
    required init() { }
    
    var employer: Company?
    var uuid: String = ""
    var name: String = ""
    var joinDate: Date = Date()
    var salary: Int = 0
    var isEmployeeOfMonth: Bool = false
    var percentYearlyRaise: Double = 0.0
}

enum EmployeeCodingKey: MappingKey {
    case employer(Set<CompanyCodingKey>)
    case uuid
    case name
    case joinDate
    case salary
    case isEmployeeOfMonth
    case percentYearlyRaise
    
    var keyPath: String {
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
            return companyKeys.wrapped()
        default:
            return nil
        }
    }
}

extension Employee: AnyMappable { }

class EmployeeMapping: MockMapping {
    
    var adapter: MockAdapter<Employee>
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "uuid", nil) ]
    }
    
    required init(adapter: MockAdapter<Employee>) {
        self.adapter = adapter
    }
    
    func mapping(toMap: inout Employee, payload: MappingPayload<EmployeeCodingKey>) {
        let companyMapping = CompanyMapping(adapter: MockAdapter<Company>())
        
        toMap.employer              <- .mapping(.employer([]), companyMapping) >*<
        toMap.joinDate              <- .joinDate  >*<
        toMap.uuid                  <- .uuid >*<
        toMap.name                  <- .name >*<
        toMap.salary                <- .salary  >*<
        toMap.isEmployeeOfMonth     <- .isEmployeeOfMonth  >*<
        toMap.percentYearlyRaise    <- .percentYearlyRaise >*<
        payload
    }
}
