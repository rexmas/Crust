import Foundation
import Crust

class EmployeeStub {
    
    //    var employer: CompanyStub?
    var uuid: String = NSUUID().UUIDString
    var name: String = "John"
    var joinDate: NSDate = NSDate()
    var salary: NSNumber = 44                   // Int64
    var isEmployeeOfMonth: NSNumber = false     // Bool
    var percentYearlyRaise: NSNumber = 0.5      // Double
    
    init() {
        
    }
    
    func generateJsonObject() -> Dictionary<String, AnyObject> {
        return [
            "uuid" : uuid,
            "name" : name,
            "joinDate" : joinDate.toISOString(),
            "data" : [
                "salary" : salary,
                "is_employee_of_month" : isEmployeeOfMonth,
                "percent_yearly_raise" : percentYearlyRaise
            ]
        ]
    }
    
    func matches(object: Employee) -> Bool {
        var matches = true
        matches &&= uuid == object.uuid
        matches &&= name == object.name
        matches &&= floor(joinDate.timeIntervalSinceReferenceDate) == object.joinDate.timeIntervalSinceReferenceDate
        matches &&= salary == object.salary
        matches &&= isEmployeeOfMonth == object.isEmployeeOfMonth
        matches &&= percentYearlyRaise == object.percentYearlyRaise
        
        return matches
    }
}
