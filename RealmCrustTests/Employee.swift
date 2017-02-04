import Crust
import Realm

public class EmployeeMapping : RealmMapping {
    
    public var adaptor: RealmAdaptor
    public var primaryKeys: [String : Keypath]? {
        return [ "uuid" : "uuid" ]
    }
    
    public required init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    public func mapping(tomap: inout Employee, context: MappingContext) {
        let companyMapping = CompanyMapping(adaptor: self.adaptor)
        let key = Spec.mapping("company", companyMapping)
        
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
