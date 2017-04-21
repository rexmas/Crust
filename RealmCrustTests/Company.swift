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
    
    public func mapping(toMap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adapter: self.adapter)
        
        toMap.employees             <- (Binding.collectionMapping("employees", employeeMapping, (.append, true)), context)
        toMap.founder               <- .mapping("founder", employeeMapping) >*< context
        toMap.name                  <- "name" >*<
        toMap.foundingDate          <- "data.founding_date"  >*<
        toMap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}

public class CompanyMappingWithDupes : CompanyMapping {
    
    public override func mapping(toMap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adapter: self.adapter)
        
        toMap.employees <- (.collectionMapping("employees", employeeMapping, (.append, false)), context)
        toMap.founder               <- .mapping("founder", employeeMapping) >*<
        toMap.uuid                  <- "data.uuid" >*<
        toMap.name                  <- "name" >*<
        toMap.foundingDate          <- "data.founding_date"  >*<
        toMap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}
