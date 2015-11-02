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

// Map arbitrary object.
public func <- <T: JSONable, C: MappingContext where T == T.J>(inout field: T, map:(key: JSONKeypath, context: C)) -> C {
    return mapField(&field, map: map)
}

// Map a Mappable.
public func <- <T: Mappable, U: Mapping, C: MappingContext where U.MappedObject == T>(inout field: T, map:(key: KeyExtensions<U>, context: C)) -> C {
    return mapField(&field, map: map)
}

// NOTE: Must supply two separate versions for optional and non-optional types or we'll have to continuously
// guard against unsafe nil assignments.

public func <- <T: JSONable, C: MappingContext where T == T.J>(inout field: T?, map:(key: JSONKeypath, context: C)) -> C {
    return mapField(&field, map: map)
}

public func <- <T: Mappable, U: Mapping, C: MappingContext where U.MappedObject == T>(inout field: T?, map:(key: KeyExtensions<U>, context: C)) -> C {
    return mapField(&field, map: map)
}

// MARK: - Map funcs

// Arbitrary object.
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

// Arbitrary Optional.
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

// Mappable.
public func mapField<T: Mappable, U: Mapping, C: MappingContext where U.MappedObject == T>(inout field: T, map:(key: KeyExtensions<U>, context: C)) -> C {
    
    guard map.context.error == nil else {
        return map.context
    }
    
    guard case .Mapping(let key, let mapping) = map.key else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Must provide a KeyExtension.Mapping to map a List" ]
        map.context.error = NSError(domain: "CRMappingDomain", code: -1000, userInfo: userInfo)
        return map.context
    }
    
    do {
        switch map.context.dir {
        case .ToJSON:
            let json = map.context.json
            try map.context.json = mapToJson(json, fromField: field, viaKey: key, mapping: mapping)
        case .FromJSON:
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: &field, mapping: mapping)
            } else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(map.key) does not exist to map from" ]
                throw NSError(domain: "CRMappingDomain", code: 0, userInfo: userInfo)
            }
        }
    } catch let error as NSError {
        map.context.error = error
    }
    
    return map.context
}

// TODO: Maybe we can just make Optional: Mappable and then this redudancy can safely go away...
public func mapField<T: Mappable, U: Mapping, C: MappingContext where U.MappedObject == T>(inout field: T?, map:(key: KeyExtensions<U>, context: C)) -> C {
    
    guard map.context.error == nil else {
        return map.context
    }
    
    guard case .Mapping(let key, let mapping) = map.key else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Expected KeyExtension.Mapping to map type \(T.type)" ]
        map.context.error = NSError(domain: "CRMappingDomain", code: -1000, userInfo: userInfo)
        return map.context
    }
    
    do {
        switch map.context.dir {
        case .ToJSON:
            let json = map.context.json
            try map.context.json = mapToJson(json, fromField: field, viaKey: key, mapping: mapping)
        case .FromJSON:
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: &field, mapping: mapping)
            } else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(map.key) does not exist to map from" ]
                throw NSError(domain: "CRMappingDomain", code: 0, userInfo: userInfo)
            }
        }
    } catch let error as NSError {
        map.context.error = error
    }
    
    return map.context
}

// MARK: - To JSON

private func mapToJson<T: JSONable where T == T.J>(var json: JSONValue, fromField field: T?, viaKey key: JSONKeypath) -> JSONValue {
    
    if let field = field {
        json[key] = T.toJSON(field)
    } else {
        json[key] = .JSONNull()
    }
    
    return json
}

private func mapToJson<T: Mappable, U: Mapping where U.MappedObject == T>(var json: JSONValue, fromField field: T?, viaKey key: CRMappingKey, mapping: U) throws -> JSONValue {
    
    guard let field = field else {
        json[key] = .JSONNull()
        return json
    }
    
    json[key] = try CRMapper<T, U>().mapFromObjectToJSON(field, mapping: mapping)
    return json
}

// MARK: - From JSON

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

private func mapFromJson<T: Mappable, U: Mapping where U.MappedObject == T>(json: JSONValue, inout toField field: T, mapping: U) throws {
    
    let mapper = CRMapper<T, U>()
    field = try mapper.mapFromJSONToNewObject(json, mapping: mapping)
}

private func mapFromJson<T: Mappable, U: Mapping where U.MappedObject == T>(json: JSONValue, inout toField field: T?, mapping: U) throws {
    
    if case .JSONNull = json {
        field = nil
        return
    }
    
    let mapper = CRMapper<T, U>()
    field = try mapper.mapFromJSONToNewObject(json, mapping: mapping)
}

// MARK: - RangeReplaceableCollectionType (Array and List follow this protocol)

public func <- <T: Mappable, U: Mapping, V: RangeReplaceableCollectionType, C: MappingContext where U.MappedObject == T, V.Generator.Element == T>(inout field: V, map:(key: KeyExtensions<U>, context: C)) -> C {
    
    return mapField(&field, map: map)
}

public func mapField<T: Mappable, U: Mapping, V: RangeReplaceableCollectionType, C: MappingContext where U.MappedObject == T, V.Generator.Element == T>(inout field: V, map:(key: KeyExtensions<U>, context: C)) -> C {
    
    guard map.context.error == nil else {
        return map.context
    }
    
    guard case .Mapping(let key, let mapping) = map.key else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Must provide a KeyExtension.Mapping to map a \(V.self)" ]
        map.context.error = NSError(domain: "CRMappingDomain", code: -1000, userInfo: userInfo)
        return map.context
    }
    
    do {
        switch map.context.dir {
        case .ToJSON:
            let json = map.context.json
            try map.context.json = mapToJson(json, fromField: field, viaKey: key, mapping: mapping)
        case .FromJSON:
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: &field, mapping: mapping)
            } else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(map.key) does not exist to map from" ]
                throw NSError(domain: "CRMappingDomain", code: 0, userInfo: userInfo)
            }
        }
    } catch let error as NSError {
        map.context.error = error
    }
    
    return map.context
}

private func mapToJson<T: Mappable, U: Mapping, V: RangeReplaceableCollectionType where U.MappedObject == T, V.Generator.Element == T>(var json: JSONValue, fromField field: V, viaKey key: CRMappingKey, mapping: U) throws -> JSONValue {
    
    let results = try field.map {
        try CRMapper<T, U>().mapFromObjectToJSON($0, mapping: mapping)
    }
    json[key] = .JSONArray(results)
    
    return json
}

private func mapFromJson<T: Mappable, U: Mapping, V: RangeReplaceableCollectionType where U.MappedObject == T, V.Generator.Element == T>(json: JSONValue, inout toField field: V, mapping: U) throws {
    
    if case .JSONArray(let xs) = json {
        let mapper = CRMapper<T, U>()
        let results = try xs.map {
            try mapper.mapFromJSONToNewObject($0, mapping: mapping)
        }
        field.appendContentsOf(results)
    } else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Trying to map json of type \(json.dynamicType) to \(V.self)<\(T.self)>" ]
        throw NSError(domain: "CRMappingDomain", code: -1, userInfo: userInfo)
    }
}


