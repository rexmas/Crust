import XCTest
import Crust
import JSONValueRX

class Parent: AnyMappable {
    required init() { }
    
    var uuid: String = ""
    var companies: [Company]? = nil
}

class MockRealmAdapter: RealmAdapter {
    var numberOfCallsToMappingWillBegin = 0
    override func mappingWillBegin() throws {
        numberOfCallsToMappingWillBegin += 1
        try super.mappingWillBegin()
    }
}

class ParentMapping: AnyMapping {
    var numberOfCallsToMappingWillBegin = 0
    
    func mapping(toMap: inout Parent, payload: MappingPayload<String>) {
        let realmAdapter = MockRealmAdapter(realm: RLMRealm.default())
        let companyMapping = CompanyMapping(adapter: realmAdapter)
        
        toMap.companies <- (.mapping("companies", companyMapping), payload)
        toMap.uuid      <- ("uuid", payload)
        
        numberOfCallsToMappingWillBegin = realmAdapter.numberOfCallsToMappingWillBegin
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
        let parent = try! mapper.map(from: json, using: ParentMapping(), keyedBy: AllKeys())
        
        XCTAssertEqual(parent.uuid, jsonObject["uuid"] as! String)
        XCTAssertTrue(companyStub1.matches(object: parent.companies![0]))
        XCTAssertTrue(companyStub2.matches(object: parent.companies![1]))
        XCTAssertEqual(Company.allObjects(in: self.realm).count, 2)
        XCTAssertEqual(Employee.allObjects(in: self.realm).count, 3)
    }
    
    func testMappingTransactionIsBatchedForNestedMappingOfRealmArray() {
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
        let mapping = ParentMapping()
        _ = try! mapper.map(from: json, using: mapping, keyedBy: AllKeys())
        
        XCTAssertEqual(mapping.numberOfCallsToMappingWillBegin, 1)
    }
    
    func testTransactionCorrectlyClosedForNestedMapping() {
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
        let mapping = ParentMapping()
        
        // We do this twice because these functions have slightly different paths at the beginning.
        _ = try! mapper.map(from: json, using: mapping, keyedBy: AllKeys())
        XCTAssertFalse(self.realm.inWriteTransaction)
        
        _ = try! mapper.map(from: json, using: Binding.mapping("", mapping), keyedBy: AllKeys())
        XCTAssertFalse(self.realm.inWriteTransaction)
    }
}
