import XCTest
@testable import Crust
import JSONValueRX

extension Int: AnyMappable { }

class CollectionMappingTests: RealmMappingTest {
    
    func testMappingCollection() {
        let employeeStub = EmployeeStub()
        let employeeStub2 = EmployeeStub()
        let json = try! JSONValue(object: employeeStub.generateJsonObject())
        let json2 = try! JSONValue(object: employeeStub2.generateJsonObject())
        let employeesJSON = JSONValue.array([json, json, json2, json])
        
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 0)
        
        let mapping = EmployeeMapping(adapter: self.adapter!)
        let mapper = Mapper()
        
        let spec = Binding.mapping("", mapping)
        let collection: [Employee] = try! mapper.map(from: employeesJSON, using: spec)
        
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 2)
        XCTAssertEqual(collection.count, 2)
        XCTAssertNotEqual(collection[0].uuid, collection[1].uuid)
        XCTAssertTrue(employeeStub.matches(object: collection[0]))
        XCTAssertTrue(employeeStub2.matches(object: collection[1]))
    }
    
    func testMappingCollectionByAppendUnique() {
        class CompanyMappingAppendUnique: CompanyMapping {
            override func mapping(toMap: inout Company, context: MappingContext) {
                let employeeMapping = EmployeeMapping(adapter: self.adapter)
                map(toRLMArray: toMap.employees, using: (Binding.collectionMapping("employees", employeeMapping, (.append, true, false)), context))
            }
        }
        
        let uuid = NSUUID().uuidString
        let dupEmployeeStub = EmployeeStub()
        
        let original = Company()
        let originalEmployee = Employee()   // 1.
        let dupEmployee = Employee()        // 2.
        original.uuid = uuid
        originalEmployee.uuid = uuid
        dupEmployee.uuid = dupEmployeeStub.uuid
        original.employees.append(originalEmployee)
        original.employees.append(dupEmployee)
        try! self.adapter!.save(objects: [ original ])
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 2)
        
        let companyStub = CompanyStub()
        let employeeStub3 = EmployeeStub()   // 3.
        let employeeStub4 = EmployeeStub()  // 4.
        companyStub.uuid = uuid
        companyStub.employees = [employeeStub3, employeeStub3, employeeStub4, employeeStub3, dupEmployeeStub]
        let json = try! JSONValue(object: companyStub.generateJsonObject())
        
        let mapping = CompanyMappingAppendUnique(adapter: self.adapter!)
        let mapper = Mapper()
        
        let spec = Binding.mapping("", mapping)
        let company: Company = try! mapper.map(from: json, using: spec)
        let employees = company.employees
        
        XCTAssertEqual(original.uuid, company.uuid)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 4)
        XCTAssertEqual(employees.count, 4)
        XCTAssertEqual(employees[0].uuid, originalEmployee.uuid)
        XCTAssertTrue(dupEmployeeStub.matches(object: employees[1]))
        XCTAssertTrue(employeeStub3.matches(object: employees[2]))
        XCTAssertTrue(employeeStub4.matches(object: employees[3]))
    }
    
    func testMappingCollectionByReplaceUnique() {
        class CompanyMappingReplaceUnique: CompanyMapping {
            override func mapping(toMap: inout Company, context: MappingContext) {
                let employeeMapping = EmployeeMapping(adapter: self.adapter)
                map(toRLMArray: toMap.employees,
                    using: (.collectionMapping("employees", employeeMapping, (.replace(delete: nil), true, false)), context))
            }
        }
        
        let uuid = NSUUID().uuidString
        
        let original = Company()
        let originalEmployee = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        original.employees.append(originalEmployee)
        try! self.adapter!.save(objects: [ original ])
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 1)
        
        let companyStub = CompanyStub()
        let employeeStub = EmployeeStub()
        let employeeStub2 = EmployeeStub()
        companyStub.uuid = original.uuid!
        companyStub.employees = [employeeStub, employeeStub, employeeStub2, employeeStub]
        let json = try! JSONValue(object: companyStub.generateJsonObject())
        
        let mapping = CompanyMappingReplaceUnique(adapter: self.adapter!)
        let mapper = Mapper()
        
        let spec = Binding.mapping("", mapping)
        let company: Company = try! mapper.map(from: json, using: spec)
        let employees = company.employees
        
        XCTAssertEqual(original.uuid, company.uuid)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 3)
        XCTAssertEqual(employees.count, 2)
        XCTAssertTrue(employeeStub.matches(object: employees[0]))
        XCTAssertTrue(employeeStub2.matches(object: employees[1]))
    }
    
    func testMappingCollectionByReplaceDeleteUnique() {
        class CompanyMappingReplaceDeleteUnique: CompanyMapping {
            override func mapping(toMap: inout Company, context: MappingContext) {
                let employeeMapping = EmployeeMapping(adapter: self.adapter)
                map(toRLMArray: toMap.employees,
                    using: (.collectionMapping("employees", employeeMapping, (.replace(delete: { $0 }), true, false)), context))
            }
        }
        
        let uuid = NSUUID().uuidString
        let dupEmployeeStub = EmployeeStub()
        
        let original = Company()
        let originalEmployee = Employee()
        let dupEmployee = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        dupEmployee.uuid = dupEmployeeStub.uuid
        original.employees.append(originalEmployee)
        original.employees.append(dupEmployee)
        
        try! self.adapter!.save(objects: [ original ])
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 2)
        
        let companyStub = CompanyStub()
        let employeeStub = EmployeeStub()
        let employeeStub2 = EmployeeStub()
        companyStub.employees = [employeeStub, employeeStub, employeeStub2, employeeStub, dupEmployeeStub]
        companyStub.uuid = original.uuid!
        let json = try! JSONValue(object: companyStub.generateJsonObject())
        
        let mapping = CompanyMappingReplaceDeleteUnique(adapter: self.adapter!)
        let mapper = Mapper()
        
        let spec = Binding.mapping("", mapping)
        let company: Company = try! mapper.map(from: json, using: spec)
        let employees = company.employees
        
        XCTAssertEqual(original.uuid, company.uuid)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 3)
        XCTAssertEqual(employees.count, 3)
        XCTAssertTrue(employeeStub.matches(object: employees[0]))
        XCTAssertTrue(employeeStub2.matches(object: employees[1]))
        XCTAssertTrue(dupEmployeeStub.matches(object: employees[2]))
    }
    
    func testAssigningNullToCollectionWhenReplaceNullableRemovesAllAndDeletes() {
        class CompanyMappingReplaceNullable: CompanyMapping {
            override func mapping(toMap: inout Company, context: MappingContext) {
                let employeeMapping = EmployeeMapping(adapter: self.adapter)
                map(toRLMArray: toMap.employees,
                    using: (.collectionMapping("employees", employeeMapping, (.replace(delete: { $0 }), true, true)), context))
            }
        }
        
        let uuid = NSUUID().uuidString
        let dupEmployeeStub = EmployeeStub()
        
        let original = Company()
        let originalEmployee = Employee()
        let dupEmployee = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        dupEmployee.uuid = dupEmployeeStub.uuid
        original.employees.append(originalEmployee)
        original.employees.append(dupEmployee)
        
        let outsideEmployee = Employee()
        
        try! self.adapter!.save(objects: [ original, outsideEmployee ])
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 3)
        
        let companyStub = CompanyStub()
        companyStub.employees = []
        companyStub.uuid = original.uuid!
        var jsonObj = companyStub.generateJsonObject()
        XCTAssertEqual(jsonObj["employees"] as! NSArray, [])    // Sanity check.
        
        jsonObj["employees"] = NSNull()
        XCTAssertEqual(jsonObj["employees"] as! NSNull, NSNull())    // Sanity check.
        
        let json = try! JSONValue(object: jsonObj)
        
        let mapping = CompanyMappingReplaceNullable(adapter: self.adapter!)
        let mapper = Mapper()
        
        let spec = Binding.mapping("", mapping)
        let company: Company = try! mapper.map(from: json, using: spec)
        let employees = company.employees
        
        XCTAssertEqual(original.uuid, company.uuid)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 1)
        XCTAssertEqual(employees.count, 0)
    }
    
    func testAssigningNullToCollectionWhenAppendNullableDoesNothing() {
        class CompanyMappingAppendNullable: CompanyMapping {
            override func mapping(toMap: inout Company, context: MappingContext) {
                let employeeMapping = EmployeeMapping(adapter: self.adapter)
                map(toRLMArray: toMap.employees,
                    using: (.collectionMapping("employees", employeeMapping, (.append, true, true)), context))
            }
        }
        
        let uuid = NSUUID().uuidString
        let dupEmployeeStub = EmployeeStub()
        
        let original = Company()
        let originalEmployee = Employee()
        let dupEmployee = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        dupEmployee.uuid = dupEmployeeStub.uuid
        original.employees.append(originalEmployee)
        original.employees.append(dupEmployee)
        
        try! self.adapter!.save(objects: [ original ])
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 2)
        
        let companyStub = CompanyStub()
        companyStub.employees = []
        companyStub.uuid = original.uuid!
        var jsonObj = companyStub.generateJsonObject()
        XCTAssertEqual(jsonObj["employees"] as! NSArray, [])    // Sanity check.
        
        jsonObj["employees"] = NSNull()
        XCTAssertEqual(jsonObj["employees"] as! NSNull, NSNull())    // Sanity check.
        
        let json = try! JSONValue(object: jsonObj)
        
        let mapping = CompanyMappingAppendNullable(adapter: self.adapter!)
        let mapper = Mapper()
        
        let spec = Binding.mapping("", mapping)
        let company: Company = try! mapper.map(from: json, using: spec)
        let employees = company.employees
        
        XCTAssertEqual(employees.count, 2)
        XCTAssertEqual(original.uuid, company.uuid)
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 2)
    }
    
    func testAssigningNullToCollectionWhenNonNullableThrows() {
        class CompanyMappingAppendNonNullable: CompanyMapping {
            override func mapping(toMap: inout Company, context: MappingContext) {
                let employeeMapping = EmployeeMapping(adapter: self.adapter)
                map(toRLMArray: toMap.employees,
                    using: (.collectionMapping("employees", employeeMapping, (.append, true, false)), context))
            }
        }
        
        let uuid = NSUUID().uuidString
        let dupEmployeeStub = EmployeeStub()
        
        let original = Company()
        let originalEmployee = Employee()
        let dupEmployee = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        dupEmployee.uuid = dupEmployeeStub.uuid
        original.employees.append(originalEmployee)
        original.employees.append(dupEmployee)
        
        try! self.adapter!.save(objects: [ original ])
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 2)
        
        let companyStub = CompanyStub()
        companyStub.employees = []
        companyStub.uuid = original.uuid!
        var jsonObj = companyStub.generateJsonObject()
        XCTAssertEqual(jsonObj["employees"] as! NSArray, [])    // Sanity check.
        
        jsonObj["employees"] = NSNull()
        XCTAssertEqual(jsonObj["employees"] as! NSNull, NSNull())    // Sanity check.
        
        let json = try! JSONValue(object: jsonObj)
        
        let mapping = CompanyMappingAppendNonNullable(adapter: self.adapter!)
        let mapper = Mapper()
        
        let spec = Binding.mapping("", mapping)
        let testFunc = {
            let _: Company = try mapper.map(from: json, using: spec)
        }
        
        XCTAssertThrowsError(try testFunc())
        XCTAssertEqual(Company.allObjects(in: realm!).count, 1)
        XCTAssertEqual(Employee.allObjects(in: realm!).count, 2)
    }
}
