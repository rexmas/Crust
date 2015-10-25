import RealmSwift

public class Employee: Object {
    
    dynamic var employer: Company?
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var joinDate: NSDate = NSDate()
    var salary: Int = 0
    var isEmployeeOfMonth: Bool = false
    var percentYearlyRaise: Double = 0.0
}
