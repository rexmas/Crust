import XCTest
import Crust
import JSONValueRX

class CompanyMappingTests: XCTestCase {
    
    func testJsonToCompany() {
        
        let stub = CompanyStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper<CompanyMapping>()
        let object = try! mapper.map(from: json, using: CompanyMapping(adaptor: MockAdaptor<Company>()))
        
        XCTAssertTrue(stub.matches(object))
    }
    
    class MockAdaptorExistingCompany: MockAdaptor<Company> {
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
        let adaptor = MockAdaptorExistingCompany(withCompany: original)
        
        let stub = CompanyStub()
        stub.uuid = uuid;
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper<CompanyMapping>()
        let object = try! mapper.map(from: json, using: CompanyMapping(adaptor: adaptor))
        
        XCTAssertTrue(object === original)
        XCTAssertTrue(stub.matches(object))
    }
    
    func testNilOptionalNilsRelationship() {
        let uuid = UUID().uuidString;
        
        let original = Company()
        original.uuid = uuid
        original.founder = Employee()
        
        let adaptor = MockAdaptorExistingCompany(withCompany: original)
        
        let stub = CompanyStub()
        stub.uuid = uuid;
        stub.founder = nil;
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper<CompanyMapping>()
        let object = try! mapper.map(from: json, using: CompanyMapping(adaptor: adaptor))
        
        XCTAssertTrue(stub.matches(object))
        XCTAssertNil(object.founder)
    }
}
