import XCTest
@testable import Crust
import JSONValueRX

class MockMap : Mapping, Adaptor {
    typealias BaseType = MockMap
    typealias ResultsType = Array<MockMap>
    
    init() { }
    
    var catchMapping: ((tomap: MockMap, context: MappingContext) -> ())? = nil
    
    var adaptor: MockMap {
        return self
    }
    var primaryKeys: Dictionary<String, CRMappingKey>? {
        return nil
    }
    
    func mapping(inout tomap: MockMap, context: MappingContext) {
        catchMapping!(tomap: tomap, context: context)
    }
    
    func mappingBegins() throws { }
    func mappingEnded() throws { }
    func mappingErrored(error: ErrorType) { }
    
    func fetchObjectsWithType(type: BaseType.Type, keyValues: Dictionary<String, CVarArgType>) -> ResultsType? { return nil }
    func createObject(objType: BaseType.Type) -> BaseType { return self }
    func deleteObject(obj: BaseType) throws { }
    func saveObjects(objects: [ BaseType ]) throws { }
}

class CRMapperTests: XCTestCase {

    func testMapFromJSONUsesParentContext() {
        let mockMap = MockMap()
        
        let json = try! JSONValue(object: [:])
        let parent = MappingContext(withObject: mockMap, json: json, direction: Crust.MappingDirection.FromJSON)
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
