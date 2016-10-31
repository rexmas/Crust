import Foundation
import Crust

class CompanyStub {
    
    var employees = [ EmployeeStub ]()
    var uuid: String = UUID().uuidString
    var name: String = "Derp International"
    var foundingDate: Date = Date()
    var founder: EmployeeStub? = EmployeeStub()
    var pendingLawsuits: Int = 5
    
    init() { }
    
    func copy() -> CompanyStub {
        let copy = CompanyStub()
        copy.employees = employees.map { $0.copy() }
        copy.uuid = uuid
        copy.name = name
        copy.foundingDate = foundingDate
        copy.founder = founder?.copy()
        copy.pendingLawsuits = pendingLawsuits
        
        return copy
    }
    
    func generateJsonObject() -> [AnyHashable : Any] {
        let founder = self.founder?.generateJsonObject()
        return [
            "name" : name as AnyObject,
            "employees" : employees.map { $0.generateJsonObject() } as NSArray,
            "founder" : founder == nil ? NSNull() : founder! as NSDictionary,
            "data" : [
                "uuid" : uuid,
                "lawsuits" : [
                    "pending" : pendingLawsuits
                ]
            ],
            "data.founding_date" : foundingDate.isoString,
        ]
    }
    
    func matches(_ object: Company) -> Bool {
        var matches = true
        matches &&= uuid == object.uuid
        matches &&= name == object.name
        matches &&= floor(foundingDate.timeIntervalSinceReferenceDate) == floor(object.foundingDate.timeIntervalSinceReferenceDate)
        matches &&= pendingLawsuits == object.pendingLawsuits
        if let founder = founder {
            matches &&= founder.matches(object.founder!)
        } else if object.founder != nil {
            return false
        }
        for (i, employeeStub) in employees.enumerated() {
            matches &&= employeeStub.matches(object.employees[i])
        }
        
        return matches
    }
}
