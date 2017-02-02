import XCTest
@testable import Crust
import JSONValueRX

extension EmployeeMapping: ArraySubMapping { }

fileprivate typealias AllEmployeesMapping = ArrayMapping<Employee, RealmAdaptor, EmployeeMapping>

fileprivate class AllEmployeesMappingWithDupes: ArrayMapping<Employee, RealmAdaptor, EmployeeMapping> {
}

class ArrayAdaptorTests: RealmMappingTest {
    /*
    func testArrayWithDupesNotAllowed() {
        let employeeStub = EmployeeStub()
        let employeeStub2 = EmployeeStub()
        let json = try! JSONValue(object: employeeStub.generateJsonObject())
        let json2 = try! JSONValue(object: employeeStub2.generateJsonObject())
        let employeesJSON = JSONValue.array([json, json, json2, json])
        
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 0)
        
        let mapper = Mapper<AllEmployeesMapping>()
        let adaptor = RealmArrayAdaptor<Employee>()
        let obj = try! mapper.map(from: employeesJSON, using: AllEmployeesMapping(adaptor: adaptor))
        
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 2)
        XCTAssertEqual(obj.count, 2)
        XCTAssertNotEqual(obj[0].uuid, obj[1].uuid)
        XCTAssertTrue(employeeStub.matches(object: obj[0]))
        XCTAssertTrue(employeeStub2.matches(object: obj[1]))
    }
    
    func testArrayAllowingDupes() {
        let employeeStub = EmployeeStub()
        let employeeStub2 = EmployeeStub()
        let json = try! JSONValue(object: employeeStub.generateJsonObject())
        let json2 = try! JSONValue(object: employeeStub2.generateJsonObject())
        let employeesJSON = JSONValue.array([json, json, json2, json])
        
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 0)
        
        let mapper = Mapper<AllEmployeesMappingWithDupes>()
        let adaptor = RealmArrayAdaptor<Employee>()
        let obj = try! mapper.map(from: employeesJSON, using: AllEmployeesMappingWithDupes(adaptor: adaptor))
        
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 2)
        XCTAssertEqual(obj.count, 4)
        XCTAssertEqual(obj[0].uuid, obj[1].uuid)
        XCTAssertNotEqual(obj[1].uuid, obj[2].uuid)
        XCTAssertEqual(obj[0].uuid, obj[3].uuid)
        XCTAssertTrue(employeeStub.matches(object: obj[0]))
        XCTAssertTrue(employeeStub2.matches(object: obj[2]))
    }
 */
}
