import XCTest
import Crust
import JSONValueRX

class Node: AnyMappable {
    required init() { }
    var uuid: String = ""
}

class Parent: Node {
    var children: [Child]? = nil
}

class Child: Node {
}

class ParentMapping: Mapping {
    
    var adapter: MockAdapter<Node>
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? = nil
    
    required init(adapter: MockAdapter<Node>) {
        self.adapter = adapter
    }
    
    func mapping(toMap: inout Parent, payload: MappingPayload<AnyMappingKey>) {
        let childMapping = ChildMapping(adapter: self.adapter)
        
        toMap.children  <- (.mapping("children", childMapping), payload)
        toMap.uuid      <- ("uuid", payload)
    }
}

class ChildMapping: Mapping {
    
    var adapter: MockAdapter<Node>
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? = nil
    
    required init(adapter: MockAdapter<Node>) {
        self.adapter = adapter
    }
    
    func mapping(toMap: inout Child, payload: MappingPayload<AnyMappingKey>) {
        toMap.uuid <- ("uuid", payload)
    }
}

class NestedMappingTests: XCTestCase {
    
    func testMappingWillBeginCalledOnlyOnceWhenNestedMappingOfSameAdapter() {
        let jsonObject: [String : Any] = [
            "uuid" : NSUUID().uuidString,
            "children" : [
                [
                    "uuid" : NSUUID().uuidString
                ],
                [
                    "uuid" : NSUUID().uuidString
                ]
            ]
        ]
        
        let json = try! JSONValue(dict: jsonObject)
        let mapper = Mapper()
        let adapter = MockAdapter<Node>()
        let parent = try! mapper.map(from: json, using: ParentMapping(adapter: adapter), keyedBy: AllKeys())
        
        XCTAssertEqual(parent.uuid, jsonObject["uuid"] as! String)
        XCTAssertEqual(parent.children!.map { $0.uuid }, (jsonObject["children"] as! [[String : String]]).map { $0["uuid"]! })
        XCTAssertEqual(adapter.numberOfCallsToMappingWillBegin, 1)
    }
    
    func testMappingBeginCalledWhenNestedMappingOfDifferentAdapter() {
        class ParentMappingWithDifferentChildAdapter: ParentMapping {
            let childAdapter = MockAdapter<Node>()
            override func mapping(toMap: inout Parent, payload: MappingPayload<AnyMappingKey>) {
                let childMapping = ChildMapping(adapter: self.childAdapter)
                
                toMap.children  <- (.mapping("children", childMapping), payload)
                toMap.uuid      <- ("uuid", payload)
            }
        }
        
        let jsonObject: [String : Any] = [
            "uuid" : NSUUID().uuidString,
            "children" : [
                [
                    "uuid" : NSUUID().uuidString
                ],
                [
                    "uuid" : NSUUID().uuidString
                ]
            ]
        ]
        
        let json = try! JSONValue(dict: jsonObject)
        let mapper = Mapper()
        let adapter = MockAdapter<Node>()
        let mapping = ParentMappingWithDifferentChildAdapter(adapter: adapter)
        let parent = try! mapper.map(from: json, using: mapping, keyedBy: AllKeys())
        
        XCTAssertEqual(parent.uuid, jsonObject["uuid"] as! String)
        XCTAssertEqual(parent.children!.map { $0.uuid }, (jsonObject["children"] as! [[String : String]]).map { $0["uuid"]! })
        XCTAssertEqual(adapter.numberOfCallsToMappingWillBegin, 1)
        XCTAssertEqual(mapping.childAdapter.numberOfCallsToMappingWillBegin, 1)
    }
}
