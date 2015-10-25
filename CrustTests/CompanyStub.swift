import Foundation
import Crust

class CompanyStub {
    
    var employees = [ EmployeeStub ]()
    var uuid: String = NSUUID().UUIDString
    var name: String = "Derp International"
    var foundingDate: NSDate = NSDate()
//    var founder: EmployeeStub?
    var pendingLawsuits: Int = 5
    
    init() {
        
    }
    
    func generateJsonObject() -> Dictionary<String, Any> {
        return [
            "uuid" : uuid,
            "name" : name,
            "employees" : employees.map { $0.generateJsonObject },
            "data" : [
                "lawsuits" : [
                    "pending" : pendingLawsuits
                ],
                "founding_date" : foundingDate.toISOString(),
            ]
        ]
    }
    
    func matches(object: Company) -> Bool {
        var matches = true
        matches &&= uuid == object.uuid
        matches &&= name == object.name
        matches &&= floor(foundingDate.timeIntervalSinceReferenceDate) == object.foundingDate.timeIntervalSinceReferenceDate
        matches &&= pendingLawsuits == object.pendingLawsuits
        
        for (i, employeeStub) in employees.enumerate() {
            matches &&= employeeStub.matches(object.employees[i])
        }
        
        return matches
    }
}
