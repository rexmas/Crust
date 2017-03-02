import Crust
import Realm

public class EmployeeMapping : RealmMapping {
    
    public var adapter: RealmAdapter
    public var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "uuid", nil) ]
    }
    
    public required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    public func mapping(tomap: inout Employee, context: MappingContext) {
        let companyMapping = CompanyMapping(adapter: self.adapter)
        let key = Binding.mapping("company", companyMapping)
        
        tomap.employer              <-  key >*<
        tomap.joinDate              <- ("joinDate", context)
        tomap.uuid                  <- "uuid" >*<
        tomap.name                  <- "name" >*<
        tomap.salary                <- "data.salary"  >*<
        tomap.isEmployeeOfMonth     <- "data.is_employee_of_month"  >*<
        tomap.percentYearlyRaise    <- "data.percent_yearly_raise" >*<
        context
    }
}
