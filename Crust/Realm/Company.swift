import RealmSwift

public class Company: Object {
    
    let employees = List<Employee>()
    dynamic var uuid: String?
    dynamic var foundingDate: NSDate?
    dynamic var founder: Employee?
    dynamic var pendingLawsuits: Int = 0
}
