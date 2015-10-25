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
}
