import Foundation

public enum JSONValue: CustomStringConvertible {
    case jsonArray([JSONValue])
    case jsonObject([String : JSONValue])
    case jsonNumber(Double)
    case jsonString(String)
    case jsonBool(Bool)
    case jsonNull()
    
    public func values() -> AnyObject {
        switch self {
        case let .jsonArray(xs):
            return xs.map { $0.values() } as AnyObject
        case let .jsonObject(xs):
            return xs.mapValues { $0.values() } as AnyObject
        case let .jsonNumber(n):
            return n as AnyObject
        case let .jsonString(s):
            return s as AnyObject
        case let .jsonBool(b):
            return b as AnyObject
        case .jsonNull():
            return NSNull()
        }
    }
    
    public func valuesAsNSObjects() -> NSObject {
        switch self {
        case let .jsonArray(xs):
            return xs.map { $0.values() } as NSObject
        case let .jsonObject(xs):
            return xs.mapValues { $0.values() } as NSObject
        case let .jsonNumber(n):
            return NSNumber(value: n as Double)
        case let .jsonString(s):
            return NSString(string: s)
        case let .jsonBool(b):
            return NSNumber(value: b as Bool)
        case .jsonNull():
            return NSNull()
        }
    }
    
    public init<T>(array: Array<T>) throws {
        let jsonValues = try array.map {
            return try JSONValue(object: $0)
        }
        self = .jsonArray(jsonValues)
    }
    
    public init<V>(dict: Dictionary<String, V>) throws {
        var jsonValues = [String : JSONValue]()
        for (key, val) in dict {
            let x = try JSONValue(object: val)
            jsonValues[key] = x
        }
        self = .jsonObject(jsonValues)
    }
    
    // NOTE: Would be nice to figure out a generic recursive way of solving this.
    // Array<Dictionary<String, Any>> doesn't seem to work. Maybe case eval on generic param too?
    public init(object: Any) throws {
        switch object {
        case let array as Array<Any>:
            let jsonValues = try array.map {
                return try JSONValue(object: $0)
            }
            self = .jsonArray(jsonValues)
            
        case let array as NSArray:
            let jsonValues = try array.map {
                return try JSONValue(object: $0)
            }
            self = .jsonArray(jsonValues)
            
        case let dict as Dictionary<String, Any>:
            var jsonValues = [String : JSONValue]()
            for (key, val) in dict {
                let x = try JSONValue(object: val)
                jsonValues[key] = x
            }
            self = .jsonObject(jsonValues)
            
        case let dict as NSDictionary:
            var jsonValues = [String : JSONValue]()
            for (key, val) in dict {
                let x = try JSONValue(object: val)
                jsonValues[key as! String] = x
            }
            self = .jsonObject(jsonValues)
        
        case let val as NSNumber:
            if val.isBool {
                self = .jsonBool(val.boolValue)
            } else {
                self = .jsonNumber(val.doubleValue)
            }
            
        case let val as NSString:
            self = .jsonString(String(val))
            
        case is NSNull:
            self = .jsonNull()
            
        default:
            // TODO: Generate an enum of standard errors.
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "\(type(of: (object))) cannot be converted to JSON" ]
            throw NSError(domain: "CRJSONErrorDomain", code: -1000, userInfo: userInfo)
        }
    }
    
    public func encode() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self.values(), options: JSONSerialization.WritingOptions(rawValue: 0))
    }
    
    public static func decode(_ data: Data) throws -> JSONValue {
        let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
        return try JSONValue(object: json)
    }
    
    public static func decode(_ string: String) throws -> JSONValue {
        return try JSONValue.decode(string.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
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
            let components = index.components(separatedBy: ".")
            if let result = self[components] {
                return result
            } else {
                return self[[index]]
            }
        }
        set(newValue) {
            let components = index.components(separatedBy: ".")
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
            case .jsonObject(let obj):
                if let next = obj[key] {
                    return next[Array(keys)]
                } else {
                    return nil
                }
            case .jsonArray(let arr):
                return .jsonArray(arr.flatMap { $0[index] })
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
                case .jsonObject(var obj):
                    if (newValue != nil) {
                        obj.updateValue(newValue!, forKey: key)
                    } else {
                        obj.removeValue(forKey: key)
                    }
                    self = .jsonObject(obj)
                default:
                    return
                }
            }
            
            let keys = index.dropFirst()
            switch self {
            case .jsonObject(var obj):
                if var next = obj[key] {
                    next[Array(keys)] = newValue
                    obj.updateValue(next, forKey: key)
                    self = .jsonObject(obj)
                }
            default:
                return
            }
        }
    }
    
    public var description: String {
        switch self {
        case .jsonNull():
            return "JSONNull()"
        case let .jsonBool(b):
            return "JSONBool(\(b))"
        case let .jsonString(s):
            return "JSONString(\(s))"
        case let .jsonNumber(n):
            return "JSONNumber(\(n))"
        case let .jsonObject(o):
            return "JSONObject(\(o))"
        case let .jsonArray(a):
            return "JSONArray(\(a))"
        }
    }
}

// MARK: - Protocols
// MARK: - Hashable, Equatable

extension JSONValue: Hashable {
    
    static let prime = 31
    static let truePrime = 1231;
    static let falsePrime = 1237;
    
    public var hashValue: Int {
        switch self {
        case .jsonNull():
            return JSONValue.prime
        case let .jsonBool(b):
            return b ? JSONValue.truePrime: JSONValue.falsePrime
        case let .jsonString(s):
            return s.hashValue
        case let .jsonNumber(n):
            return n.hashValue
        case let .jsonObject(obj):
            return obj.reduce(1, { (accum: Int, pair: (key: String, val: JSONValue)) -> Int in
                return accum.hashValue ^ pair.key.hashValue ^ pair.val.hashValue.byteSwapped
            })
        case let .jsonArray(xs):
            return xs.reduce(3, { (accum: Int, val: JSONValue) -> Int in
                return (accum.hashValue &* JSONValue.prime) ^ val.hashValue
            })
        }
    }
}

public func ==(lhs: JSONValue, rhs: JSONValue) -> Bool {
    switch (lhs, rhs) {
    case (.jsonNull(), .jsonNull()):
        return true
    case let (.jsonBool(l), .jsonBool(r)) where l == r:
        return true
    case let (.jsonString(l), .jsonString(r)) where l == r:
        return true
    case let (.jsonNumber(l), .jsonNumber(r)) where l == r:
        return true
    case let (.jsonObject(l), .jsonObject(r))
        where l.elementsEqual(r, by: {
            (v1: (String, JSONValue), v2: (String, JSONValue)) in
            v1.0 == v2.0 && v1.1 == v2.1
        }):
        return true
    case let (.jsonArray(l), .jsonArray(r)) where l.elementsEqual(r, by: { $0 == $1 }):
        return true
    default:
        return false
    }
}

public func !=(lhs: JSONValue, rhs: JSONValue) -> Bool {
    return !(lhs == rhs)
}

// MARK: - JSONKeypath

public protocol JSONKeypath {
    var keyPath: String { get }
}

extension String: JSONKeypath {
    public var keyPath: String {
        return self
    }
}

extension Int: JSONKeypath {
    public var keyPath: String {
        return String(self)
    }
}
