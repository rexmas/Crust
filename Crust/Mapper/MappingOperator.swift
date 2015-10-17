import Foundation

/**
* This file defines a new operator which is used to create a mapping between an object and a JSON key value.
* There is an overloaded operator definition for each type of object that is supported in ObjectMapper.
* This provides a way to add custom logic to handle specific types of objects
*/

infix operator >*< { associativity right }

public func >*< <T, U>(left: T, right: U) -> (T, U) {
    return (left, right)
}

public func >*< <T: JSONKeypath, U>(left: T, right: U) -> (JSONKeypath, U) {
    return (left, right)
}

infix operator <- { associativity right }

// MARK:- Objects with Basic types

// Object of Basic type
public func <- <T: JSONable, C: CRMappingContext where T == T.J>(inout field: T, map:(key: JSONKeypath, context: C)) -> C {
    
    if case .Error(_)? = map.context.result {
        return map.context
    }
    
    switch map.context.dir {
    case .ToJSON:
        let json = map.context.json
        map.context.json = mapToJson(json, fromField: field, viaKey: map.key)
        map.context.result = .Value(json)
    case .FromJSON:
        do {
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: &field)
            } else {
                map.context.result = Result.Error(NSError(domain: "", code: 0, userInfo: nil))
            }
        } catch let error as NSError {
            map.context.result = Result.Error(error)
        }
    }
    
    return map.context
}

// Map to JSON with field as optional type.
func mapToJson<T: JSONable where T == T.J>(var json: JSONValue, fromField field: T?, viaKey key: JSONKeypath) -> JSONValue {
    
    if let field = field {
        let result = T.toJSON(field)
        json[key] = result
    } else {
        json[key] = .JSONNull()
    }
    
    return json
}

// TODO: Have a map for optional fields. .Null will map to `nil`.
func mapFromJson<T: JSONable where T.J == T>(json: JSONValue, inout toField field: T) throws {
    
    if let fromJson = T.fromJSON(json) {
        field = fromJson
    } else {
        throw NSError(domain: "CRMappingDomain", code: -1, userInfo: nil)
    }
}
