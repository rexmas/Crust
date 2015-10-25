import XCTest
import Crust
import RealmSwift

class EmployeeMappingTests: RealmMappingTest {
    
    func testJsonToEmployee() {
        
        XCTAssertEqual(realm!.objects(Employee).count, 0)
        let employeeStub = EmployeeStub()
        let employeeJson = try! JSONValue(object: employeeStub.generateJsonObject())
        let mapper = CRMapper<Employee, EmployeeMapping>()
        let employee = try! mapper.mapFromJSONToNewObject(employeeJson, mapping: EmployeeMapping(adaptor: adaptor!))
        
        self.adaptor!.saveObjects([ employee ])
        
        XCTAssertEqual(realm!.objects(Employee).count, 1)
        XCTAssertTrue(employeeStub.matches(employee))
    }
}
