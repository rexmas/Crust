import XCTest
import Crust
import RealmSwift

class CompanyMappingTests: RealmMappingTest {
    
    func testJsonToCompany() {
        
        XCTAssertEqual(realm!.objects(Company).count, 0)
        let stub = CompanyStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMapping>()
        let object = try! mapper.mapFromJSONToNewObject(json, mapping: CompanyMapping(adaptor: adaptor!))
        
        self.adaptor!.saveObjects([ object ])
        
        XCTAssertEqual(realm!.objects(Company).count, 1)
        XCTAssertTrue(stub.matches(object))
    }
    
    func testUsesExistingObject() {
        
        let uuid = NSUUID().UUIDString;
        
        let original = Company()
        original.uuid = uuid;
        self.adaptor!.saveObjects([ original ])
        XCTAssertEqual(realm!.objects(Company).count, 1)
        
        let stub = CompanyStub()
        stub.uuid = uuid;
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMapping>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: CompanyMapping(adaptor: adaptor!))
                
        XCTAssertEqual(original, object)
        XCTAssertEqual(realm!.objects(Company).count, 1)
        XCTAssertTrue(stub.matches(object))
    }
    
    func testDuplicateObjectsAreNotCreatedTwice() {
        // TODO: Caching scheme added to adaptor.
    }
    
    func testWithNilFounder() {
        
    }
    
    func testWithManyEmployees() {
        
    }
    
    func testWith0Employees() {
        
    }
}
