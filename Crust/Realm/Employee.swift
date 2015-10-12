import RealmSwift

class Employee: Object {
    
    dynamic var employer: Company?
    dynamic var uuid: String?
    dynamic var name: String?
    dynamic var joinDate: NSDate?
    dynamic var salary: NSNumber?               // Int64
    dynamic var isEmployeeOfMonth: NSNumber?    // Bool
    dynamic var percentYearlyRaise: NSNumber?   // Double
    
// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return []
//  }
}
