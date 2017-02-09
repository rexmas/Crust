import XCTest
import Crust
import JSONValueRX

class StructMappingTests: XCTestCase {

    func testStructMapping() {
        
        let stub = PersonStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: PersonMapping())
        
        XCTAssertTrue(stub.matches(object))
    }
    
    func testNilClearsOptionalValue() {
        
        let stub = PersonStub()
        var json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper()
        var object = try! mapper.map(from: json, using: PersonMapping())
        
        XCTAssertTrue(object.ownsCat!)
        
        stub.ownsCat = nil
        json = try! JSONValue(object: stub.generateJsonObject())
        object = try! mapper.map(from: json, to: object, using: PersonMapping())
        
        XCTAssertNil(object.ownsCat)
    }
}
