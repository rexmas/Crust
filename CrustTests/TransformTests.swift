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
        return .number(.fraction(Double(obj.value.hash)))
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

enum UserCodingKey: String, RawMappingKey {
    case identifier = "data.id_hash"
    case birthDate = "data.birthdate"
    case name = "data.user_name"
    case surname = "data.user_surname"
    
    var keyPath: String {
        return self.rawValue
    }
}

class UserMapping: Mapping {
    
    var adapter: MockAdapter<User>
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("identifier", "data.id_hash", nil) ]
    }
    
    required init(adapter: MockAdapter<User>) {
        self.adapter = adapter
    }
    
    func mapping(toMap: inout User, payload: MappingPayload<UserCodingKey>) {
        let userBirthdateMapping = DateMapping(dateFormatter: DateFormatter.birthdateFormatter())
        
        toMap.identifier        <- (.identifier, payload)
        toMap.birthDate         <- (Binding.mapping(.birthDate, userBirthdateMapping), payload)
        toMap.name              <- (.name, payload)
        toMap.surname           <- (.surname, payload)
    }
}


class TransformTests: XCTestCase {
    
    func testMappingFromJSON() {
        let json = try! JSONValue(object: 1)
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: TransformableMapping(), keyedBy: Set([RootKey()]))
        
        XCTAssertEqual(object.value, "1")
    }
    
    func testMappingToJSON() {
        var object = Transformable()
        object.value = "derp"
        let mapper = Mapper()
        let json = try! mapper.mapFromObjectToJSON(object, mapping: TransformableMapping(), keyedBy: Set([RootKey()]))
        
        XCTAssertEqual(json, JSONValue.number(.fraction(Double(object.value.hash))))
    }
    
    func testCustomTransformOverridesDefaultOne(){
        let jsonObject: [AnyHashable : Any] = ["data": ["id_hash": 170, "user_name": "Jorge", "user_surname": "Revuelta", "birthdate": "1991-03-31", "height": 175, "weight": 60, "sex": 2]]
        let json = try! JSONValue(object: jsonObject)
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: UserMapping(adapter: MockAdapter<User>()), keyedBy: AllKeys())
        
        let targetDate: Date = DateFormatter.birthdateFormatter().date(from: "1991-03-31")!
        
        XCTAssertEqual(object.birthDate, targetDate)
        XCTAssertEqual(object.identifier, 170)
    }
}

