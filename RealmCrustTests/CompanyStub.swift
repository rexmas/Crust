import Foundation
import Crust

class CompanyStub {
    
    var employees = [ EmployeeStub ]()
    var uuid: String = NSUUID().uuidString
    var name: String = "Derp International"
    var foundingDate: NSDate = NSDate()
    var founder: EmployeeStub? = EmployeeStub()
    var pendingLawsuits: Int = 5
    
    init() { }
    
    func copy() -> CompanyStub {
        let copy = CompanyStub()
        copy.employees = employees.map { $0.copy() }
        copy.uuid = uuid
        copy.name = name
        copy.foundingDate = foundingDate.copy() as! NSDate
        copy.founder = founder?.copy()
        copy.pendingLawsuits = pendingLawsuits
        
        return copy
    }
    
    func generateJsonObject() -> [String : Any] {
        let founder = self.founder?.generateJsonObject()
        return [
            "name" : name,
            "employees" : employees.map { $0.generateJsonObject() } as NSArray,
            "founder" : founder == nil ? NSNull() : founder! as NSDictionary,
            "data" : [
                "uuid" : uuid,
                "lawsuits" : [
                    "pending" : pendingLawsuits
                ]
            ],
            "data.founding_date" : (foundingDate as Date).isoString,
        ]
    }
    
    func matches(object: Company) -> Bool {
        var matches = true
        matches &&= uuid == object.uuid
        matches &&= name == object.name
        // TODO: The conversion seems to be consistently off by 1 millisecond, figure out why.
        matches &&= floor(foundingDate.timeIntervalSinceReferenceDate) == floor(object.foundingDate!.timeIntervalSinceReferenceDate)
        matches &&= pendingLawsuits == object.pendingLawsuits?.intValue
        if let founder = founder {
            matches &&= founder.matches(object: object.founder!)
        } else if object.founder != nil {
            return false
        }
        for (i, employeeStub) in employees.enumerated() {
            matches &&= employeeStub.matches(object: object.employees[UInt(i)])
        }
        
        return matches
    }
}
