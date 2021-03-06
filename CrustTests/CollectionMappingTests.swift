import XCTest
@testable import Crust
import JSONValueRX

// We test the following.
// | append / replace  | nullable  | vals / null | Array     | Array?      | RLMArray  |
// |-------------------|-----------|-------------|-----------|-------------|-----------|
// | append            | yes or no | vals        | append    | append      | append    |
// | append            | yes       | null        | no-op     | no-op       | no-op     |
// | replace           | yes or no | vals        | replace   | replace     | replace   |
// | replace           | yes       | null        | removeAll | assign null | removeAll |
// | append or replace | no        | null        | error     | error       | error     |

extension Int: AnyMappable { }

class CollectionMappingTests: XCTestCase {
    
    class IntMapping: AnyMapping {
        func mapping(toMap: inout Int, payload: MappingPayload<String>) { }
    }
    
    func testDefaultInsertionPolicyIsReplaceUniqueNullable() {
        let binding = Binding.mapping("", IntMapping())
        let policy = binding.collectionUpdatePolicy
        guard case (.replace(delete: nil), true, true) = policy else {
            XCTFail()
            return
        }
    }
    
    func testMappingCollection() {
        let employeeStub = EmployeeStub()
        let employeeStub2 = EmployeeStub()
        let json = try! JSONValue(object: employeeStub.generateJsonObject())
        let json2 = try! JSONValue(object: employeeStub2.generateJsonObject())
        let employeesJSON = JSONValue.array([json, json2])
        
        let mapping = EmployeeMapping(adapter: MockAdapter<Employee>())
        let mapper = Mapper()
        
        let spec = Binding.mapping("", mapping)
        let collection: [Employee] = try! mapper.map(from: employeesJSON, using: spec, keyedBy: AllKeys())
        
        XCTAssertEqual(collection.count, 2)
        XCTAssertNotEqual(collection[0].uuid, collection[1].uuid)
        XCTAssertTrue(employeeStub.matches(collection[0]))
        XCTAssertTrue(employeeStub2.matches(collection[1]))
    }
    
    // | append / replace  | nullable  | vals / null | Array     |
    // |-------------------|-----------|-------------|-----------|
    // | append            | yes or no | append      | append    |
    func testMappingCollectionByAppend() {
        class CompanyMappingAppendUnique: CompanyMapping {
            override func mapping(toMap: inout Company, payload: MappingPayload<CompanyCodingKey>) {
                let employeeMapping = EmployeeMapping(adapter: MockAdapter<Employee>())
                toMap.employees <- (Binding.collectionMapping(.employees([]), employeeMapping, (.append, true, false)), payload)
            }
        }
        
        let uuid = NSUUID().uuidString
        
        let original = Company()
        let employee1 = Employee()   // 1.
        let employee2 = Employee()        // 2.
        original.uuid = uuid
        employee1.uuid = uuid
        employee2.uuid = NSUUID().uuidString
        original.employees.append(employee1)
        original.employees.append(employee2)
        
        let companyStub = CompanyStub()
        let employeeStub3 = EmployeeStub()   // 3.
        let employeeStub4 = EmployeeStub()  // 4.
        companyStub.uuid = uuid
        companyStub.employees = [employeeStub3, employeeStub4]
        let json = try! JSONValue(object: companyStub.generateJsonObject())
        
        let mapping = CompanyMappingAppendUnique(adapter: MockAdapter<Company>())
        let mapper = Mapper()
        
        let company: Company = try! mapper.map(from: json, to: original, using: mapping, keyedBy: AllKeys())
        let employees = company.employees
        
        XCTAssertEqual(original.uuid, company.uuid)
        XCTAssertEqual(employees.count, 4)
        XCTAssertEqual(employees[0].uuid, employee1.uuid)
        XCTAssertTrue(employeeStub3.matches(employees[2]))
        XCTAssertTrue(employeeStub4.matches(employees[3]))
    }
    
