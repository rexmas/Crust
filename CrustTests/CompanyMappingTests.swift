import XCTest
import Crust
import JSONValueRX

class CompanyMappingTests: XCTestCase {
    
    func testJsonToCompany() {
        let stub = CompanyStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: CompanyMapping(adapter: MockAdapter<Company>()), keyedBy: AllKeysProvider())
        
        XCTAssertTrue(stub.matches(object))
    }
    
    func testNestedJsonToCompany() {
        let stub = CompanyStub()
        let jsonObj = [ "data.company" : stub.generateJsonObject() ]
        let json = try! JSONValue(object: jsonObj)
        let mapper = Mapper()
        let binding = Binding.mapping("data.company", CompanyMapping(adapter: MockAdapter<Company>()))
        let object = try! mapper.map(from: json, using: binding, keyedBy: AllKeysProvider())
        
        XCTAssertTrue(stub.matches(object))
    }
    
    class MockAdapterExistingCompany: MockAdapter<Company> {
        var company: Company
        
        required init(withCompany company: Company) {
            self.company = company
        }
        
        override func fetchObjects(type: BaseType.Type, primaryKeyValues: [[String : CVarArg]], isMapping: Bool) -> [Company] {
            return [ self.company ]
        }
    }
    
    func testUsesExistingObject() {
        
        let uuid = UUID().uuidString;
        
        let original = Company()
        original.uuid = uuid
        let adapter = MockAdapterExistingCompany(withCompany: original)
        
        let stub = CompanyStub()
        stub.uuid = uuid;
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: CompanyMapping(adapter: adapter), keyedBy: AllKeysProvider())
        
        XCTAssertTrue(object === original)
        XCTAssertTrue(stub.matches(object))
    }
    
    func testNilOptionalNilsRelationship() {
        let uuid = UUID().uuidString;
        
        let original = Company()
        original.uuid = uuid
        original.founder = Employee()
        
        let adapter = MockAdapterExistingCompany(withCompany: original)
        
        let stub = CompanyStub()
        stub.uuid = uuid;
        stub.founder = nil;
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: CompanyMapping(adapter: adapter), keyedBy: AllKeysProvider())
        
        XCTAssertTrue(stub.matches(object))
        XCTAssertNil(object.founder)
    }
}
