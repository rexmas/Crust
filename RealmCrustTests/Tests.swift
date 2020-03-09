import XCTest
import Crust
import JSONValueRX
import Realm

public class User: RLMObject {
    @objc public dynamic var identifier: String = ""
    @objc public dynamic var name: String? = nil
    @objc public dynamic var surname: String? = nil
    @objc public dynamic var height: Int = 170
    @objc public dynamic var weight: Int = 70
    @objc public dynamic var birthDate: NSDate? = nil
    @objc public dynamic var sex: Int = 2
    @objc public dynamic var photoPath: String? = nil
    
//    override public static func primaryKey() -> String? {
//        return "identifier"
//    }
    
}

public class UserMapping: RealmMapping {
    public var adapter: RealmAdapter
    public var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [("identifier", "id_hash", nil)]
    }
    
    public required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    public func mapping(toMap: inout User, payload: MappingPayload<String>) {
        let birthdateMapping = DateMapping(dateFormatter: DateFormatter.isoFormatter)
        let primaryKeyMapping = PrimaryKeyMapping()
        
        toMap.birthDate     <- (.mapping("birthdate", birthdateMapping), payload)
        toMap.identifier    <- (.mapping("id_hash", primaryKeyMapping), payload)
        toMap.name          <- ("user_name", payload)
        toMap.surname       <- ("user_surname", payload)
        toMap.height        <- ("height", payload)
        toMap.weight        <- ("weight", payload)
        toMap.sex           <- ("sex", payload)
        toMap.photoPath     <- ("photo_path", payload)
    }
}

extension NSDate: AnyMappable { }

public class DateMapping: Transform {
    
    public typealias MappedObject = NSDate
    
    let dateFormatter: DateFormatter
    
    init(dateFormatter: DateFormatter){
        self.dateFormatter = dateFormatter
    }
    
    public func fromJSON(_ json: JSONValue) throws -> MappedObject {
        
        switch json {
        case .string(let date):
            return (self.dateFormatter.date(from: date) as NSDate?) ?? NSDate()
        default:
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
    }
    
    public func toJSON(_ obj: MappedObject) -> JSONValue {
        return .string(self.dateFormatter.string(from: obj as Date))
    }
}


extension String: AnyMappable { }

public class PrimaryKeyMapping: Transform {
    
    public typealias MappedObject = String
    
    public func fromJSON(_ json: JSONValue) throws -> MappedObject {
        switch json{
        case .string(let string):
            return string
        default:
            throw NSError(domain: "", code: -1, userInfo: nil)
        }
    }
    
    public func toJSON(_ obj: MappedObject) -> JSONValue {
        return JSONValue.number(.int(Int64(obj)!))
    }
}


class Tests: RealmMappingTest {
    
    func testShouldDecodeJSONUserObjects() {
        
        // NOTE: Also testing coercing strings to numbers.
        // TODO: We don't coerce numbers to strings, possibly something to look into.
        
        let json: [String : Any] = ["data": ["id_hash": "170", "user_name": "Jorge", "user_surname": "Revuelta", "birthdate": "1991-03-31", "height": 175, "weight": "60", "sex": 2, "photo_path": "http://somwhere-over-the-internet.com/"]]
        
        
        let mapping = Mapper()
        let jsonValue = try! JSONValue(object: json)
        _ = try! mapping.map(from: jsonValue["data"]!, using: UserMapping(adapter: adapter!), keyedBy: AllKeys())
        
        XCTAssertEqual(User.allObjects(in: realm!).count, 1)
    }
    
    func testShouldEncodeJSONUserObjects() {
    
        let jsonObj: [String : Any] = ["data": ["id_hash": "170", "user_name": "Jorge", "user_surname": "Revuelta", "birthdate": "1991-03-31", "height": 175, "weight": "60", "sex": 2, "photo_path": "http://somwhere-over-the-internet.com/"]]
        
        
        let mapping = Mapper()
        let jsonValue = try! JSONValue(object: jsonObj)
        _ = try! mapping.map(from: jsonValue["data"]!, using: UserMapping(adapter: adapter!), keyedBy: AllKeys())
        
        let user = User.allObjects(in: realm!).firstObject()!
        let json = try! mapping.mapFromObjectToJSON(user as! User, mapping: UserMapping(adapter: adapter!), keyedBy: AllKeys())
        
        //let id_hash = json["id_hash"]?.values() as! Int
        XCTAssertNotNil(json)
        //XCTAssertEqual(id_hash, 170)
    }
}