    // | append / replace  | nullable  | vals / null | Array     |
    // |-------------------|-----------|-------------|-----------|
    // | replace           | yes or no | vals        | replace   |
    func testMappingCollectionByReplace() {
        class CompanyMappingReplaceUnique: CompanyMapping {
            override func mapping(toMap: inout Company, payload: MappingPayload<CompanyCodingKey>) {
                let employeeMapping = EmployeeMapping(adapter: MockAdapter<Employee>())
                toMap.employees <- (.collectionMapping(.employees([]), employeeMapping, (.replace(delete: nil), true, false)), payload)
            }
        }
        
        let uuid = NSUUID().uuidString
        
        let original = Company()
        let originalEmployee = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        original.employees.append(originalEmployee)
        
        let companyStub = CompanyStub()
        let employeeStub = EmployeeStub()
        let employeeStub2 = EmployeeStub()
        companyStub.uuid = original.uuid
        companyStub.employees = [employeeStub, employeeStub2]
        let json = try! JSONValue(object: companyStub.generateJsonObject())
        
        let mapping = CompanyMappingReplaceUnique(adapter: MockAdapter<Company>())
        let mapper = Mapper()
        
        let company: Company = try! mapper.map(from: json, to: original, using: mapping, keyedBy: AllKeys())
        let employees = company.employees
        
        XCTAssertEqual(original.uuid, company.uuid)
        XCTAssertEqual(employees.count, 2)
        XCTAssertTrue(employeeStub.matches(employees[0]))
        XCTAssertTrue(employeeStub2.matches(employees[1]))
    }
    
    // | append / replace  | nullable  | vals / null | Array     |
    // |-------------------|-----------|-------------|-----------|
    // | replace           | yes or no | vals        | replace   |
    func testMappingCollectionByReplaceDelete() {
        class CompanyMappingReplaceDeleteUnique: CompanyMapping {
            let employeeAdapter = MockAdapter<Employee>()
            override func mapping(toMap: inout Company, payload: MappingPayload<CompanyCodingKey>) {
                let employeeMapping = EmployeeMapping(adapter: employeeAdapter)
                toMap.employees <- (.collectionMapping(.employees([]), employeeMapping, (.replace(delete: { $0 }), true, false)), payload)
            }
        }
        
        let uuid = NSUUID().uuidString
        let originalEmployee2Stub = EmployeeStub()
        
        let original = Company()
        let originalEmployee = Employee()
        let originalEmployee2 = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        originalEmployee2.uuid = originalEmployee2Stub.uuid
        original.employees.append(originalEmployee)
        original.employees.append(originalEmployee2)
        
        let companyStub = CompanyStub()
        let employeeStub = EmployeeStub()
        let employeeStub2 = EmployeeStub()
        companyStub.employees = [employeeStub, employeeStub2, employeeStub, originalEmployee2Stub]
        companyStub.uuid = original.uuid
        let json = try! JSONValue(object: companyStub.generateJsonObject())
        
        let mapping = CompanyMappingReplaceDeleteUnique(adapter: MockAdapter<Company>())
        let mapper = Mapper()
        
        let company: Company = try! mapper.map(from: json, to: original, using: mapping, keyedBy: AllKeys())
        let employees = company.employees
        
        XCTAssertEqual(original.uuid, company.uuid)
        XCTAssertEqual(mapping.employeeAdapter.deletedObjects.map { $0.uuid }, [originalEmployee.uuid, originalEmployee2.uuid])
        XCTAssertEqual(employees.count, 4)
        XCTAssertTrue(employeeStub.matches(employees[0]))
        XCTAssertTrue(employeeStub2.matches(employees[1]))
        XCTAssertTrue(employeeStub.matches(employees[2]))
        XCTAssertTrue(originalEmployee2Stub.matches(employees[3]))
    }
    
    // | append / replace  | nullable  | vals / null | Array     |
    // |-------------------|-----------|-------------|-----------|
    // | replace           | yes       | null        | removeAll |
    func testAssigningNullToCollectionWhenReplaceNullableRemovesAllAndDeletes() {
        class CompanyMappingReplaceNullable: CompanyMapping {
            let employeeAdapter = MockAdapter<Employee>()
            override func mapping(toMap: inout Company, payload: MappingPayload<CompanyCodingKey>) {
                let employeeMapping = EmployeeMapping(adapter: employeeAdapter)
                toMap.employees <- (.collectionMapping(.employees([]), employeeMapping, (.replace(delete: { $0 }), true, true)), payload)
            }
        }
        
        let uuid = NSUUID().uuidString
        let originalEmployee2Stub = EmployeeStub()
        
        let original = Company()
        let originalEmployee = Employee()
        let originalEmployee2 = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        originalEmployee2.uuid = originalEmployee2Stub.uuid
        original.employees.append(originalEmployee)
        original.employees.append(originalEmployee2)
        
        let companyStub = CompanyStub()
        companyStub.employees = []
        companyStub.uuid = original.uuid
        var jsonObj = companyStub.generateJsonObject()
        XCTAssertEqual(jsonObj["employees"] as! NSArray, [])    // Sanity check.
        
        jsonObj["employees"] = NSNull()
        XCTAssertEqual(jsonObj["employees"] as! NSNull, NSNull())    // Sanity check.
        
        let json = try! JSONValue(object: jsonObj)
        
        let mapping = CompanyMappingReplaceNullable(adapter: MockAdapter<Company>())
        let mapper = Mapper()
        
        let company: Company = try! mapper.map(from: json, to: original, using: mapping, keyedBy: AllKeys())
        let employees = company.employees
        
        XCTAssertEqual(mapping.employeeAdapter.deletedObjects.map { $0.uuid }, [originalEmployee.uuid, originalEmployee2.uuid])
        XCTAssertEqual(original.uuid, company.uuid)
        XCTAssertEqual(employees.count, 0)
    }
    
