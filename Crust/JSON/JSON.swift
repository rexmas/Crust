import Foundation

public enum JSONValue : CustomStringConvertible {
    case JSONArray([JSONValue])
    case JSONObject([String : JSONValue])   // TODO: Maybe elevate this to [Hashable : JSONValue]?
    case JSONNumber(Double)
    case JSONString(String)
    case JSONBool(Bool)
    case JSONNull()
    
    public func values() -> NSObject {
        switch self {
        case let .JSONArray(xs):
            return NSArray(array: xs.map { $0.values() })
        case let .JSONObject(xs):
            return NSDictionary(dictionary: xs.mapValues { $0.values() })
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
            throw NSError(domain: "CRJSONErrorDomain", code: -1000, userInfo: nil);
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
    
    subscript(index: JSONKeypath) -> JSONValue? {
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
    
    subscript(index: [String]) -> JSONValue? {
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

// You'll have more fun if you match tuples.
// Equatable
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

// instances

extension NSArray : JSONable {
    public static func fromJSON(x: JSONValue) -> NSArray? {
        switch x {
        case .JSONArray:
            return x.values() as? NSArray
        default:
            return nil
        }
    }
    
    public static func toJSON(x: NSArray) -> JSONValue {
        do {
            return try JSONValue(object: x)
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
    
    public class func toJSON(xs : NSNumber) -> JSONValue {
        return JSONValue.JSONNumber(Double(xs))
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
    
    public static func toJSON(xs : String) -> JSONValue {
        return JSONValue.JSONString(xs)
    }
}

// or unit...
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

// container types should be split
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


/// MARK: Implementation Details

//private func resolveKeypath(lhs : Dictionary<String, JSONValue>, rhs : JSONKeypath) -> JSONValue? {
//    if rhs.path.isEmpty {
//        return .None
//    }
//    
//    switch rhs.path.match {
//    case .Nil:
//        return .None
//    case let .Cons(hd, tl):
//        if let o = lhs[hd] {
//            switch o {
//            case let .JSONObject(d) where rhs.path.count > 1:
//                return resolveKeypath(d, rhs: JSONKeypath(tl))
//            default:
//                return o
//            }
//        }
//        return .None
//    }
//}
