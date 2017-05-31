import Crust

class Company {
    
    required init() { }
    
    var employees = [Employee]()
    var uuid: String = ""
    var name: String = ""
    var foundingDate: Date = Date()
    var founder: Employee?
    var pendingLawsuits: Int = 0
}

extension Company: AnyMappable { }

enum CompanyCodingKey: MappingKey {
    case uuid
    case employees(Set<EmployeeCodingKey>)
    case founder
    case name
    case foundingDate
    case pendingLawsuits
    
    var keyPath: String {
        switch self {
        case .uuid:             return "data.uuid"
        case .employees(_):     return "employees"
        case .founder:          return "founder"
        case .name:             return "name"
        case .foundingDate:     return "data.founding_date"
        case .pendingLawsuits:  return "data.lawsuits.pending"
        }
    }
    
    func nestedMappingKeys<Key: MappingKey>() -> AnyKeyCollection<Key>? {
        switch self {
        case .employees(let employeeKeys):
            return employeeKeys.wrapped()
        default:
            return nil
        }
    }
}

class CompanyMapping: Mapping {
    
    var adapter: MockAdapter<Company>
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.uuid", nil) ]
    }
    
    required init(adapter: MockAdapter<Company>) {
        self.adapter = adapter
    }
    
    func mapping(toMap: inout Company, payload: MappingPayload<CompanyCodingKey>) {
        let employeeMapping = EmployeeMapping(adapter: MockAdapter<Employee>())
        
        toMap.employees             <- .mapping(.employees([]), employeeMapping) >*<
        toMap.founder               <- .mapping(.founder, employeeMapping) >*<
        toMap.uuid                  <- .uuid >*<
        toMap.name                  <- .name >*<
        toMap.foundingDate          <- .foundingDate  >*<
        toMap.pendingLawsuits       <- .pendingLawsuits  >*<
        payload
    }
}

class CompanyMappingWithDupes: CompanyMapping {
    
    override func mapping(toMap: inout Company, payload: MappingPayload<CompanyCodingKey>) {
        let employeeMapping = EmployeeMapping(adapter: MockAdapter<Employee>())
        
        toMap.employees             <- .collectionMapping(.employees([]), employeeMapping, (.append, true, true)) >*<
        toMap.founder               <- .mapping(.founder, employeeMapping) >*<
        toMap.uuid                  <- .uuid >*<
        toMap.name                  <- .name >*<
        toMap.foundingDate          <- .foundingDate  >*<
        toMap.pendingLawsuits       <- .pendingLawsuits  >*<
        payload
    }
}

class CompanyWithOptionalEmployees {
    
    required init() { }
    
    var employees: [Employee]? = nil
    var uuid: String = ""
    var name: String = ""
    var foundingDate: Date = Date()
    var founder: Employee?
    var pendingLawsuits: Int = 0
}

extension CompanyWithOptionalEmployees: AnyMappable { }

class CompanyWithOptionalEmployeesMapping: Mapping {
    
    var adapter: MockAdapter<CompanyWithOptionalEmployees>
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.uuid", nil) ]
    }
    
    required init(adapter: MockAdapter<CompanyWithOptionalEmployees>) {
        self.adapter = adapter
    }
    
    func mapping(toMap: inout CompanyWithOptionalEmployees, payload: MappingPayload<CompanyCodingKey>) {
        let employeeMapping = EmployeeMapping(adapter: MockAdapter<Employee>())
        
        toMap.employees         <- .mapping(.employees([]), employeeMapping) >*<
        toMap.founder           <- .mapping(.founder, employeeMapping) >*<
        toMap.uuid              <- .uuid >*<
        toMap.name              <- .name >*<
        toMap.foundingDate      <- .foundingDate  >*<
        toMap.pendingLawsuits   <- .pendingLawsuits  >*<
        payload
    }
}
