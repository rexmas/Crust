import Foundation
import Crust

class EmployeeStub {
    
    var employer: CompanyStub?
    var uuid: String = NSUUID().uuidString
    var name: String = "John"
    var joinDate: NSDate = NSDate()
    var salary: NSNumber = 44                   // Int64
    var isEmployeeOfMonth: NSNumber = false     // Bool
    var percentYearlyRaise: NSNumber = 0.5      // Double
    
    init() { }
    
    func copy() -> EmployeeStub {
        let copy = EmployeeStub()
        copy.employer = employer?.copy()
        copy.uuid = uuid
        copy.name = name
        copy.joinDate = joinDate.copy() as! NSDate
        copy.salary = salary.copy() as! NSNumber
        copy.isEmployeeOfMonth = isEmployeeOfMonth.copy() as! NSNumber
        copy.percentYearlyRaise = percentYearlyRaise.copy() as! NSNumber
        
        return copy
    }
    
    func generateJsonObject() -> [String : Any] {
        let company = employer?.generateJsonObject()
        return [
            "uuid" : uuid,
            "name" : name,
            "joinDate" : (joinDate as Date).isoString,
            "company" :  company == nil ? NSNull() : company! as NSDictionary,
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
        // TODO: Consistently off by almost a millisecond, figure out why.
        matches &&= floor(joinDate.timeIntervalSinceReferenceDate) == floor(object.joinDate!.timeIntervalSinceReferenceDate)
        matches &&= salary.intValue == object.salary?.intValue
        matches &&= isEmployeeOfMonth.boolValue == object.isEmployeeOfMonth?.boolValue
        matches &&= percentYearlyRaise.doubleValue == object.percentYearlyRaise?.doubleValue
        if let employer = employer {
            matches &&= (employer.matches(object: object.employer!))
        } else if object.employer != nil {
            return false
        }
        
        return matches
    }
}
