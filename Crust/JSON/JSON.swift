import Foundation

public enum JSONValue : CustomStringConvertible {
    case JSONArray([JSONValue])
    case JSONObject([String : JSONValue])   // TODO: Maybe elevate this to [Hashable : JSONValue]?
    case JSONNumber(Double)
    case JSONString(String)
    case JSONBool(Bool)
    case JSONNull()
    
    public func values() -> AnyObject {
        switch self {
        case let .JSONArray(xs):
            return xs.map { $0.values() }
        case let .JSONObject(xs):
            return xs.mapValues { $0.values() }
        case let .JSONNumber(n):
            return n
        case let .JSONString(s):
            return s
        case let .JSONBool(b):
            return b
        case .JSONNull():
            return NSNull()
        }
    }
    
    public func valuesAsNSObjects() -> NSObject {
        switch self {
        case let .JSONArray(xs):
            return xs.map { $0.values() }
        case let .JSONObject(xs):
            return xs.mapValues { $0.values() }
        case let .JSONNumber(n):
            return NSNumber(double: n)
        case let .JSONString(s):
            return NSString(string: s)
        case let .JSONBool(b):
            return NSNumber(bool: b)
        case .JSONNull():
            return NSNull()
        }
    }
    
    public init<T>(array: Array<T>) throws {
        let jsonValues = try array.map {
            return try JSONValue(object: $0)
        }
        self = .JSONArray(jsonValues)
    }
    
    public init<V>(dict: Dictionary<String, V>) throws {
        var jsonValues = [String : JSONValue]()
        for (key, val) in dict {
            let x = try JSONValue(object: val)
            jsonValues[key] = x
        }
        self = .JSONObject(jsonValues)
    }
    
    // NOTE: Would be nice to figure out a generic recursive way of solving this.
    // Array<Dictionary<String, Any>> doesn't seem to work. Maybe case eval on generic param too?
    public init(object: Any) throws {
        switch object {
        case let array as Array<Any>:
            let jsonValues = try array.map {
                return try JSONValue(object: $0)
            }
            self = .JSONArray(jsonValues)
            
        case let array as NSArray:
            let jsonValues = try array.map {
                return try JSONValue(object: $0)
            }
            self = .JSONArray(jsonValues)
            
        case let dict as Dictionary<String, Any>:
            var jsonValues = [String : JSONValue]()
            for (key, val) in dict {
                let x = try JSONValue(object: val)
                jsonValues[key] = x
            }
            self = .JSONObject(jsonValues)
            
        case let dict as NSDictionary:
            var jsonValues = [String : JSONValue]()
            for (key, val) in dict {
                let x = try JSONValue(object: val)
                jsonValues[key as! String] = x
            }
            self = .JSONObject(jsonValues)
        
        case let val as NSNumber:
            if val.isBool {
                self = .JSONBool(val.boolValue)
            } else {
                self = .JSONNumber(val.doubleValue)
            }
            
        case let val as NSString:
            self = .JSONString(String(val))
            
        case is NSNull:
            self = .JSONNull()
            
        default:
            // TODO: Generate an enum of standard errors.
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "\(object.dynamicType) cannot be converted to JSON" ]
            throw NSError(domain: "CRJSONErrorDomain", code: -1000, userInfo: userInfo)
        }
    }
    
    public func encode() throws -> NSData {
        return try NSJSONSerialization.dataWithJSONObject(self.values(), options: NSJSONWritingOptions(rawValue: 0))
    }
    
    public static func decode(data: NSData) throws -> JSONValue {
        let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
        return try JSONValue(object: json)
    }
    
    public static func decode(string: String) throws -> JSONValue {
        return try JSONValue.decode(string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
    }
    
    public subscript(index: JSONKeypath) -> JSONValue? {
        get {
            return self[index.keyPath]
        }
        set(newValue) {
            self[index.keyPath] = newValue
        }
    }
    
    subscript(index: String) -> JSONValue? {
        get {
            let components = index.componentsSeparatedByString(".")
            return self[components]
        }
        set(newValue) {
            let components = index.componentsSeparatedByString(".")
            self[components] = newValue
        }
    }
    
    public subscript(index: [String]) -> JSONValue? {
        get {
            guard let key = index.first else {
                return self
            }
            
            let keys = index.dropFirst()
            switch self {
            case .JSONObject(let obj):
                if let next = obj[key] {
                    return next[Array(keys)]
                } else {
                    return nil
                }
            case .JSONArray(let arr):
                return .JSONArray(arr.flatMap { $0[index] })
            default:
                return nil
            }
        }
        set (newValue) {
            guard let key = index.first else {
                return
            }
            
            if index.count == 1 {
                switch self {
                case .JSONObject(var obj):
                    if (newValue != nil) {
                        obj.updateValue(newValue!, forKey: key)
                    } else {
                        obj.removeValueForKey(key)
                    }
                    self = .JSONObject(obj)
                default:
                    return
                }
            }
            
            let keys = index.dropFirst()
            switch self {
            case .JSONObject(var obj):
                if var next = obj[key] {
                    next[Array(keys)] = newValue
                    obj.updateValue(next, forKey: key)
                    self = .JSONObject(obj)
                }
            default:
                return
            }
        }
    }
    
    public var description : String {
        switch self {
        case .JSONNull():
            return "JSONNull()"
        case let .JSONBool(b):
            return "JSONBool(\(b))"
        case let .JSONString(s):
            return "JSONString(\(s))"
        case let .JSONNumber(n):
            return "JSONNumber(\(n))"
        case let .JSONObject(o):
            return "JSONObject(\(o))"
        case let .JSONArray(a):
            return "JSONArray(\(a))"
        }
    }
}

