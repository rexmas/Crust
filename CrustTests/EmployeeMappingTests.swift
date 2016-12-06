import XCTest
import Crust
import JSONValueRX

class EmployeeMappingTests: XCTestCase {
    
    func testJsonToEmployee() {
        
        let stub = EmployeeStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Employee, EmployeeMapping>()
        let object = try! mapper.mapFromJSONToNewObject(json, mapping: EmployeeMapping(adaptor: MockAdaptor<Employee>()))
        
        XCTAssertTrue(stub.matches(object))
    }
}
