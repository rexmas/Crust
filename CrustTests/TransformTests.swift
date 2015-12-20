import XCTest
import Crust
import JSONValueRX

struct Transformable : AnyMappable {
    var value: String = "awesome"
}

class TransformableMapping : Transform {
    
    typealias MappedObject = Transformable
    
    func fromJSON(json: JSONValue) throws -> MappedObject {
        switch json {
        case .JSONNumber(let num):
            var transformable = Transformable()
            transformable.value = "\(num)"
            return transformable
        default:
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
    }
    
    func toJSON(obj: MappedObject) -> JSONValue {
        return .JSONNumber(Double(obj.value.hash))
    }
}

class TransformTests: XCTestCase {
    
    func testMappingFromJSON() {
        
        let json = try! JSONValue(object: 1)
        let mapper = CRMapper<Transformable, TransformableMapping>()
        let object = try! mapper.mapFromJSONToNewObject(json, mapping: TransformableMapping())
        
        XCTAssertEqual(object.value, "1.0")
    }
    
    func testMappingToJSON() {
        var object = Transformable()
        object.value = "derp"
        let mapper = CRMapper<Transformable, TransformableMapping>()
        let json = try! mapper.mapFromObjectToJSON(object, mapping: TransformableMapping())
        
        XCTAssertEqual(json, JSONValue.JSONNumber(Double(object.value.hash)))
    }
}