// MARK: - Hashable, Equatable

extension JSONValue : Hashable {
    
    static let prime = 31
    static let truePrime = 1231;
    static let falsePrime = 1237;
    
    public var hashValue: Int {
        switch self {
        case .JSONNull():
            return JSONValue.prime
        case let .JSONBool(b):
            return b ? JSONValue.truePrime : JSONValue.falsePrime
        case let .JSONString(s):
            return s.hashValue
        case let .JSONNumber(n):
            return n.hashValue
        case let .JSONObject(obj):
            return obj.reduce(1, combine: { (accum: Int, pair: (key: String, val: JSONValue)) -> Int in
                return accum.hashValue ^ pair.key.hashValue ^ pair.val.hashValue.byteSwapped
            })
        case let .JSONArray(xs):
            return xs.reduce(3, combine: { (accum: Int, val: JSONValue) -> Int in
                return (accum.hashValue &* JSONValue.prime) ^ val.hashValue
            })
        }
    }
}

public func ==(lhs : JSONValue, rhs : JSONValue) -> Bool {
    switch (lhs, rhs) {
    case (.JSONNull(), .JSONNull()):
        return true
    case let (.JSONBool(l), .JSONBool(r)) where l == r:
        return true
    case let (.JSONString(l), .JSONString(r)) where l == r:
        return true
    case let (.JSONNumber(l), .JSONNumber(r)) where l == r:
        return true
    case let (.JSONObject(l), .JSONObject(r))
        where l.elementsEqual(r, isEquivalent: {
            (v1: (String, JSONValue), v2: (String, JSONValue)) in
            v1.0 == v2.0 && v1.1 == v2.1
        }):
        return true
    case let (.JSONArray(l), .JSONArray(r)) where l.elementsEqual(r, isEquivalent: { $0 == $1 }):
        return true
    default:
        return false
    }
}

public func !=(lhs : JSONValue, rhs : JSONValue) -> Bool {
    return !(lhs == rhs)
}

// someday someone will ask for this
//// Comparable
//func <=(lhs: JSValue, rhs: JSValue) -> Bool {
//  return false;
//}
//
//func >(lhs: JSValue, rhs: JSValue) -> Bool {
//  return !(lhs <= rhs)
//}
//
//func >=(lhs: JSValue, rhs: JSValue) -> Bool {
//  return (lhs > rhs || lhs == rhs)
//}
//
//func <(lhs: JSValue, rhs: JSValue) -> Bool {
//  return !(lhs >= rhs)
//}

