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

class CompanyMapping: Mapping {
    
    var adapter: MockAdapter<Company>
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.uuid", nil) ]
    }
    
    required init(adapter: MockAdapter<Company>) {
        self.adapter = adapter
    }
    
    func mapping(toMap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adapter: MockAdapter<Employee>())
        
        toMap.employees             <- .mapping("employees", employeeMapping) >*<
        toMap.founder               <- .mapping("founder", employeeMapping) >*<
        toMap.uuid                  <- "data.uuid" >*<
        toMap.name                  <- "name" >*<
        toMap.foundingDate          <- "data.founding_date"  >*<
        toMap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}

class CompanyMappingWithDupes: CompanyMapping {
    
    override func mapping(toMap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adapter: MockAdapter<Employee>())
        
        toMap.employees             <- .collectionMapping("employees", employeeMapping, (.append, true)) >*<
        toMap.founder               <- .mapping("founder", employeeMapping) >*<
        toMap.uuid                  <- "data.uuid" >*<
        toMap.name                  <- "name" >*<
        toMap.foundingDate          <- "data.founding_date"  >*<
        toMap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}
