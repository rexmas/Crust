import XCTest
import Crust
import RealmSwift

class EmployeeMappingTests: XCTestCase {
    
    var realm: Realm?
    var adaptor: RealmAdaptor?

    override func setUp() {
        super.setUp()
        
        // Use an in-memory Realm identified by the name of the current test.
        // This ensures that each test can't accidentally access or modify the data
        // from other tests or the application itself, and because they're in-memory,
        // there's nothing that needs to be cleaned up.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
        realm = try! Realm()
        
        adaptor = RealmAdaptor(realm: realm!)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testJsonToEmployee() {
        
        XCTAssertEqual(realm!.objects(Employee).count, 0)
        let jsonObj = EmployeeStub().generateJsonObject()
        let employeeJson = try! JSONValue(object: jsonObj)
        let mapper = CRMapper<Employee, EmployeeMapping>()
        let employee = try! mapper.mapFromJSONToNewObject(employeeJson, mapping: EmployeeMapping(adaptor: adaptor!))
        
        self.adaptor!.saveObjects([ employee ])
        
        XCTAssertEqual(realm!.objects(Employee).count, 1)
    }
}

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
    
    func generateJsonObject() -> Dictionary<String, Any> {
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
}