//public func <? <A : JSONDecodable where A == A.J>(lhs : JSONValue, rhs : JSONKeypath) -> A? {
//    switch lhs {
//    case let .JSONObject(d):
//        return resolveKeypath(d, rhs: rhs).flatMap(A.fromJSON)
//    default:
//        return .None
//    }
//}
//
//public func <? <A : JSONDecodable where A == A.J>(lhs : JSONValue, rhs : JSONKeypath) -> [A]? {
//    switch lhs {
//    case let .JSONObject(d):
//        return resolveKeypath(d, rhs: rhs).flatMap(JArrayFrom<A, A>.fromJSON)
//    default:
//        return .None
//    }
//}
//
//public func <? <A : JSONDecodable where A == A.J>(lhs : JSONValue, rhs : JSONKeypath) -> [String:A]? {
//    switch lhs {
//    case let .JSONObject(d):
//        return resolveKeypath(d, rhs: rhs).flatMap(JDictionaryFrom<A, A>.fromJSON)
//    default:
//        return .None
//    }
//}
//
//public func <! <A : JSONDecodable where A == A.J>(lhs : JSONValue, rhs : JSONKeypath) -> A {
//    if let r : A = (lhs <? rhs) {
//        return r
//    }
//    return error("Cannot find value at keypath \(rhs) in JSON object \(rhs).")
//}
//
//public func <! <A : JSONDecodable where A == A.J>(lhs : JSONValue, rhs : JSONKeypath) -> [A] {
//    if let r : [A] = (lhs <? rhs) {
//        return r
//    }
//    return error("Cannot find array at keypath \(rhs) in JSON object \(rhs).")
//}
//
//public func <! <A : JSONDecodable where A == A.J>(lhs : JSONValue, rhs : JSONKeypath) -> [String:A] {
//    if let r : [String:A] = (lhs <? rhs) {
//        return r
//    }
//    return error("Cannot find object at keypath \(rhs) in JSON object \(rhs).")
//}

// MARK: - Protocols
// MARK: - JSONKeypath

public protocol JSONKeypath {
    var keyPath: String { get }
}

extension String : JSONKeypath {
    public var keyPath: String {
        return self
    }
}

extension Int : JSONKeypath {
    public var keyPath: String {
        return String(self)
    }
}

// MARK: - JSONable

// TODO: May need to remove the typealias and just return Any if
// Array conversion turns out to be too cumbersome.

public protocol JSONDecodable {
    typealias J = Self
    static func fromJSON(x : JSONValue) -> J?
}

public protocol JSONEncodable {
    typealias J
    static func toJSON(x : J) -> JSONValue
}

public protocol JSONable : JSONDecodable, JSONEncodable { }

extension Dictionary : JSONable {
    public static func fromJSON(x: JSONValue) -> Dictionary.J? {
        switch x {
        case .JSONObject:
            return x.values() as? Dictionary<String, Value>
        default:
            return nil
        }
    }
    
    public static func toJSON(x: Dictionary.J) -> JSONValue {
        do {
            return try JSONValue(dict: x)
        } catch {
            return JSONValue.JSONNull()
        }
    }
}

extension Array : JSONable {
    public static func fromJSON(x: JSONValue) -> Array? {
        switch x {
        case .JSONArray:
            return x.values() as? Array
        default:
            return nil
        }
    }
    
    public static func toJSON(x: Array) -> JSONValue {
        do {
            return try JSONValue(array: x)
        } catch {
            return JSONValue.JSONNull()
        }
    }
}

extension Bool : JSONable {
    public static func fromJSON(x : JSONValue) -> Bool? {
        switch x {
        case let .JSONBool(n):
            return n
        case .JSONNumber(0):
            return false
        case .JSONNumber(1):
            return true
        default:
            return nil
        }
    }
    
    public static func toJSON(xs : Bool) -> JSONValue {
        return JSONValue.JSONNumber(Double(xs))
    }
}

extension Int : JSONable {
    public static func fromJSON(x : JSONValue) -> Int? {
        switch x {
        case let .JSONNumber(n):
            return Int(n)
        default:
            return nil
        }
    }
    
