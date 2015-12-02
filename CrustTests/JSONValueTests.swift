import XCTest
import Crust

class JSONValueTests: XCTestCase {
    
    func testFalseAndTrueHashesAreNotEqual() {
        let jFalse = JSONValue.JSONBool(false)
        let jTrue = JSONValue.JSONBool(true)
        XCTAssertNotEqual(jFalse.hashValue, jTrue.hashValue)
    }
    
    func testHashesAreDeterministic() {
        
        let jNull = JSONValue.JSONNull()
        XCTAssertEqual(jNull.hashValue, jNull.hashValue)
        
        let jBool = JSONValue.JSONBool(false)
        XCTAssertEqual(jBool.hashValue, jBool.hashValue)
        
        let jNum = JSONValue.JSONNumber(3.0)
        XCTAssertEqual(jNum.hashValue, jNum.hashValue)
        
        let jString = JSONValue.JSONString("some json")
        XCTAssertEqual(jString.hashValue, jString.hashValue)
        
        let jDict = JSONValue.JSONObject([
            "a string" : .JSONNumber(6.0),
            "another" : .JSONNull()
            ])
        XCTAssertEqual(jDict.hashValue, jDict.hashValue)
        
        let jArray = JSONValue.JSONArray([ .JSONNumber(6.0), .JSONString("yo"), jDict ])
        XCTAssertEqual(jArray.hashValue, jArray.hashValue)
    }
    
    func testUniqueHashesForKeyValueReorderingOnJSONObject() {
        let string1 = "blah"
        let string2 = "derp"
        
        let obj1 = JSONValue.JSONObject([ string1 : .JSONString(string2) ])
        let obj2 = JSONValue.JSONObject([ string2 : .JSONString(string1) ])
        
        XCTAssertNotEqual(obj1.hashValue, obj2.hashValue)
    }
    
    func testUniqueHashesForJSONArrayReordering() {
        let string1 = "blah"
        let string2 = "derp"
        
        let arr1 = JSONValue.JSONArray([ .JSONString(string1), .JSONString(string2) ])
        let arr2 = JSONValue.JSONArray([ .JSONString(string2), .JSONString(string1) ])
        
        XCTAssertNotEqual(arr1.hashValue, arr2.hashValue)
    }
    
    func test0NumberFalseAndNullHashesAreUnique() {
        let jNull = JSONValue.JSONNull()
        let jBool = JSONValue.JSONBool(false)
        let jNum = JSONValue.JSONNumber(0.0)
        let jString = JSONValue.JSONString("\0")
        
        XCTAssertNotEqual(jNull.hashValue, jBool.hashValue)
        XCTAssertNotEqual(jNull.hashValue, jNum.hashValue)
        XCTAssertNotEqual(jNull.hashValue, jString.hashValue)
        
        XCTAssertNotEqual(jBool.hashValue, jNum.hashValue)
        XCTAssertNotEqual(jBool.hashValue, jString.hashValue)
        
        XCTAssertNotEqual(jNum.hashValue, jString.hashValue)
    }
}
