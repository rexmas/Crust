import Foundation

// MARK: - JSONable

public protocol JSONDecodable {
    associatedtype ConversionType = Self
    static func fromJSON(_ x: JSONValue) -> ConversionType?
}

public protocol JSONEncodable {
    associatedtype ConversionType
    static func toJSON(_ x: ConversionType) -> JSONValue
}

public protocol JSONable: JSONDecodable, JSONEncodable { }

extension Dictionary: JSONable {
    public typealias ConversionType = Dictionary<String, Value>
    public static func fromJSON(_ x: JSONValue) -> Dictionary.ConversionType? {
        switch x {
        case .jsonObject:
            return x.values() as? Dictionary<String, Value>
        default:
            return nil
        }
    }
    
    public static func toJSON(_ x: Dictionary.ConversionType) -> JSONValue {
        do {
            return try JSONValue(dict: x)
        } catch {
            return JSONValue.jsonNull()
        }
    }
}

extension Array: JSONable {
    public static func fromJSON(_ x: JSONValue) -> Array? {
        switch x {
        case .jsonArray:
            return x.values() as? Array
        default:
            return nil
        }
    }
    
    public static func toJSON(_ x: Array) -> JSONValue {
        do {
            return try JSONValue(array: x)
        } catch {
            return JSONValue.jsonNull()
        }
    }
}

extension Bool: JSONable {
    public static func fromJSON(_ x: JSONValue) -> Bool? {
        switch x {
        case let .jsonBool(n):
            return n
        case .jsonNumber(0):
            return false
        case .jsonNumber(1):
            return true
        default:
            return nil
        }
    }
    
    public static func toJSON(_ xs: Bool) -> JSONValue {
        return JSONValue.jsonBool(xs)
    }
}

extension Int: JSONable {
    public static func fromJSON(_ x: JSONValue) -> Int? {
        switch x {
        case let .jsonNumber(n):
            return Int(n)
        default:
            return nil
        }
    }
    
    public static func toJSON(_ xs: Int) -> JSONValue {
        return JSONValue.jsonNumber(Double(xs))
    }
}

extension Double: JSONable {
    public static func fromJSON(_ x: JSONValue) -> Double? {
        switch x {
        case let .jsonNumber(n):
            return n
        default:
            return nil
        }
    }
    
    public static func toJSON(_ xs: Double) -> JSONValue {
        return JSONValue.jsonNumber(xs)
    }
}

extension NSNumber: JSONable {
    public class func fromJSON(_ x: JSONValue) -> NSNumber? {
        switch x {
        case let .jsonNumber(n):
            return NSNumber(value: n as Double)
        default:
            return nil
        }
    }
    
    public class func toJSON(_ x: NSNumber) -> JSONValue {
        return JSONValue.jsonNumber(Double(x))
    }
}

extension String: JSONable {
    public static func fromJSON(_ x: JSONValue) -> String? {
        switch x {
        case let .jsonString(n):
            return n
        default:
            return nil
        }
    }
    
    public static func toJSON(_ x: String) -> JSONValue {
        return JSONValue.jsonString(x)
    }
}

extension Date: JSONable {
    public static func fromJSON(_ x: JSONValue) -> Date? {
        switch x {
        case let .jsonString(string):
            return Date(isoString: string)
        default:
            return nil
        }
    }
    
    public static func toJSON(_ x: Date) -> JSONValue {
        return .jsonString(x.isoString)
    }
}

extension NSNull: JSONable {
    public class func fromJSON(_ x: JSONValue) -> NSNull? {
        switch x {
        case .jsonNull():
            return NSNull()
        default:
            return nil
        }
    }
    
    public class func toJSON(_ xs: NSNull) -> JSONValue {
        return JSONValue.jsonNull()
    }
}
