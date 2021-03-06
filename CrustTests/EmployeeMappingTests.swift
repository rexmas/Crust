import XCTest
import Crust
import JSONValueRX

class EmployeeMappingTests: XCTestCase {
    
    func testJsonToEmployee() {
        
        let stub = EmployeeStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: EmployeeMapping(adapter: MockAdapter<Employee>()), keyedBy: AllKeys())
        
        XCTAssertTrue(stub.matches(object))
    }
}
