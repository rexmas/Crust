import XCTest
import Crust
import JSONValueRX
import Realm

class RootedKeyTests: RealmMappingTest {
    
    func testJsonToInterface() {
        
        XCTAssertEqual(GQLInterfaceObj.allObjects(in: realm!).count, 0)
        let stub = GQLInterfaceObjStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: GQLInterfaceObjMapping(adapter: adapter!), keyedBy: AllKeys())
        
        try! self.adapter!.save(objects: [ object ])

        XCTAssertEqual(GQLInterfaceObj.allObjects(in: realm!).count, 1)
        XCTAssertTrue(stub.matches(object: object))
    }
}

class GQLInterfaceObjStub {
    
    var uuid: String = NSUUID().uuidString
    var prop: String = NSUUID().uuidString
    
    init() { }
    
    func generateJsonObject() -> [String : Any] {
        return [
            "uuid" : uuid,
            "prop" : prop
        ]
    }
    
    func matches(object: GQLInterfaceObj) -> Bool {
        var matches = true
        matches &&= uuid == object.uuid
        matches &&= uuid == object.concreteObj?.uuid
        matches &&= prop == object.concreteObj?.prop
        return matches
    }
}

public enum GQLInterfaceObjKey: MappingKey {
    case uuid
    case concreteObj([GQLConcreteObjKey])
    
    public var keyPath: String {
        switch self {
        case .uuid:                 return "uuid"
        case .concreteObj(_):       return ""
        }
    }
    
    public func nestedMappingKeys<Key: MappingKey>() -> AnyKeyCollection<Key>? {
        switch self {
        case .concreteObj(let objKeys):
            return objKeys.anyKeyCollection()
        default:
            return nil
        }
    }
}

public class GQLInterfaceObjMapping : RealmMapping {
    
    public var adapter: RealmAdapter
    public var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "uuid", nil) ]
    }
    
    public required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    public func mapping(toMap: inout GQLInterfaceObj, payload: MappingPayload<GQLInterfaceObjKey>) {
        let concreteObjMapping = GQLConcreteObjMapping(adapter: self.adapter)
        toMap.concreteObj <- (.mapping(RootedKey(GQLInterfaceObjKey.concreteObj([])), concreteObjMapping), payload)
    }
}

public enum GQLConcreteObjKey: MappingKey {
    case uuid
    case prop
    
    public var keyPath: String {
        switch self {
        case .uuid: return "uuid"
        case .prop: return "prop"
        }
    }
    
    public func nestedMappingKeys<Key: MappingKey>() -> AnyKeyCollection<Key>? {
        switch self {
        default:
            return nil
        }
    }
}

public class GQLConcreteObjMapping : RealmMapping {
    
    public var adapter: RealmAdapter
    public var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "uuid", nil) ]
    }
    
    public required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    public func mapping(toMap: inout GQLConcreteObj, payload: MappingPayload<GQLConcreteObjKey>) {
        toMap.prop <- (.prop, payload)
    }
}
