import Crust

class Company {
    
    required init() { }
    
    var employees = Array<Employee>()
    var uuid: String = ""
    var name: String = ""
    var foundingDate: Date = Date()
    var founder: Employee?
    var pendingLawsuits: Int = 0
}

extension Company: AnyMappable { }

class CompanyMapping: Mapping {
    
    var adaptor: MockAdaptor<Company>
    var primaryKeys: Dictionary<String, Keypath>? {
        return [ "uuid" : "data.uuid" ]
    }
    
    required init(adaptor: MockAdaptor<Company>) {
        self.adaptor = adaptor
    }
    
    func mapping(_ tomap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adaptor: MockAdaptor<Employee>())
        
        tomap.employees             <- Spec.mapping("employees", employeeMapping) >*<
        tomap.founder               <- .mapping("founder", employeeMapping) >*<
        tomap.uuid                  <- "data.uuid" >*<
        tomap.name                  <- "name" >*<
        tomap.foundingDate          <- "data.founding_date"  >*<
        tomap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}

class CompanyMappingWithDupes: CompanyMapping {
    
    override func mapping(_ tomap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adaptor: MockAdaptor<Employee>())
        let mappingExtension = Spec.mapping("employees", employeeMapping)
        
        tomap.employees             <- Spec.mappingOptions(mappingExtension, [ .AllowDuplicatesInCollection ]) >*<
        tomap.founder               <- .mapping("founder", employeeMapping) >*<
        tomap.uuid                  <- "data.uuid" >*<
        tomap.name                  <- "name" >*<
        tomap.foundingDate          <- "data.founding_date"  >*<
        tomap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}
