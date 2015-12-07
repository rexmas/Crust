import XCTest
import Crust

class StructMappingTests: XCTestCase {

    func testStructMapping() {
        
        let stub = PersonStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Person, PersonMapping>()
        let object = try! mapper.mapFromJSONToNewObject(json, mapping: PersonMapping())
        
        XCTAssertTrue(stub.matches(object))
    }
}
