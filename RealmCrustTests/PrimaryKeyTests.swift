import XCTest
import Crust
import JSONValueRX
import Realm

class PrimaryObj1Mapping : RealmMapping {
    
    var adapter: RealmAdapter
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.uuid", nil) ]
    }
    
    required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    func mapping(toMap: inout PrimaryObj1, payload: MappingPayload<String>) {
        let obj2Mapping = PrimaryObj2Mapping(adapter: self.adapter)
        
        map(toRLMArray: toMap.class2s, using: (.mapping("class2s", obj2Mapping), payload))
        toMap.uuid          <- ("data.uuid", payload)
    }
}

// Until we support optional mappings, have to make a nested version.
class NestedPrimaryObj1Mapping : RealmMapping {
    
    var adapter: RealmAdapter
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.uuid", nil) ]
    }
    
    required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    func mapping(toMap: inout PrimaryObj1, payload: MappingPayload<AnyMappingKey>) { }
}

class PrimaryObj2Mapping : RealmMapping {
    
    let nested: NestedPrimaryObj1Mapping
    var adapter: RealmAdapter
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.more_data.uuid", nil) ]
    }
    
    required init(adapter: RealmAdapter) {
        self.adapter = adapter
        self.nested = NestedPrimaryObj1Mapping(adapter: adapter)
    }
    
    required init(adapter: RealmAdapter, nested: NestedPrimaryObj1Mapping) {
        self.adapter = adapter
        self.nested = nested
    }
    
    func mapping(toMap: inout PrimaryObj2, payload: MappingPayload<String>) {
        // TODO: Including this mapping fails. Need to support making some mappings as optional
        // so when the recursive cycle of json between these two relationships runs out it doesn't error
        // from expecting json.
        //
        // In the meantime, user can write separate Nested Mappings for the top level object and nested objects.
//        let obj1Mapping = PrimaryObj1Mapping(adapter: self.adapter)
        
        let obj1Mapping = nested
        
        toMap.class1        <- (Binding.mapping("class1", obj1Mapping), payload)
    }
}

public class DatePrimaryObjMapping : RealmMapping {
    
    public var adapter: RealmAdapter
    public var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("remoteId", "remoteId", nil) ]
    }
    
    public required init(adapter: RealmAdapter) {
        self.adapter = adapter
    }
    
    public func mapping(toMap: inout DatePrimaryObj, payload: MappingPayload<AnyMappingKey>) {
        toMap.date <- ("date", payload)
        toMap.junk <- ("junk", payload)
    }
}

class PrimaryKeyTests: RealmMappingTest {

    func testMappingsWithPrimaryKeys() {
        
        var json1Dict = [ "data" : [ "uuid" : "primary1" ] ]  as [String : Any]
        let json2Dict1 = [ "data.more_data.uuid" : "primary2.1", "class1" : json1Dict ] as [String : Any]
        let json2Dict2 = [ "data.more_data.uuid" : "primary2.2", "class1" : json1Dict ] as [String : Any]
        
        json1Dict["class2s"] = [ json2Dict1, json2Dict2 ]
        
        XCTAssertEqual(PrimaryObj1.allObjects(in: realm!).count, 0)
        XCTAssertEqual(PrimaryObj2.allObjects(in: realm!).count, 0)
        
        let json = try! JSONValue(object: json1Dict)
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: PrimaryObj1Mapping(adapter: adapter!), keyedBy: AllKeys())
        
