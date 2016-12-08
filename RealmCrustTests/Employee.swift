import Crust
import Realm

//public class Employee: RLMObject {
//    
//    public dynamic var employer: Company?
//    public dynamic var uuid: String = ""
//    public dynamic var name: String = ""
//    public dynamic var joinDate: NSDate = NSDate()
//    public dynamic var salary: Int = 0
//    public dynamic var isEmployeeOfMonth: Bool = false
//    public dynamic var percentYearlyRaise: Double = 0.0
//}

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
