import XCTest
import Crust
import JSONValueRX

class Parent: AnyMappable {
    required init() { }
    
    var uuid: String = ""
    var companies: [Company]? = nil
}

class ParentMapping: AnyMapping {
    typealias MappedObject = Parent
    typealias AdapterKind = AnyAdapterImp<Parent>
    
    func mapping(toMap: inout Parent, context: MappingContext) {
        let companyMapping = CompanyMapping(adapter: RealmAdapter(realm: RLMRealm.default()))
        
        toMap.companies <- .mapping("companies", companyMapping) >*<
        toMap.uuid      <- "uuid" >*<
        context
    }
}

class NestedMappingTests: RealmMappingTest {
    
    func testMappingTransactionOccursForNestedMappingOfRealmAdapter() {
        let companyStub1 = CompanyStub()
        let companyStub2 = CompanyStub()
        let employeeStub = EmployeeStub()
        companyStub1.employees.append(employeeStub)
        
        let jsonObject: [String : Any] = [
            "uuid" : NSUUID().uuidString,
            "companies" : [
                companyStub1.generateJsonObject(),
                companyStub2.generateJsonObject()
            ]
        ]
        
        let json = try! JSONValue(dict: jsonObject)
        let mapper = Mapper()
        let parent = try! mapper.map(from: json, using: ParentMapping())
        
        XCTAssertEqual(parent.uuid, jsonObject["uuid"] as! String)
        XCTAssertTrue(companyStub1.matches(object: parent.companies![0]))
        XCTAssertTrue(companyStub2.matches(object: parent.companies![1]))
        XCTAssertEqual(Company.allObjects(in: self.realm).count, 2)
        XCTAssertEqual(Employee.allObjects(in: self.realm).count, 3)
    }
}
