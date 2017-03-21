import XCTest
@testable import Crust
import JSONValueRX

class MockMap: Mapping, Adapter {
    typealias BaseType = MockMap
    typealias ResultsType = [MockMap]
    
    init() { }
    
    var catchMapping: ((_ toMap: MockMap, _ context: MappingContext) -> ())? = nil
    
    var adapter: MockMap {
        return self
    }
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return nil
    }
    
    func mapping(toMap: inout MockMap, context: MappingContext) {
        catchMapping!(toMap, context)
    }
    
    func mappingBegins() throws { }
    func mappingEnded() throws { }
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
        
        let json = try! JSONValue(object: [:])
        let parent = MappingContext(withObject: mockMap, json: json, direction: MappingDirection.fromJSON)
        let mapper = Mapper()
        
        var tested = false
        mockMap.catchMapping = { (toMap, context) in
            tested = true
            XCTAssertTrue(context.parent! === parent)
        }
        let _ = try! mapper.map(from: json, using: mockMap, parentContext: parent)
        
        XCTAssertTrue(tested)
    }
}
