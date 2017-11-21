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
    
    func testWithArrayOfStructs() {
        let jsonObj = [
            [ "item" : [ "a", "b", "c" ] ],
            [ "item" : [ "a", "b", "c" ] ]
        ]
        let json = try! JSONValue(object: jsonObj)
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: Stream.Mapping(), keyedBy: [
            .subStreams([
                .items
                ])
            ])
        
        XCTAssertEqual(object.subStreams[0].items, [ "a", "b", "c" ])
        XCTAssertEqual(object.subStreams[1].items, [ "a", "b", "c" ])
    }
}

// MARK: - Structs

public struct Stream: AnyMappable {
    public init() { }
    
    public private(set) var subStreams = [SubStream]()
    
    public enum Key: MappingKey {
        case subStreams([SubStream.Key])
        
        public var keyPath: String {
            switch self {
            case .subStreams: return "subStreams"
            }
        }
        
        public func nestedMappingKeys<Key: MappingKey>() -> AnyKeyCollection<Key>? {
            switch self {
            case .subStreams(let keys): return keys.anyKeyCollection()
            }
        }
    }
    
    public class Mapping: AnyMapping {
        public typealias AdapterKind = AnyAdapterImp<Stream>
        public typealias MappedObject = Stream
        
        public required init() { }
        
        public func mapping(toMap: inout Stream, payload: MappingPayload<Key>) {
            toMap.subStreams <- (.mapping(RootedKey(.subStreams([])), SubStream.Mapping()), payload)
        }
    }
    
    public struct SubStream: AnyMappable {
        public init() { }
        
        public var items = [String]()
        
        public enum Key: MappingKey {
            case items
            
            public var keyPath: String {
                switch self {
                case .items: return "item"
                }
            }
            
            public func nestedMappingKeys<Key: MappingKey>() -> AnyKeyCollection<Key>? {
                switch self {
                case .items: return nil
                }
            }
        }
        
        public class Mapping: AnyMapping {
            public typealias AdapterKind = AnyAdapterImp<SubStream>
            public typealias MappedObject = SubStream
            
            public required init() { }
            
            public func mapping(toMap: inout SubStream, payload: MappingPayload<Key>) {
                toMap.items <- (.items, payload)
            }
        }
    }
}

// MARK: - Realm

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
        case .concreteObj(_):       return "blah"
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