    // | append / replace  | nullable  | vals / null | Array     |
    // |-------------------|-----------|-------------|-----------|
    // | append            | yes       | null        | no-op     |
    func testAssigningNullToCollectionWhenAppendNullableDoesNothing() {
        class CompanyMappingAppendNullable: CompanyMapping {
            override func mapping(toMap: inout Company, payload: MappingPayload<CompanyCodingKey>) {
                let employeeMapping = EmployeeMapping(adapter: MockAdapter<Employee>())
                toMap.employees <- (.collectionMapping(.employees([]), employeeMapping, (.append, true, true)), payload)
            }
        }
        
        let uuid = NSUUID().uuidString
        let originalEmployee2Stub = EmployeeStub()
        
        let original = Company()
        let originalEmployee = Employee()
        let originalEmployee2 = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        originalEmployee2.uuid = originalEmployee2Stub.uuid
        original.employees.append(originalEmployee)
        original.employees.append(originalEmployee2)
        
        let companyStub = CompanyStub()
        companyStub.employees = []
        companyStub.uuid = original.uuid
        var jsonObj = companyStub.generateJsonObject()
        XCTAssertEqual(jsonObj["employees"] as! NSArray, [])    // Sanity check.
        
        jsonObj["employees"] = NSNull()
        XCTAssertEqual(jsonObj["employees"] as! NSNull, NSNull())    // Sanity check.
        
        let json = try! JSONValue(object: jsonObj)
        
        let mapping = CompanyMappingAppendNullable(adapter: MockAdapter<Company>())
        let mapper = Mapper()
        
        let company: Company = try! mapper.map(from: json, to: original, using: mapping, keyedBy: AllKeys())
        let employees = company.employees
        
        XCTAssertEqual(employees.count, 2)
        XCTAssertEqual(original.uuid, company.uuid)
    }
    
    // | append / replace  | nullable  | vals / null | Array     |
    // |-------------------|-----------|-------------|-----------|
    // | append or replace | no        | null        | error     |
    func testAssigningNullToCollectionWhenNonNullableThrows() {
        class CompanyMappingAppendNonNullable: CompanyMapping {
            override func mapping(toMap: inout Company, payload: MappingPayload<CompanyCodingKey>) {
                let employeeMapping = EmployeeMapping(adapter: MockAdapter<Employee>())
                toMap.employees <- (.collectionMapping(.employees([]), employeeMapping, (.append, true, false)), payload)
            }
        }
        
        let uuid = NSUUID().uuidString
        let originalEmployee2Stub = EmployeeStub()
        
        let original = Company()
        let originalEmployee = Employee()
        let originalEmployee2 = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        originalEmployee2.uuid = originalEmployee2Stub.uuid
        original.employees.append(originalEmployee)
        original.employees.append(originalEmployee2)
        
        let companyStub = CompanyStub()
        companyStub.employees = []
        companyStub.uuid = original.uuid
        var jsonObj = companyStub.generateJsonObject()
        XCTAssertEqual(jsonObj["employees"] as! NSArray, [])    // Sanity check.
        
        jsonObj["employees"] = NSNull()
        XCTAssertEqual(jsonObj["employees"] as! NSNull, NSNull())    // Sanity check.
        
        let json = try! JSONValue(object: jsonObj)
        
        let mapping = CompanyMappingAppendNonNullable(adapter: MockAdapter<Company>())
        let mapper = Mapper()
        
        let spec = Binding.mapping("", mapping)
        let testFunc = {
            let _: Company = try mapper.map(from: json, using: spec, keyedBy: AllKeys())
        }
        
        XCTAssertThrowsError(try testFunc())
    }
    
    // MARK: - Optional Array.
    
