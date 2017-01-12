import XCTest
@testable import Crust
import JSONValueRX

class MockMap: Mapping, Adaptor {
    typealias BaseType = MockMap
    typealias ResultsType = [MockMap]
    
    init() { }
    
    var catchMapping: ((_ tomap: MockMap, _ context: MappingContext) -> ())? = nil
    
    var adaptor: MockMap {
        return self
    }
    var primaryKeys: [String : Keypath]? {
        return nil
    }
    
    func mapping(tomap: inout MockMap, context: MappingContext) {
        catchMapping!(tomap, context)
    }
    
    func mappingBegins() throws { }
    func mappingEnded() throws { }
    func mappingErrored(_ error: Error) { }
    
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
        let mapper = Crust<MockMap>()
        
        var tested = false
        mockMap.catchMapping = { (tomap, context) in
            tested = true
            XCTAssertTrue(context.parent! === parent)
        }
        let _ = try! mapper.mapFromJSONToExistingObject(json, mapping: mockMap, parentContext: parent)
        
        XCTAssertTrue(tested)
    }
}
