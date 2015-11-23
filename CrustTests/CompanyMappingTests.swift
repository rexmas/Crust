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
        
        try! self.adaptor!.saveObjects([ object ])
        
        XCTAssertEqual(realm!.objects(Company).count, 1)
        XCTAssertTrue(stub.matches(object))
    }
    
    func testUsesExistingObject() {
        
        let uuid = NSUUID().UUIDString;
        
        let original = Company()
        original.uuid = uuid;
        try! self.adaptor!.saveObjects([ original ])
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
    
    func testDuplicateJsonObjectsAreNotCreatedTwice() {
        
        XCTAssertEqual(realm!.objects(Company).count, 0)
        let stub = CompanyStub()
        let employeeStub = EmployeeStub()
        stub.employees = [ employeeStub ]
        stub.founder = employeeStub.copy()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMapping>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: CompanyMapping(adaptor: adaptor!))
        
        try! self.adaptor!.saveObjects([ object ])
                
        XCTAssertEqual(realm!.objects(Company).count, 1)
        XCTAssertEqual(realm!.objects(Employee).count, 1)
        XCTAssertEqual(object.employees.first!, object.founder!)
        XCTAssertTrue(stub.matches(object))
    }
    
    func testDuplicateJsonObjectsInArrayAreEqualObjectsInList() {
        
        XCTAssertEqual(realm!.objects(Company).count, 0)
        let stub = CompanyStub()
        let employeeStub = EmployeeStub()
        stub.employees = [ employeeStub, employeeStub, employeeStub.copy() ]
        stub.founder = employeeStub.copy()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMapping>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: CompanyMapping(adaptor: adaptor!))
        
        XCTAssertEqual(object.employees.count, 3)
        XCTAssertEqual(object.employees[0], object.employees[1])
        XCTAssertEqual(object.employees[1], object.employees[2])
    }
    
    func testDuplicateJsonObjectsInArrayMergeToSingleObjectWithArrayDedupingOn() {
        
        XCTAssertEqual(realm!.objects(Company).count, 0)
        let stub = CompanyStub()
        let employeeStub = EmployeeStub()
        stub.employees = [ employeeStub, employeeStub, employeeStub.copy() ]
        stub.founder = employeeStub.copy()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Company, CompanyMapping>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: CompanyMapping(adaptor: adaptor!))
        
        try! self.adaptor!.saveObjects([ object ])
        
        XCTAssertEqual(object.employees.count, 1)
    }
    
    func testFailureToMapReturnsError() {
        // TODO: Caching scheme added to adaptor.
    }
    
    func testMappingArrayOfValues() {
        // TODO: Make a new test file that's all structs, test struct mappings.
    }
    
    func testWithNilFounder() {
        
    }
    
    func testWithManyEmployees() {
        
    }
    
    func testWith0Employees() {
        
    }
}