    // | append / replace  | nullable  | vals / null | Array?      |
    // |-------------------|-----------|-------------|-------------|
    // | replace           | yes       | null        | assign null |
    func testAssigningNullToOptionalCollectionWhenReplaceNullableAssignsNullAndDeletes() {
        class CompanyMappingReplaceNullable: CompanyWithOptionalEmployeesMapping {
            let employeeAdapter = MockAdapter<Employee>()
            override func mapping(toMap: inout CompanyWithOptionalEmployees, payload: MappingPayload<CompanyCodingKey>) {
                let employeeMapping = EmployeeMapping(adapter: employeeAdapter)
                toMap.employees <- (.collectionMapping(.employees([]), employeeMapping, (.replace(delete: { $0 }), true, true)), payload)
            }
        }
        
        let uuid = NSUUID().uuidString
        let originalEmployee2Stub = EmployeeStub()
        
        let original = CompanyWithOptionalEmployees()
        original.employees = []
        let originalEmployee = Employee()
        let originalEmployee2 = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        originalEmployee2.uuid = originalEmployee2Stub.uuid
        original.employees?.append(originalEmployee)
        original.employees?.append(originalEmployee2)
        
        let companyStub = CompanyStub()
        companyStub.employees = []
        companyStub.uuid = original.uuid
        var jsonObj = companyStub.generateJsonObject()
        XCTAssertEqual(jsonObj["employees"] as! NSArray, [])    // Sanity check.
        
        jsonObj["employees"] = NSNull()
        XCTAssertEqual(jsonObj["employees"] as! NSNull, NSNull())    // Sanity check.
        
        let json = try! JSONValue(object: jsonObj)
        
        let mapping = CompanyMappingReplaceNullable(adapter: MockAdapter<CompanyWithOptionalEmployees>())
        let mapper = Mapper()
        
        let company: CompanyWithOptionalEmployees = try! mapper.map(from: json, to: original, using: mapping, keyedBy: AllKeys())
        let employees = company.employees
        
        XCTAssertEqual(mapping.employeeAdapter.deletedObjects.map { $0.uuid }, [originalEmployee.uuid, originalEmployee2.uuid])
        XCTAssertEqual(original.uuid, company.uuid)
        XCTAssertNil(employees)
    }
    
    // | append / replace  | nullable  | vals / null | Array?      |
    // |-------------------|-----------|-------------|-------------|
    // | append or replace | no        | null        | error       |
    func testAssigningNullToOptionalCollectionWhenNonNullableThrows() {
        class CompanyMappingAppendNonNullable: CompanyWithOptionalEmployeesMapping {
            override func mapping(toMap: inout CompanyWithOptionalEmployees, payload: MappingPayload<CompanyCodingKey>) {
                let employeeMapping = EmployeeMapping(adapter: MockAdapter<Employee>())
                toMap.employees <- (.collectionMapping(.employees([]), employeeMapping, (.append, true, false)), payload)
            }
        }
        
        let uuid = NSUUID().uuidString
        let originalEmployee2Stub = EmployeeStub()
        
        let original = CompanyWithOptionalEmployees()
        let originalEmployee = Employee()
        let originalEmployee2 = Employee()
        original.uuid = uuid
        originalEmployee.uuid = uuid
        originalEmployee2.uuid = originalEmployee2Stub.uuid
        original.employees = []
        original.employees?.append(originalEmployee)
        original.employees?.append(originalEmployee2)
        
        let companyStub = CompanyStub()
        companyStub.employees = []
        companyStub.uuid = original.uuid
        var jsonObj = companyStub.generateJsonObject()
        XCTAssertEqual(jsonObj["employees"] as! NSArray, [])    // Sanity check.
        
        jsonObj["employees"] = NSNull()
        XCTAssertEqual(jsonObj["employees"] as! NSNull, NSNull())    // Sanity check.
        
        let json = try! JSONValue(object: jsonObj)
        
        let mapping = CompanyMappingAppendNonNullable(adapter: MockAdapter<CompanyWithOptionalEmployees>())
        let mapper = Mapper()
        
        let spec = Binding.mapping("", mapping)
        let testFunc = {
            let _: CompanyWithOptionalEmployees = try mapper.map(from: json, using: spec, keyedBy: AllKeys())
        }
        
        XCTAssertThrowsError(try testFunc())
        XCTAssertEqual(original.employees!.map { $0.uuid }, [originalEmployee.uuid, originalEmployee2.uuid])
    }
    
    struct EquatableThing: AnyMappable, Equatable {
        var uuid: String = NSUUID().uuidString
        
