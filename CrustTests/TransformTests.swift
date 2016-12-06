import XCTest
import Crust
import JSONValueRX

struct Transformable: AnyMappable {
    var value: String = "awesome"
}

class TransformableMapping: Transform {
    
    typealias MappedObject = Transformable
    
    func fromJSON(_ json: JSONValue) throws -> MappedObject {
        switch json {
        case .number(let num):
            var transformable = Transformable()
            transformable.value = "\(num)"
            return transformable
        default:
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
    }
    
    func toJSON(_ obj: MappedObject) -> JSONValue {
        return .number(Double(obj.value.hash))
    }
}

extension Date: AnyMappable { }

extension DateFormatter {
    
    class func birthdateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}

class DateMapping: Transform {
    
    typealias MappedObject = Date
    
    let dateFormatter: DateFormatter
    
    init(dateFormatter: DateFormatter){
        self.dateFormatter = dateFormatter
    }
    
    func fromJSON(_ json: JSONValue) throws -> MappedObject {
        switch json {
        case .string(let date):
            return self.dateFormatter.date(from: date) ?? Date()
        default:
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
    }
    
    func toJSON(_ obj: MappedObject) -> JSONValue {
        return .string(self.dateFormatter.string(from: obj))
    }
}

class User {
    
    required init() { }
    
    var identifier: Int = 0
    var name: String? = nil
    var surname: String? = nil
    var birthDate: Date? = nil
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
    
    func mapping(_ toMap: inout User, context: MappingContext) {
        let userBirthdateMapping = DateMapping(dateFormatter: DateFormatter.birthdateFormatter())
        
        toMap.identifier        <- "data.id_hash" >*<
        toMap.birthDate         <- Spec.mapping("data.birthdate", userBirthdateMapping) >*<
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
        
        XCTAssertEqual(json, JSONValue.number(Double(object.value.hash)))
    }
    
    func testCustomTransformOverridesDefaultOne(){
        let jsonObject: [AnyHashable : Any] = ["data": ["id_hash": 170, "user_name": "Jorge", "user_surname": "Revuelta", "birthdate": "1991-03-31", "height": 175, "weight": 60, "sex": 2]]
        let json = try! JSONValue(object: jsonObject)
        let mapper = CRMapper<User, UserMapping>()
        let object = try! mapper.mapFromJSONToNewObject(json, mapping: UserMapping(adaptor: MockAdaptor<User>()))
        
        let targetDate: Date = DateFormatter.birthdateFormatter().date(from: "1991-03-31")!
        
        XCTAssertEqual(object.birthDate, targetDate)
    }
}