        XCTAssertEqual(PrimaryObj1.allObjects(in: realm!).count, 1)
        XCTAssertEqual(PrimaryObj2.allObjects(in: realm!).count, 2)
        XCTAssertEqual(object.uuid, "primary1")
        XCTAssertEqual(object.class2s.count, 2)
    }
    
    func testMappingsWithPrimaryKeysForAlreadyPresentObject() {
        let obj = PrimaryObj2()
        obj.uuid = "primary2"
        realm!.beginWriteTransaction()
        realm!.add(obj)
        try! realm!.commitWriteTransaction()
        
        let json2Dict = [ "data.more_data.uuid" : "primary2", "class1" : [ "data" : [ "uuid" : "primary1" ] ] ] as [String : Any]
        
        XCTAssertEqual(PrimaryObj1.allObjects(in: realm!).count, 0)
        XCTAssertEqual(PrimaryObj2.allObjects(in: realm!).count, 1)
        
        let json = try! JSONValue(object: json2Dict)
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: PrimaryObj2Mapping(adapter: adapter!), keyedBy: AllKeys())
        
        XCTAssertEqual(PrimaryObj2.allObjects(in: realm!).count, 1)
        XCTAssertEqual(PrimaryObj2.allObjects(in: realm!).count, 1)
        XCTAssertEqual(object, obj)
    }
    
    func testFetchingWithStringDateCorrectlySantizesValue() {
        let date = Date().isoString
        let obj = DatePrimaryObj()
        obj.remoteId = 1 as NSNumber & RLMInt
        obj.date = Date(isoString: date)
        realm!.beginWriteTransaction()
        realm!.add(obj)
        try! realm!.commitWriteTransaction()
        
        let mapping = DatePrimaryObjMapping(adapter: adapter!)
        let object = mapping.adapter.fetchObjects(baseType: DatePrimaryObj.self, primaryKeyValues: [["date" : date as CVarArg]], isMapping: false)?.first as! DatePrimaryObj
        XCTAssertEqual(object.date!, Date(isoString: date))
    }
    
    func testPrimaryKeyIsSantizedFromJSONDoubleToInt() {
        let finalDate = Date()
        let json2Dict = [ "remoteId" : 1, "date" : finalDate.isoString, "junk" : "junk" ] as [String : Any]
        let json = try! JSONValue(object: json2Dict)
        
        XCTAssertTrue(json["remoteId"]!.values() is Double)
        
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: DatePrimaryObjMapping(adapter: adapter!), keyedBy: AllKeys())
        
        XCTAssertEqual(DatePrimaryObj.allObjects(in: realm!).count, 1)
        XCTAssertEqual(object.remoteId! as NSNumber, 1 as NSNumber)
    }
    
    func testPrimaryKeyTransformIsRespected() {
        class DatePrimaryObjMappingWithTransform : DatePrimaryObjMapping {
            var called = false
            override var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
                return [ ("remoteId", "remoteId", { [weak self] (json, _) in
                    self?.called = true
                    let remoteId = json["data"]
                    return Int.fromJSON(remoteId!)
                }) ]
            }
        }
        
        let finalDate = Date()
        let json2Dict = [ "remoteId" : ["data" : "1"], "date" : finalDate.isoString, "junk" : "junk" ] as [String : Any]
        let json = try! JSONValue(object: json2Dict)
        let mapper = Mapper()
        let mapping = DatePrimaryObjMappingWithTransform(adapter: adapter!)
        let object = try! mapper.map(from: json, using: mapping, keyedBy: AllKeys())
        
        XCTAssertTrue(mapping.called)
        XCTAssertEqual(DatePrimaryObj.allObjects(in: realm!).count, 1)
        XCTAssertEqual(object.remoteId! as NSNumber, 1)
    }
    
    func testPrimaryKeyTransformParentPayloadIsPassedThrough() {
        struct Garbage: Error { }
        class NestedPrimaryObj1MappingWithParent : NestedPrimaryObj1Mapping {
            var called = false
            let parentJSON: JSONValue
            
            init(adapter: RealmAdapter, parentJSON: JSONValue) {
                self.parentJSON = parentJSON
                super.init(adapter: adapter)
            }
            
            required init(adapter: RealmAdapter) {
                fatalError("init(adapter:) has not been implemented")
            }
            
            override var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
                return [ ("uuid", "data.uuid", { (json: JSONValue?, parent: MappingPayload<AnyMappingKey>?) throws -> CVarArg? in
                    XCTAssertNotNil(parent)
                    XCTAssertEqual(self.parentJSON, parent!.json)
                    XCTAssertEqual(json!, self.parentJSON["class1.data.uuid"])
                    self.called = true
                    return nil
                }) ]
            }
        }
        
        let obj = PrimaryObj2()
        obj.uuid = "primary2"
        realm!.beginWriteTransaction()
        realm!.add(obj)
        try! realm!.commitWriteTransaction()
        
        let json2Dict = [ "data.more_data.uuid" : "primary2", "class1" : [ "data" : [ "uuid" : "primary1" ] ] ] as [String : Any]
        let json = try! JSONValue(object: json2Dict)
        let mapper = Mapper()
        let nestedMapping = NestedPrimaryObj1MappingWithParent(adapter: adapter!, parentJSON: json)
        _ = try! mapper.map(from: json, using: PrimaryObj2Mapping(adapter: adapter!, nested: nestedMapping), keyedBy: AllKeys())
        
        XCTAssertTrue(nestedMapping.called)
        XCTAssertEqual(PrimaryObj2.allObjects(in: realm!).count, 1)
    }
    
    func testPrimaryKeyTransformThrownErrorIsReturned() {
        struct Garbage: Error { }
        class DatePrimaryObjMappingWithTransform : DatePrimaryObjMapping {
            var called = false
            override var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
                return [ ("remoteId", "remoteId", { (json: JSONValue?, _) throws -> CVarArg? in
                    throw Garbage()
                }) ]
            }
        }
        
        let finalDate = Date()
        let json2Dict = [ "remoteId" : ["data" : "1"], "date" : finalDate.isoString, "junk" : "junk" ] as [String : Any]
        let json = try! JSONValue(object: json2Dict)
        let mapper = Mapper()
        let mapping = DatePrimaryObjMappingWithTransform(adapter: adapter!)
        do {
            _ = try mapper.map(from: json, using: mapping, keyedBy: AllKeys())
        }
        catch let e {
            XCTAssertTrue(e is Garbage)
        }
    }
}
