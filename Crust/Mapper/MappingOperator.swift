import Foundation

// MARK: - Merge right into tuple operator definition

infix operator >*< { associativity right }

public func >*< <T, U>(left: T, right: U) -> (T, U) {
    return (left, right)
}

public func >*< <T: JSONKeypath, U>(left: T, right: U) -> (JSONKeypath, U) {
    return (left, right)
}

// MARK: - Map value operator definition

infix operator <- { associativity right }

public func <- <T: JSONable, C: MappingContext where T == T.J>(inout field: T, map:(key: JSONKeypath, context: C)) -> C {
    return mapField(&field, map: map)
}

// NOTE: Must supply two separate versions for optional and non-optional types or we'll have to continuously
// guard against unsafe nil assignments.

public func <- <T: JSONable, C: MappingContext where T == T.J>(inout field: T?, map:(key: JSONKeypath, context: C)) -> C {
    return mapField(&field, map: map)
}

// MARK: - Map value funcs

public func mapField<T: JSONable, C: MappingContext where T == T.J>(inout field: T?, map:(key: JSONKeypath, context: C)) -> C {
    
    guard map.context.error == nil else {
        return map.context
    }
    
    switch map.context.dir {
    case .ToJSON:
        let json = map.context.json
        map.context.json = mapToJson(json, fromField: field, viaKey: map.key)
    case .FromJSON:
        do {
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: &field)
            } else {
                throw NSError(domain: "", code: 0, userInfo: nil)
            }
        } catch let error as NSError {
            map.context.error = error
        }
    }
    
    return map.context
}

public func mapField<T: JSONable, C: MappingContext where T == T.J>(inout field: T, map:(key: JSONKeypath, context: C)) -> C {
    
    guard map.context.error == nil else {
        return map.context
    }
    
    switch map.context.dir {
    case .ToJSON:
        let json = map.context.json
        map.context.json = mapToJson(json, fromField: field, viaKey: map.key)
    case .FromJSON:
        do {
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: &field)
            } else {
                throw NSError(domain: "", code: 0, userInfo: nil)
            }
        } catch let error as NSError {
            map.context.error = error
        }
    }
    
    return map.context
}

private func mapToJson<T: JSONable where T == T.J>(var json: JSONValue, fromField field: T?, viaKey key: JSONKeypath) -> JSONValue {
    
    if let field = field {
        json[key] = T.toJSON(field)
    } else {
        json[key] = .JSONNull()
    }
    
    return json
}

private func mapFromJson<T: JSONable where T.J == T>(json: JSONValue, inout toField field: T) throws {
    
    if let fromJson = T.fromJSON(json) {
        field = fromJson
    } else {
        throw NSError(domain: "CRMappingDomain", code: -1, userInfo: nil)
    }
}

private func mapFromJson<T: JSONable where T.J == T>(json: JSONValue, inout toField field: T?) throws {
    
    if case .JSONNull = json {
        field = nil
        return
    }
    
    if let fromJson = T.fromJSON(json) {
        field = fromJson
    } else {
        throw NSError(domain: "CRMappingDomain", code: -1, userInfo: nil)
    }
}
