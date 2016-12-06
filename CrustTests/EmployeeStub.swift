import Foundation
import Crust

class EmployeeStub {
    
    var employer: CompanyStub?
    var uuid: String = UUID().uuidString
    var name: String = "John"
    var joinDate: Date = Date()
    var salary: Int = 44
    var isEmployeeOfMonth: Bool = false
    var percentYearlyRaise: Double = 0.5
    
    init() { }
    
    func copy() -> EmployeeStub {
        let copy = EmployeeStub()
        copy.employer = employer?.copy()
        copy.uuid = uuid
        copy.name = name
        copy.joinDate = joinDate
        copy.salary = salary
        copy.isEmployeeOfMonth = isEmployeeOfMonth
        copy.percentYearlyRaise = percentYearlyRaise
        
        return copy
    }
    
    func generateJsonObject() -> [AnyHashable : Any] {
        let company = employer?.generateJsonObject()
        return [
            "uuid" : uuid as AnyObject,
            "name" : name as AnyObject,
            "joinDate" : joinDate.isoString,
            "company" :  company == nil ? NSNull() : company! as NSDictionary,
            "data" : [
                "salary" : salary,
                "is_employee_of_month" : isEmployeeOfMonth,
                "percent_yearly_raise" : percentYearlyRaise
            ]
        ]
    }
    
    func matches(_ object: Employee) -> Bool {
        var matches = true
        matches &&= uuid == object.uuid
        matches &&= name == object.name
        matches &&= floor(joinDate.timeIntervalSinceReferenceDate) == floor(object.joinDate.timeIntervalSinceReferenceDate)
        matches &&= salary == object.salary
        matches &&= isEmployeeOfMonth == object.isEmployeeOfMonth
        matches &&= percentYearlyRaise == object.percentYearlyRaise
        if let employer = employer {
            matches &&= (employer.matches(object.employer!))
        } else if object.employer != nil {
            return false
        }
        
        return matches
    }
}
