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

extension NSDate: AnyMappable { }

extension NSDateFormatter {
    
    class func birthdateFormatter() -> NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return formatter
    }
}

class DateMapping: Transform {
    
    typealias MappedObject = NSDate
    
    let dateFormatter: NSDateFormatter
    
    init(dateFormatter: NSDateFormatter){
        self.dateFormatter = dateFormatter
    }
    
    func fromJSON(json: JSONValue) throws -> MappedObject {
        switch json {
        case .JSONString(let date):
            return self.dateFormatter.dateFromString(date) ?? NSDate()
        default:
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
    }
    
    func toJSON(obj: MappedObject) -> JSONValue {
        return .JSONString(self.dateFormatter.stringFromDate(obj))
    }
}

class User {
    
    required init() { }
    
    var identifier: Int = 0
    var name: String? = nil
    var surname: String? = nil
    var birthDate: NSDate? = nil
}

extension User: AnyMappable { }

class UserMapping: Mapping {
    
    var adaptor: MockAdaptor<User>
    var primaryKeys: Dictionary<String, CRMappingKey>? {
        return [ "identifier" : "data.id_hash" ]
    }
    
    required init(adaptor: MockAdaptor<User>) {
        self.adaptor = adaptor
    }
    
    func mapping(inout toMap: User, context: MappingContext) {
        let userBirthdateMapping = DateMapping(dateFormatter: NSDateFormatter.birthdateFormatter())
        
        toMap.identifier        <- "data.id_hash" >*<
        toMap.birthDate         <- KeyExtensions.Mapping("data.birthdate", userBirthdateMapping) >*<
        toMap.name              <- "data.user_name" >*<
        toMap.surname           <- "data.user_surname" >*<
        context
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
    
    func testCustomTransformOverridesDefaultOne(){
        let jsonObject: Dictionary<String, AnyObject> = ["data": ["id_hash": 170, "user_name": "Jorge", "user_surname": "Revuelta", "birthdate": "1991-03-31", "height": 175, "weight": 60, "sex": 2]]
        let json = try! JSONValue(object: jsonObject)
        let mapper = CRMapper<User, UserMapping>()
        let object = try! mapper.mapFromJSONToNewObject(json, mapping: UserMapping(adaptor: MockAdaptor<User>()))
        
        let targetDate: NSDate = NSDateFormatter.birthdateFormatter().dateFromString("1991-03-31")!
        
        XCTAssertEqual(object.birthDate, targetDate)
    }
}

