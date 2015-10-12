import Realm

class Company: Object {
    
    let employees = List<Employee>()
    dynamic var uuid: String?
    dynamic var foundingDate: NSDate?
    dynamic var founder: Employee?
    dynamic var pendingLawsuits: Int64?
    
// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return []
//  }
}
