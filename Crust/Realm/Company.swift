import RealmSwift

public class Company: Object {
    
    public let employees = List<Employee>()
    public dynamic var uuid: String = ""
    public dynamic var name: String = ""
    public dynamic var foundingDate: NSDate = NSDate()
    public dynamic var founder: Employee?
    public dynamic var pendingLawsuits: Int = 0
}
