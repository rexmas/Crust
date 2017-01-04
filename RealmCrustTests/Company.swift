import Crust
import JSONValueRX
import Realm

public class CompanyMapping : RealmMapping {
    
    public var adaptor: RealmAdaptor
    public var primaryKeys: [String : Keypath]? {
        return [ "uuid" : "data.uuid" ]
    }
    
    public required init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    public func mapping(tomap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adaptor: self.adaptor)
        
        tomap.employees             <- Spec.mapping("employees", employeeMapping) >*< context
        tomap.founder               <- Spec.mapping("founder", employeeMapping) >*< context
        tomap.uuid                  <- ("data.uuid" as JSONKeypath, context)
        tomap.name                  <- "name" >*<
        tomap.foundingDate          <- "data.founding_date"  >*<
        tomap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}

public class CompanyMappingWithDupes : CompanyMapping {
    
    public override func mapping(tomap: inout Company, context: MappingContext) {
        let employeeMapping = EmployeeMapping(adaptor: self.adaptor)
        let mappingExtension = Spec.mapping("employees", employeeMapping)
        
        tomap.employees             <- .mappingOptions(mappingExtension, [ .AllowDuplicatesInCollection ]) >*< context
        tomap.founder               <- .mapping("founder", employeeMapping) >*<
        tomap.uuid                  <- "data.uuid" >*<
        tomap.name                  <- "name" >*<
        tomap.foundingDate          <- "data.founding_date"  >*<
        tomap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
        context
    }
}