    public static func toJSON(xs : Int) -> JSONValue {
        return JSONValue.JSONNumber(Double(xs))
    }
}

extension Double : JSONable {
    public static func fromJSON(x : JSONValue) -> Double? {
        switch x {
        case let .JSONNumber(n):
            return n
        default:
            return nil
        }
    }
    
    public static func toJSON(xs : Double) -> JSONValue {
        return JSONValue.JSONNumber(xs)
    }
}

extension NSNumber : JSONable {
    public class func fromJSON(x : JSONValue) -> NSNumber? {
        switch x {
        case let .JSONNumber(n):
            return NSNumber(double: n)
        default:
            return nil
        }
    }
    
    public class func toJSON(x : NSNumber) -> JSONValue {
        return JSONValue.JSONNumber(Double(x))
    }
}

extension String : JSONable {
    public static func fromJSON(x : JSONValue) -> String? {
        switch x {
        case let .JSONString(n):
            return n
        default:
            return nil
        }
    }
    
    public static func toJSON(x : String) -> JSONValue {
        return JSONValue.JSONString(x)
    }
}

extension NSDate : JSONable {
    public static func fromJSON(x: JSONValue) -> NSDate? {
        switch x {
        case let .JSONString(string):
            return NSDate.fromISOString(string)
        default:
            return nil
        }
    }
    
    public static func toJSON(x: NSDate) -> JSONValue {
        return .JSONString(x.toISOString())
    }
}

extension NSNull : JSONable {
    public class func fromJSON(x : JSONValue) -> NSNull? {
        switch x {
        case .JSONNull():
            return NSNull()
        default:
            return nil
        }
    }
    
    public class func toJSON(xs : NSNull) -> JSONValue {
        return JSONValue.JSONNull()
    }
}

// MARK: - Specialized Containers
// Container types should be split.

public struct JArrayFrom<A, B : JSONDecodable where B.J == A> : JSONDecodable {
    public typealias J = [A]
    
    public static func fromJSON(x : JSONValue) -> J? {
        switch x {
        case let .JSONArray(xs):
            let r = xs.map(B.fromJSON)
            let rp = r.flatMap { $0 }
            if r.count == rp.count {
                return rp
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

public struct JArrayTo<A, B : JSONEncodable where B.J == A> : JSONEncodable {
    public typealias J = [A]
    
    public static func toJSON(xs: J) -> JSONValue {
        return JSONValue.JSONArray(xs.map(B.toJSON))
    }
}

public struct JArray<A, B : JSONable where B.J == A> : JSONable {
    public typealias J = [A]
    
    public static func fromJSON(x : JSONValue) -> J? {
        switch x {
        case let .JSONArray(xs):
            let r = xs.map(B.fromJSON)
            let rp = r.flatMap { $0 }
            if r.count == rp.count {
                return rp
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    public static func toJSON(xs : J) -> JSONValue {
        return JSONValue.JSONArray(xs.map(B.toJSON))
    }
}


public struct JDictionaryFrom<A, B : JSONDecodable where B.J == A> : JSONDecodable {
    public typealias J = Dictionary<String, A>
    
    public static func fromJSON(x : JSONValue) -> J? {
        switch x {
        case let .JSONObject(xs):
            return xs.mapValues { B.fromJSON($0)! }
        default: 
            return nil
        }
    }
}

public struct JDictionaryTo<A, B : JSONEncodable where B.J == A> : JSONEncodable {
    public typealias J = Dictionary<String, A>
    
    public static func toJSON(xs : J) -> JSONValue {
        return JSONValue.JSONObject(xs.mapValues { B.toJSON($0) })
    }
}

public struct JDictionary<A, B : JSONable where B.J == A> : JSONable {
    public typealias J = Dictionary<String, A>
    
    public static func fromJSON(x : JSONValue) -> J? {
        switch x {
        case let .JSONObject(xs):
            return xs.mapValues { B.fromJSON($0)! }
        default: 
            return nil
        }
    }
    
    public static func toJSON(xs : J) -> JSONValue {
        return JSONValue.JSONObject(xs.mapValues { B.toJSON($0) })
    }
}
