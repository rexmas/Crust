import XCTest
@testable import Crust
import JSONValueRX

class MockMap: Mapping, Adaptor {
    typealias BaseType = MockMap
    typealias ResultsType = Array<MockMap>
    
    init() { }
    
    var catchMapping: ((_ tomap: MockMap, _ context: MappingContext) -> ())? = nil
    
    var adaptor: MockMap {
        return self
    }
    var primaryKeys: Dictionary<String, CRMappingKey>? {
        return nil
    }
    
    func mapping(_ tomap: inout MockMap, context: MappingContext) {
        catchMapping!(tomap, context)
    }
    
    func mappingBegins() throws { }
    func mappingEnded() throws { }
    func mappingErrored(_ error: Error) { }
    
    func fetchObjectsWithType(_ type: BaseType.Type, keyValues: Dictionary<String, CVarArg>) -> ResultsType? { return nil }
    func createObject(_ objType: BaseType.Type) -> BaseType { return self }
    func deleteObject(_ obj: BaseType) throws { }
    func saveObjects(_ objects: [ BaseType ]) throws { }
}

class CRMapperTests: XCTestCase {

    func testMapFromJSONUsesParentContext() {
        let mockMap = MockMap()
        
        let json = try! JSONValue(object: [:])
        let parent = MappingContext(withObject: mockMap, json: json, direction: Crust.MappingDirection.fromJSON)
        let mapper = CRMapper<MockMap, MockMap>()
        
        var tested = false
        mockMap.catchMapping = { (tomap, context) in
            tested = true
            XCTAssertTrue(context.parent! === parent)
        }
        let _ = try! mapper.mapFromJSONToExistingObject(json, mapping: mockMap, parentContext: parent)
        
        XCTAssertTrue(tested)
    }
}
