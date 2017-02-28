import XCTest
import Crust
import JSONValueRX
import Realm

class PrimaryObj1Mapping : RealmMapping {
    
    var adaptor: RealmAdaptor
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.uuid", nil) ]
    }
    
    required init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    func mapping(tomap: inout PrimaryObj1, context: MappingContext) {
        let obj2Mapping = PrimaryObj2Mapping(adaptor: self.adaptor)
        
        map(toRLMArray: tomap.class2s, using: (Binding.mapping("class2s", obj2Mapping), context))
        tomap.uuid          <- "data.uuid" >*<
        context
    }
}

// Until we support optional mappings, have to make a nested version.
class NestedPrimaryObj1Mapping : RealmMapping {
    
    var adaptor: RealmAdaptor
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.uuid", nil) ]
    }
    
    required init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    func mapping(tomap: inout PrimaryObj1, context: MappingContext) { }
}

class PrimaryObj2Mapping : RealmMapping {
    
    var adaptor: RealmAdaptor
    var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("uuid", "data.more_data.uuid", nil) ]
    }
    
    required init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    func mapping(tomap: inout PrimaryObj2, context: MappingContext) {
        // TODO: Including this mapping fails. Need to support making some mappings as optional
        // so when the recursive cycle of json between these two relationships runs out it doesn't error
        // from expecting json.
        //
        // In the meantime, user can write separate Nested Mappings for the top level object and nested objects.
//        let obj1Mapping = PrimaryObj1Mapping(adaptor: self.adaptor)
        
        let obj1Mapping = NestedPrimaryObj1Mapping(adaptor: self.adaptor)
        
        tomap.class1        <- Binding.mapping("class1", obj1Mapping) >*<
        context
    }
}

public class DatePrimaryObjMapping : RealmMapping {
    
    public var adaptor: RealmAdaptor
    public var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
        return [ ("remoteId", "remoteId", nil) ]
    }
    
    public required init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    public func mapping(tomap: inout DatePrimaryObj, context: MappingContext) {
        tomap.date <- ("date", context)
        tomap.junk <- ("junk", context)
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
        let object = try! mapper.map(from: json, using: PrimaryObj1Mapping(adaptor: adaptor!))
        
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
        let object = try! mapper.map(from: json, using: PrimaryObj2Mapping(adaptor: adaptor!))
        
        XCTAssertEqual(PrimaryObj2.allObjects(in: realm!).count, 1)
        XCTAssertEqual(PrimaryObj2.allObjects(in: realm!).count, 1)
        XCTAssertEqual(object, obj)
    }
    
    func testFeatchingWithStringDateCorrectlySantizesValue() {
        let date = Date().isoString
        let obj = DatePrimaryObj()
        obj.remoteId = 1
        obj.date = Date(isoString: date)
        realm!.beginWriteTransaction()
        realm!.add(obj)
        try! realm!.commitWriteTransaction()
        
        let mapping = DatePrimaryObjMapping(adaptor: adaptor!)
        let object = mapping.adaptor.fetchObjects(type: DatePrimaryObj.self, primaryKeyValues: [["date" : date as CVarArg]], isMapping: false)?.first as! DatePrimaryObj
        XCTAssertEqual(object.date!, Date(isoString: date))
    }
    
    func testPrimaryKeyIsSantizedFromJSONDoubleToInt() {
        let finalDate = Date()
        let json2Dict = [ "remoteId" : 1, "date" : finalDate.isoString, "junk" : "junk" ] as [String : Any]
        let json = try! JSONValue(object: json2Dict)
        
        XCTAssertTrue(json["remoteId"]!.values() is Double)
        
        let mapper = Mapper()
        let object = try! mapper.map(from: json, using: DatePrimaryObjMapping(adaptor: adaptor!))
        
        XCTAssertEqual(DatePrimaryObj.allObjects(in: realm!).count, 1)
        XCTAssertEqual(object.remoteId!, 1)
    }
    
    func testPrimaryKeyTransformIsRespected() {
        class DatePrimaryObjMappingWithTransform : DatePrimaryObjMapping {
            var called = false
            override var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
                return [ ("remoteId", "remoteId", { [weak self] in
                    self?.called = true
                    let remoteId = $0["data"]
                    return Int.fromJSON(remoteId!)
                }) ]
            }
        }
        
        let finalDate = Date()
        let json2Dict = [ "remoteId" : ["data" : "1"], "date" : finalDate.isoString, "junk" : "junk" ] as [String : Any]
        let json = try! JSONValue(object: json2Dict)
        let mapper = Mapper()
        let mapping = DatePrimaryObjMappingWithTransform(adaptor: adaptor!)
        let object = try! mapper.map(from: json, using: mapping)
        
        XCTAssertTrue(mapping.called)
        XCTAssertEqual(DatePrimaryObj.allObjects(in: realm!).count, 1)
        XCTAssertEqual(object.remoteId!, 1)
    }
    
    func testPrimaryKeyTransformThrownErrorIsReturned() {
        struct Garbage: Error { }
        class DatePrimaryObjMappingWithTransform : DatePrimaryObjMapping {
            var called = false
            override var primaryKeys: [Mapping.PrimaryKeyDescriptor]? {
                return [ ("remoteId", "remoteId", { (json: JSONValue?) throws -> CVarArg? in
                    throw Garbage()
                }) ]
            }
        }
        
        let finalDate = Date()
        let json2Dict = [ "remoteId" : ["data" : "1"], "date" : finalDate.isoString, "junk" : "junk" ] as [String : Any]
        let json = try! JSONValue(object: json2Dict)
        let mapper = Mapper()
        let mapping = DatePrimaryObjMappingWithTransform(adaptor: adaptor!)
        do {
            _ = try mapper.map(from: json, using: mapping)
        }
        catch let e {
            XCTAssertTrue(e is Garbage)
        }
    }
}
