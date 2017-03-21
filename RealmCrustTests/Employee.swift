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
    
    public func mapping(toMap: inout Employee, context: MappingContext) {
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
