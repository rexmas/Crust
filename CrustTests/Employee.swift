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

extension Employee: AnyMappable { }

class EmployeeMapping: MockMapping {
    
    var adapter: MockAdapter<Employee>
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "uuid", nil) ]
    }
    
    required init(adapter: MockAdapter<Employee>) {
        self.adapter = adapter
    }
    
    func mapping(toMap: inout Employee, context: MappingContext) {
        let companyMapping = CompanyMapping(adapter: MockAdapter<Company>())
        
        toMap.employer              <- .mapping("company", companyMapping) >*<
        toMap.joinDate              <- "joinDate"  >*<
        toMap.uuid                  <- "uuid" >*<
        toMap.name                  <- "name" >*<
        toMap.salary                <- "data.salary"  >*<
        toMap.isEmployeeOfMonth     <- "data.is_employee_of_month"  >*<
        toMap.percentYearlyRaise    <- "data.percent_yearly_raise" >*<
        context
    }
}
