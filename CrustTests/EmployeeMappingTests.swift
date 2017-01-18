import XCTest
import Crust
import JSONValueRX

class EmployeeMappingTests: XCTestCase {
    
    func testJsonToEmployee() {
        
        let stub = EmployeeStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper<EmployeeMapping>()
        let object = try! mapper.map(from: json, using: EmployeeMapping(adaptor: MockAdaptor<Employee>()))
        
        XCTAssertTrue(stub.matches(object))
    }
}
