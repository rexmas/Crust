import Crust
import JSONValueRX
import Realm

public class CompanyMapping : RealmMapping {
    
    public var adapter: RealmAdapter
    public var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.uuid", nil) ]
    }
    
    public required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    public func mapping(tomap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adapter: self.adapter)
        
        tomap.employees             <- (Binding.collectionMapping("employees", employeeMapping, (.append, true)), context)
        tomap.founder               <- .mapping("founder", employeeMapping) >*< context
        tomap.name                  <- "name" >*<
        tomap.foundingDate          <- "data.founding_date"  >*<
        tomap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}

public class CompanyMappingWithDupes : CompanyMapping {
    
    public override func mapping(tomap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adapter: self.adapter)
        
        tomap.employees <- (Binding.collectionMapping("employees", employeeMapping, (.append, false)), context)
        tomap.founder               <- .mapping("founder", employeeMapping) >*<
        tomap.uuid                  <- "data.uuid" >*<
        tomap.name                  <- "name" >*<
        tomap.foundingDate          <- "data.founding_date"  >*<
        tomap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}
