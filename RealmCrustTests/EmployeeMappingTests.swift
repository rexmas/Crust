import XCTest
import Crust
import JSONValueRX
import Realm

class EmployeeMappingTests: RealmMappingTest {
    
    func testJsonToEmployee() {
        
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 0)
        let stub = EmployeeStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: EmployeeMapping(adapter: adapter!))
        
        try! self.adapter!.save(objects: [ object ])
        
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 1)
        XCTAssertTrue(stub.matches(object: object))
    }
}
