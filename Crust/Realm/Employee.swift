import RealmSwift

public class Employee: Object {
    
    public dynamic var employer: Company?
    public dynamic var uuid: String = ""
    public dynamic var name: String = ""
    public dynamic var joinDate: NSDate = NSDate()
    public dynamic var salary: Int = 0
    public dynamic var isEmployeeOfMonth: Bool = false
    public dynamic var percentYearlyRaise: Double = 0.0
}