        static func ==(lhs: EquatableThing, rhs: EquatableThing) -> Bool {
            return lhs.uuid == rhs.uuid
        }
    }
    
    func testMappingEquatableCollectionByReplaceDeleteUnique() {
        class EquatableThingMapping: Mapping {
            var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
                return [ ("uuid", "uuid", nil) ]
            }
            
            let adapter = MockAdapter<EquatableThing>()
            
            func mapping(toMap: inout EquatableThing, payload: MappingPayload<String>) {
                toMap.uuid <- ("uuid", payload)
            }
        }
        
        enum EquatableKeys: String, MappingKey {
            case equatables
            
            func nestedMappingKeys<Key: MappingKey>() -> AnyKeyCollection<Key>? {
                return ["uuid"].anyKeyCollection()
            }
        }
        
        let orphanedEquatable1 = EquatableThing()
        let orphanedEquatable2 = EquatableThing()
        let orphanedEquatable3 = EquatableThing()
        let remainingEquatable1 = EquatableThing()
        let remainingEquatable2 = EquatableThing()
        let newUUID = NSUUID().uuidString
        var equatableThings = [orphanedEquatable1, orphanedEquatable2, orphanedEquatable3, remainingEquatable1, remainingEquatable2]
        
        let json = try! JSONValue(object: ["equatables" : [
            ["uuid" : remainingEquatable1.uuid],
            ["uuid" : remainingEquatable2.uuid],
            ["uuid" : newUUID]
        ]])
        let binding = Binding.collectionMapping(EquatableKeys.equatables, EquatableThingMapping(), (.replace(delete: { $0 }), true, false))
        let payload = MappingPayload(withObject: equatableThings, json: json, keys: [EquatableKeys.equatables], adapterType: "derp", direction: .fromJSON)
        equatableThings <- (binding, payload)
        
        XCTAssertEqual(equatableThings.map { $0.uuid }, [remainingEquatable1.uuid, remainingEquatable2.uuid, newUUID])
    }
    
    // MARK: Array of Optional enums
    
    func testMappingArrayOfOptionalEnums() {
        enum Color: RawRepresentable, Hashable, AnyMappable {
            public typealias RawValue = String
            
            case red
            case blue
            case green
            case __unknown(RawValue)
            
            public init() {
                self = .__unknown("")
            }
            
            public init?(rawValue: String) {
                switch rawValue {
                case "red":
                    self = .red
                case "blue":
                    self = .blue
                case "green":
                    self = .green
                default:
                    self = .__unknown(rawValue)
                }
            }
            
            public var rawValue: String {
                switch self {
                case .red:
                    return "red"
                case .blue:
                    return "blue"
                case .green:
                    return "green"
                case .__unknown(let val):
                    return val
                }
            }
            
            public func graphQLInputValue() throws -> String {
                return self.rawValue
            }
            
            public struct Mapping: StringRawValueTransform {
                public typealias MappedObject = Color
            }
        }
        
        struct OuterObject: AnyMappable, Equatable {
            init() {}
            var enums: [Color?] = []
            
            public enum Key: RawRepresentable, MappingKey {
                case enums
                
                public var keyPath: String {
                    return self.rawValue
                }
                
                public init?(rawValue: String) {
                    switch rawValue {
                    case "enums": self = .enums
                    default: return nil
                    }
                }
                
                public var rawValue: String {
                    switch self {
                    case .enums: return "enums"
                    }
                }
                
                public func nestedMappingKeys<Key: MappingKey>() -> AnyKeyCollection<Key>? {
                    switch self {
                    default: return nil
                    }
                }
            }
            
            class Mapping: AnyMapping {
                typealias AdapterKind = AnyAdapterImp<OuterObject>
                typealias MappedObject = OuterObject
                
                required init() { }
                
                func mapping(toMap: inout OuterObject, payload: MappingPayload<Key>) {
                    toMap.enums <- (.mapping(.enums, OptionalAnyMapping(wrappedMapping: Color.Mapping())), payload)
                }
            }
        }
        
        let jsonObj = [ "enums" : [ "red", "blue", "green" ]]
        let json = try! JSONValue(object: jsonObj)
        
        let mapper = Mapper()
        
        let outer: OuterObject = try! mapper.map(from: json, using: OuterObject.Mapping(), keyedBy: [ .enums ])
        var expected = OuterObject()
        expected.enums = [ .red, .blue, .green ]
        
        XCTAssertEqual(outer, expected)
    }
}
