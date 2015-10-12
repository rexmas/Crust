/**
* This file defines a new operator which is used to create a mapping between an object and a JSON key value.
* There is an overloaded operator definition for each type of object that is supported in ObjectMapper.
* This provides a way to add custom logic to handle specific types of objects
*/

infix operator >*< { associativity right }

public func >*< <T, U>(left: T, right: U) -> (T, U) {
    return (left, right)
}

public func >*< <T: CRMappingKey, U>(left: T, right: U) -> (CRMappingKey, U) {
    return (left, right)
}

infix operator <- { associativity right }

// MARK:- Objects with Basic types

/// Object of Basic type
public func <- <T: JSONable, C: CRMappingContext>(inout field: T, map:(key: CRMappingKey, context: C)) -> C {
    
    if case .Error(_)? = map.context.result {
        return map.context
    }
    
    switch map.context.dir {
    case .ToJSON:
        let json = map.context.json
        let result = mapToJson(json, fromField: field, viaKey: map.key)
        
        switch result {
        case .Value(let json):
            map.context.json = json
            map.context.result = Result.Value(json)
        case .Error(let error):
            map.context.result = Result.Error(error)
        }
    case .FromJSON:
        let baseJSON = map.context.json[map.key]
        map.context.result = mapFromJson(baseJSON, toField: &field)
    }
    
    return map.context
}

func mapToJson<T: JSON>(var json: JSONValue, fromField field: T, viaKey key: CRMappingKey) -> Result<JSONValue> {
    
//    print(key)
//    json[key] = [ " fuck", " you" ]
//    print(json)
    
    let result = T.toJSON(field)
    switch result {
    case .Value(let val):
        
        switch val {
        case .JSONObject(let obj):
            break
        default: break
            
        }
        json[key] = val
        return Result.Value(json)
    case .Error(_):
        return result
    }
}

/// Map to JSON with field as optional type.
func mapToJson<T: JSON>(var json: JSONValue, fromField field: T?, viaKey key: CRMappingKey) -> Result<JSONValue> {
    
    if let field = field {
        return mapToJson(json, fromField: field, viaKey: key)
    } else {
        json[key] = JSON(NSNull)
        return Result.Value(json)
    }
}

// TODO: Have a map for optional fields. .Null will map to `nil`.
func mapFromJson<T: JSON>(json: JSONValue, inout toField field: T) -> Result<Any>? {
    
    // TODO: Clarify our errors.
    let error: NSError = NSError(domain: "CRMappingDomain", code: -1, userInfo: nil)
    
    if let fromJson = T.fromJSON(json) {
        field = fromJson as! T
    } else {
        
    }
    
    switch field {
    case is Bool:
        if let rawBool = json.bool {
            field = rawBool as! T
        } else {
            return Result.Error(error)
        }
    case is Int:
        if let rawInt = json.number {
            field = rawInt as! T
        } else {
            return Result.Error(error)
        }
    case is NSNumber:
        if let rawNumber = json.number {
            field = rawNumber as! T
        } else {
            return Result.Error(error)
        }
    case is String:
        if let rawString = json.string {
            field = rawString as! T
        } else {
            return Result.Error(error)
        }
    case is Float:
        if let rawFloat = json.float {
            field = rawFloat as! T
        } else {
            return Result.Error(error)
        }
    case is Double:
        if let rawDouble = json.double {
            field = rawDouble as! T
        } else {
            return Result.Error(error)
        }
    case is Array<CRFieldType>:
        if let rawArray = json.array {
            field = rawArray as! T
        } else {
            return Result.Error(error)
        }
    case is Dictionary<String, CRFieldType>:
        if let rawDictionary = json.dictionary {
            field = rawDictionary as! T
        } else {
            return Result.Error(error)
        }
    default:
        return Result.Error(error)
    }
    
    return nil
}
