import RealmSwift

public class Employee: Object {
    
    public dynamic var employer: Company?
    public dynamic var uuid: String = ""
    public dynamic var name: String = ""
    public dynamic var joinDate: NSDate = NSDate()
    public var salary: Int = 0
    public var isEmployeeOfMonth: Bool = false
    public var percentYearlyRaise: Double = 0.0
}
