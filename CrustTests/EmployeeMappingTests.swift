import XCTest
import Crust
import RealmSwift

class EmployeeMappingTests: XCTestCase {
    
    var realm: Realm?

    override func setUp() {
        super.setUp()
        
        // Use an in-memory Realm identified by the name of the current test.
        // This ensures that each test can't accidentally access or modify the data
        // from other tests or the application itself, and because they're in-memory,
        // there's nothing that needs to be cleaned up.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
        realm = try! Realm()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testJsonToEmployee() {
        
        XCTAssertEqual(realm!.objects(Employee), 0)
        var employeeJson = try! JSONValue(object: EmployeeStub().generateJsonObject())
        
        XCTAssertEqual(realm!.objects(Employee), 1)
    }
}

class EmployeeStub {

//    var employer: CompanyStub?
    var uuid: String?
    var name: String?
    var joinDate: NSDate?
    var salary: NSNumber?               // Int64
    var isEmployeeOfMonth: NSNumber?    // Bool
    var percentYearlyRaise: NSNumber?   // Double
    
    init() {
        uuid = NSUUID().UUIDString
        name = "John"
        joinDate = NSDate()
        salary = 44
        isEmployeeOfMonth = false
        percentYearlyRaise = 0.5
    }
    
    func generateJsonObject() -> Dictionary<String, Any?> {
        return [
            "uuid" : uuid,
            "name" : name,
            "joinDate" : joinDate,
            "data" : [
                "salary" : salary,
                "is_employee_of_month" : isEmployeeOfMonth,
                "percent_yearly_raise" : percentYearlyRaise
            ]
        ]
    }
}
