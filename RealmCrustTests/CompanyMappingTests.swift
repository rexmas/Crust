import XCTest
import Crust
import JSONValueRX
import Realm

class CompanyMappingTests: RealmMappingTest {
    
    func testJsonToCompany() {
        
        XCTAssertEqual(Company.allObjects(in: realm!).count, 0)
        let stub = CompanyStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMapping>()
        let object = try! mapper.mapFromJSONToNewObject(json, mapping: CompanyMapping(adaptor: adaptor!))
        
        try! self.adaptor!.save(objects: [ object ])
        
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertTrue(stub.matches(object: object))
    }
    
    func testUsesExistingObject() {
        
        let uuid = NSUUID().uuidString;
        
        let original = Company()
        original.uuid = uuid;
        try! self.adaptor!.save(objects: [ original ])
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        
        let stub = CompanyStub()
        stub.uuid = uuid;
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMapping>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: CompanyMapping(adaptor: adaptor!))
                
        XCTAssertEqual(original, object)
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertTrue(stub.matches(object: object))
    }
    
    func testDuplicateJsonObjectsAreNotCreatedTwice() {
        
        XCTAssertEqual(Company.allObjects(in: realm!).count, 0)
        let stub = CompanyStub()
        let employeeStub = EmployeeStub()
        stub.employees = [ employeeStub ]
        stub.founder = employeeStub.copy()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMapping>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: CompanyMapping(adaptor: adaptor!))
        
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 1)
        XCTAssertTrue(employeeStub.matches(object: object.founder!))
        XCTAssertTrue(employeeStub.matches(object: object.employees.firstObject()!))
        XCTAssertTrue(stub.matches(object: object))
    }
    
    func testDuplicateJsonObjectsInArrayAreEqualObjectsInListWithArrayDedupingOff() {
        
        XCTAssertEqual(Company.allObjects(in: realm!).count, 0)
        let stub = CompanyStub()
        let employeeStub = EmployeeStub()
        stub.employees = [ employeeStub, employeeStub, employeeStub.copy() ]
        stub.founder = employeeStub.copy()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMappingWithDupes>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: CompanyMappingWithDupes(adaptor: adaptor!))
        
        XCTAssertEqual(object.employees.count, 3)
        XCTAssertEqual(object.employees[0], object.employees[1])
        XCTAssertEqual(object.employees[1], object.employees[2])
    }
    
    func testDuplicateJsonObjectsInArrayMergeToSingleObjectWhenEqualityIsPresent() {
        
        XCTAssertEqual(Company.allObjects(in: realm!).count, 0)
        let stub = CompanyStub()
        let employeeStub = EmployeeStub()
        stub.employees = [ employeeStub, employeeStub, employeeStub.copy() ]
        stub.founder = employeeStub.copy()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMapping>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: CompanyMapping(adaptor: adaptor!))
        
        XCTAssertEqual(Employee.allObjects().count, 1)
        XCTAssertEqual(object.employees.count, 1)
    }
    
    func testNilFounderNilsRelationship() {
        let uuid = NSUUID().uuidString;
        
        let original = Company()
        original.uuid = uuid
        original.founder = Employee()
        try! self.adaptor!.save(objects: [ original ])
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 1)
        
        let stub = CompanyStub()
        stub.uuid = uuid;
        stub.founder = nil;
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMapping>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: CompanyMapping(adaptor: adaptor!))
        
        XCTAssertTrue(stub.matches(object: object))
        XCTAssertNil(object.founder)
    }
}