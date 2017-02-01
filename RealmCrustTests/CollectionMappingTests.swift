import XCTest
@testable import Crust
import JSONValueRX

class CollectionMappingTests: RealmMappingTest {
    
    func testMappingCollection() {
        let employeeStub = EmployeeStub()
        let employeeStub2 = EmployeeStub()
        let json = try! JSONValue(object: employeeStub.generateJsonObject())
        let json2 = try! JSONValue(object: employeeStub2.generateJsonObject())
        let employeesJSON = JSONValue.array([json, json, json2, json])
        
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 0)
        
        let mapping = EmployeeMapping(adaptor: self.adaptor!)
        let mapper = Mapper<EmployeeMapping>()
        
        let spec = Spec.mapping("", mapping)
        //let collection: RLMArray<EmployeeMapping.MappedObject> = try! mapper.mapToAppendable(from: employeesJSON, using: spec)
        let collection: [Employee] = try! mapper.mapToCollection(from: employeesJSON, using: spec)
        
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 2)
        XCTAssertEqual(collection.count, 2)
        XCTAssertNotEqual(collection[0].uuid, collection[1].uuid)
        XCTAssertTrue(employeeStub.matches(object: collection[0]))
        XCTAssertTrue(employeeStub2.matches(object: collection[1]))
    }
}
