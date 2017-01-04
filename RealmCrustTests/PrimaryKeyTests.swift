import XCTest
import Crust
import JSONValueRX
import Realm

//class PrimaryObj1: RLMObject {
//    dynamic var class2s: RLMArray<PrimaryObj2>
//    dynamic var uuid: String = ""
//    
//    override class func primaryKey() -> String? {
//        return "uuid"
//    }
//}
//
//class PrimaryObj2: RLMObject {
//    dynamic var uuid: String = ""
//    dynamic var class1: PrimaryObj1?
//    
//    override class func primaryKey() -> String? {
//        return "uuid"
//    }
//}

class PrimaryObj1Mapping : RealmMapping {
    
    var adaptor: RealmAdaptor
    var primaryKeys: [String : Keypath]? {
        return [ "uuid" : "data.uuid" ]
    }
    
    required init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    func mapping(tomap: inout PrimaryObj1, context: MappingContext) {
        let obj2Mapping = PrimaryObj2Mapping(adaptor: self.adaptor)
        
        tomap.class2s       <- Spec.mapping("class2s", obj2Mapping) >*<
        tomap.uuid          <- "data.uuid" >*<
        context
    }
}

// Until we support optional mappings, have to make a nested version.
class NestedPrimaryObj1Mapping : RealmMapping {
    
    var adaptor: RealmAdaptor
    var primaryKeys: [String : Keypath]? {
        return [ "uuid" : "data.uuid" ]
    }
    
    required init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    func mapping(tomap: inout PrimaryObj1, context: MappingContext) {
        tomap.uuid          <- "data.uuid" >*<
        context
    }
}

class PrimaryObj2Mapping : RealmMapping {
    
    var adaptor: RealmAdaptor
    var primaryKeys: [String : Keypath]? {
        return [ "uuid" : "data.more_data.uuid" ]
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
        
        tomap.class1        <- Spec.mapping("class1", obj1Mapping) >*<
        tomap.uuid          <- "data.more_data.uuid" >*<
        context
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
        let mapper = CRMapper<PrimaryObj1Mapping>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: PrimaryObj1Mapping(adaptor: adaptor!))
        
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
        let mapper = CRMapper<PrimaryObj2Mapping>()
        let object = try! mapper.mapFromJSONToExistingObject(json, mapping: PrimaryObj2Mapping(adaptor: adaptor!))
        
        XCTAssertEqual(PrimaryObj2.allObjects(in: realm!).count, 1)
        XCTAssertEqual(PrimaryObj2.allObjects(in: realm!).count, 1)
        XCTAssertEqual(object, obj)
    }
}
