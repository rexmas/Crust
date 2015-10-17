import RealmSwift

public class Employee: Object {
    
    dynamic var employer: Company?
    dynamic var uuid: String?
    dynamic var name: String?
    dynamic var joinDate: NSDate?
    dynamic var salary: NSNumber?               // Int64
    dynamic var isEmployeeOfMonth: NSNumber?    // Bool
    dynamic var percentYearlyRaise: NSNumber?   // Double
}
