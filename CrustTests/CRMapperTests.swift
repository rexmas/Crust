import XCTest
@testable import Crust
import JSONValueRX

class MockMap: Mapping, Adapter {
    typealias BaseType = MockMap
    typealias ResultsType = [MockMap]
    
    init() { }
    
    var catchMapping: ((_ toMap: MockMap, _ payload: MappingPayload<String>) -> ())? = nil
    
    var adapter: MockMap {
        return self
    }
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return nil
    }
    
    func mapping(toMap: inout MockMap, payload: MappingPayload<String>) {
        catchMapping!(toMap, payload)
    }
    
    var dataBaseTag: String = "none"
    var isInTransaction: Bool = false
    func mappingWillBegin() throws { self.isInTransaction = true }
    func mappingDidEnd() throws { }
    func mappingErrored(_ error: Error) { }
    public func sanitize(primaryKeyProperty property: String, forValue value: CVarArg, ofType type: MockMap.Type) -> CVarArg? { return nil }
    func fetchObjects(type: BaseType.Type, primaryKeyValues: [[String : CVarArg]], isMapping: Bool) -> ResultsType? { return nil }
    func createObject(type: BaseType.Type) -> BaseType { return self }
    func deleteObject(_ obj: BaseType) throws { }
    func save(objects: [ BaseType ]) throws { }
}

class CRMapperTests: XCTestCase {

    func testMapFromJSONUsesParentContext() {
        let mockMap = MockMap()
        
        let json = try! JSONValue(object: [ "cool" : "json" ])
        let parent = MappingPayload<String>(withObject: mockMap, json: json, keys: AllKeys(), adapterType: "derp", direction: MappingDirection.fromJSON)
        let mapper = Mapper()
        
        var tested = false
        mockMap.catchMapping = { (toMap, payload) in
            tested = true
            let resultParent = payload.parent!
            XCTAssertEqual(resultParent.adapterType, parent.adapterType)
            XCTAssertTrue((resultParent.object as! MockMap) === (parent.object as! MockMap))
            XCTAssertEqual(resultParent.json, parent.json)
            XCTAssertEqual(resultParent.dir, parent.dir)
        }
        let _ = try! mapper.map(from: json, using: mockMap, keyedBy: AllKeys(), parentContext: parent)
        
        XCTAssertTrue(tested)
    }
}
