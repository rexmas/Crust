import Foundation
import JSONValueRX

// MARK: - Merge right into tuple operator definition

infix operator >*< : AssignmentPrecedence

public func >*< <T, U>(left: T, right: U) -> (T, U) {
    return (left, right)
}

// MARK: - Map value operator definition

infix operator <- : AssignmentPrecedence

// MARK: - Map a JSONable.

@discardableResult
public func <- <T: JSONable, K: MappingKey, MC: MappingPayload<K>>(field: inout T, keyPath:(key: K, payload: MC)) -> MC where T == T.ConversionType {
    return map(to: &field, via: keyPath)
}

@discardableResult
public func <- <T: JSONable, K: MappingKey, MC: MappingPayload<K>>(field: inout T?, keyPath:(key: K, payload: MC)) -> MC where T == T.ConversionType {
    return map(to: &field, via: keyPath)
}

// MARK: - To JSON

private func shouldMapToJSON<KC: KeyCollection>(via key: KC.MappingKeyType, ifIn keys: KC) -> Bool {
    return keys.containsKey(key) || (key is RootKey)
}

private func map<T: JSONable, KC: KeyCollection>(to json: JSONValue, from field: T?, via key: KC.MappingKeyType, ifIn keys: KC) -> JSONValue where T == T.ConversionType {
    var json = json
    
    guard shouldMapToJSON(via: key, ifIn: keys) else {
        return json
    }
    
    if let field = field {
        json[key] = T.toJSON(field)
    }
    else {
        json[key] = .null()
    }
    
    return json
}

// MARK: - From JSON

private func map<T: JSONable>(from json: JSONValue, to field: inout T) throws where T.ConversionType == T {
    field = try map(from: json)
}

private func map<T: JSONable>(from json: JSONValue, to field: inout T?) throws where T.ConversionType == T {
    
    if case .null = json {
        field = nil
        return
    }
    
    field = try map(from: json)
}

private func map<T: JSONable>(from json: JSONValue) throws -> T where T.ConversionType == T {
    if let fromJson = T.fromJSON(json) {
        return fromJson
    }
    else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Conversion of JSON \(json.values()) to type \(T.self) failed" ]
        throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
    }
}

// MARK: - Map with a generic binding.

@discardableResult
public func <- <T, M: Mapping, K: MappingKey, MC: MappingPayload<K>>(field: inout T, binding:(key: Binding<K, M>, payload: MC)) -> MC where M.MappedObject == T {
    return map(to: &field, using: binding)
}

@discardableResult
public func <- <T, M: Mapping, K: MappingKey, MC: MappingPayload<K>>(field: inout T?, binding:(key: Binding<K, M>, payload: MC)) -> MC where M.MappedObject == T {
    return map(to: &field, using: binding)
}

// Transform.

@discardableResult
public func <- <T: JSONable, TF: Transform, K: MappingKey, MC: MappingPayload<K>>(field: inout T, binding:(key: Binding<K, TF>, payload: MC)) -> MC where TF.MappedObject == T, T == T.ConversionType {
    return map(to: &field, using: binding)
}

@discardableResult
public func <- <T: JSONable, TF: Transform, K: MappingKey, MC: MappingPayload<K>>(field: inout T?, binding:(key: Binding<K, TF>, payload: MC)) -> MC where TF.MappedObject == T, T == T.ConversionType {
    return map(to: &field, using: binding)
}

// MARK: - Mapping.

/// - returns: The json to be used from mapping keyed by `key`, or `nil` if `key` is not in `keys`, or throws and error.
internal func baseJSON<KC: KeyCollection>(from json: JSONValue, via key: KC.MappingKeyType, ifIn keys: KC) throws -> JSONValue? {
    guard !(key is RootKey) else {
        return json
    }
    
    guard keys.containsKey(key) else {
        return nil
    }
    
    let baseJSON = json[key]
    
    if baseJSON == nil && key.keyPath == "" {
        return json
    }
    else if baseJSON == nil {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON does not have data at key path \(key.keyPath) from key \(key) to map from" ]
        throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
    }
    
    return baseJSON
}

// Arbitrary object.
public func map<T: JSONable, K: MappingKey, MC: MappingPayload<K>>(to field: inout T, via keyPath:(key: K, payload: MC)) -> MC where T == T.ConversionType {
    
    let payload = keyPath.payload
    let key = keyPath.key
    
    guard payload.error == nil else {
        return payload
    }
    
    switch payload.dir {
    case .toJSON:
        let json = payload.json
        keyPath.payload.json = Crust.map(to: json, from: field, via: key, ifIn: payload.keys)
    case .fromJSON:
        do {
            guard let baseJSON = try baseJSON(from: payload.json, via: key, ifIn: payload.keys) else {
                return payload
            }
            
            try map(from: baseJSON, to: &field)
        }
        catch let error as NSError {
            payload.error = error
        }
    }
    
    return payload
}

// Arbitrary Optional.
public func map<T: JSONable, K: MappingKey, MC: MappingPayload<K>>(to field: inout T?, via keyPath:(key: K, payload: MC)) -> MC where T == T.ConversionType {
    
    let payload = keyPath.payload
    let key = keyPath.key
    
    guard payload.error == nil else {
        return payload
    }
    
    switch payload.dir {
    case .toJSON:
        let json = payload.json
        payload.json = Crust.map(to: json, from: field, via: key, ifIn: payload.keys)
    case .fromJSON:
        do {
            guard let baseJSON = try baseJSON(from: payload.json, via: key, ifIn: payload.keys) else {
                return payload
            }
            
            try map(from: baseJSON, to: &field)
        }
        catch let error as NSError {
            payload.error = error
        }
    }
    
    return payload
}

// Mapping.
public func map<T, M: Mapping, K: MappingKey, MC: MappingPayload<K>>(to field: inout T, using binding:(key: Binding<K, M>, payload: MC)) -> MC where M.MappedObject == T {
    
    let payload = binding.payload
    let binding = binding.key
    
    guard payload.error == nil else {
        return payload
    }
    
    guard case .mapping(let key, let mapping) = binding else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Expected KeyExtension.mapping to map type \(T.self)" ]
        payload.error = NSError(domain: CrustMappingDomain, code: -1000, userInfo: userInfo)
        return payload
    }
    
    do {
        guard let keyedBinding = try KeyedBinding(binding: binding, payload: payload) else {
            return payload
        }
        
        switch payload.dir {
        case .toJSON:
            let json = payload.json
            payload.json = try Crust.map(to: json, from: field, via: key, ifIn: payload.keys, using: mapping, keyedBy: keyedBinding.codingKeys)
        case .fromJSON:
            guard let baseJSON = try baseJSON(from: payload.json, via: key, ifIn: payload.keys) else {
                return payload
            }
            
            try map(from: baseJSON, to: &field, using: mapping, keyedBy: keyedBinding.codingKeys, payload: payload)
        }
    }
    catch let error {
        payload.error = error
    }
    
    return payload
}

public func map<T, M: Mapping, K: MappingKey, MC: MappingPayload<K>>(to field: inout T?, using binding:(key: Binding<K, M>, payload: MC)) -> MC where M.MappedObject == T {
    
    let payload = binding.payload
    let binding = binding.key
    
    guard payload.error == nil else {
        return payload
    }
    
    guard case .mapping(let key, let mapping) = binding else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Expected KeyExtension.mapping to map type \(T.self)" ]
        payload.error = NSError(domain: CrustMappingDomain, code: -1000, userInfo: userInfo)
        return payload
    }
    
    do {
        guard let keyedBinding = try KeyedBinding(binding: binding, payload: payload) else {
            return payload
        }
        
        switch payload.dir {
        case .toJSON:
            let json = payload.json
            payload.json = try Crust.map(to: json, from: field, via: key, ifIn: payload.keys, using: mapping, keyedBy: keyedBinding.codingKeys)
        case .fromJSON:
            guard let baseJSON = try baseJSON(from: payload.json, via: key, ifIn: payload.keys) else {
                return payload
            }
            
            try map(from: baseJSON, to: &field, using: mapping, keyedBy: keyedBinding.codingKeys, payload: payload)
        }
    }
    catch let error {
        payload.error = error
    }
    
    return payload
}

// MARK: - To JSON

private func map<T, M: Mapping, KC: KeyCollection>(to json: JSONValue, from field: T?, via key: KC.MappingKeyType, ifIn keys: KC, using mapping: M, keyedBy nestedKeys: AnyKeyCollection<M.MappingKeyType>) throws -> JSONValue where M.MappedObject == T {
    var json = json
    
    guard shouldMapToJSON(via: key, ifIn: keys) else {
        return json
    }
    
    guard let field = field else {
        json[key] = .null()
        return json
    }
        
    json[key] = try Mapper().mapFromObjectToJSON(field, mapping: mapping, keyedBy: nestedKeys)
    return json
}

// MARK: - From JSON

private func map<T, M: Mapping, K: MappingKey>(from json: JSONValue, to field: inout T, using mapping: M, keyedBy keys: AnyKeyCollection<M.MappingKeyType>, payload: MappingPayload<K>) throws where M.MappedObject == T {
    
    let mapper = Mapper()
    field = try mapper.map(from: json, using: mapping, keyedBy: keys, parentContext: payload)
}

private func map<T, M: Mapping, K: MappingKey>(from json: JSONValue, to field: inout T?, using mapping: M, keyedBy keys: AnyKeyCollection<M.MappingKeyType>, payload: MappingPayload<K>) throws where M.MappedObject == T {
    
    if case .null = json {
        field = nil
        return
    }
    
    let mapper = Mapper()
    field = try mapper.map(from: json, using: mapping, keyedBy: keys, parentContext: payload)
}

// MARK: - RangeReplaceableCollection (Array and Realm List follow this protocol).

/// The set of functions required to perform uniquing when inserting objects into a collection.
public typealias UniquingFunctions<T, RRC: RangeReplaceableCollection> = (
    elementEquality: ((T) -> (T) -> Bool),
    indexOf: ((RRC) -> (T) -> RRC.Index?),
    contains: ((RRC) -> (T) -> Bool)
)

/// This handles the case where our Collection contains Equatable objects, and thus can be uniqued during insertion and deletion.
@discardableResult
public func <- <T, M: Mapping, K: MappingKey, MC: MappingPayload<K>, RRC: RangeReplaceableCollection>(field: inout RRC, binding:(key: Binding<K, M>, payload: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject, T: Equatable {
    
    return map(toCollection: &field, using: binding)
}

/// This is for Collections with non-Equatable objects.
@discardableResult
public func <- <T, M: Mapping, K: MappingKey, MC: MappingPayload<K>, RRC: RangeReplaceableCollection>(field: inout RRC, binding:(key: Binding<K, M>, payload: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject {
    
    return map(toCollection: &field, using: binding, uniquing: nil)
}

//// Optional types.

@discardableResult
public func <- <T, M: Mapping, K: MappingKey, MC: MappingPayload<K>, RRC: RangeReplaceableCollection>(field: inout RRC?, binding:(key: Binding<K, M>, payload: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject, T: Equatable {
    
    return map(toCollection: &field, using: binding, uniquing: RRC.defaultUniquingFunctions())
}

/// This is for Collections with non-Equatable objects.
@discardableResult
public func <- <M: Mapping, K: MappingKey, MC: MappingPayload<K>, RRC: RangeReplaceableCollection>(field: inout RRC?, binding:(key: Binding<K, M>, payload: MC)) -> MC where RRC.Iterator.Element == M.MappedObject {
    
    return map(toCollection: &field, using: binding, uniquing: nil)
}

/// Map into a `RangeReplaceableCollection` with `Equatable` `Element`.
@discardableResult
public func map<T, M: Mapping, K: MappingKey, MC: MappingPayload<K>, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC,
     using binding:(key: Binding<K, M>, payload: MC))
    -> MC
    where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject, T: Equatable {
        
        return map(toCollection: &field, using: binding, uniquing: RRC.defaultUniquingFunctions())
}

/// General function for mapping JSON into a `RangeReplaceableCollection`.
///
/// Providing uniqing functions for equality comparison, fetching by index, and checking existence of elements allows
/// for uniquing during insertion (merging/eliminating duplicates).
@discardableResult
public func map<M: Mapping, K: MappingKey, MC: MappingPayload<K>, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC,
     using binding:(key: Binding<K, M>, payload: MC),
     uniquing: UniquingFunctions<M.MappedObject, RRC>?)
    -> MC
    where RRC.Iterator.Element == M.MappedObject {
        
        let payload = binding.payload
        let binding = binding.key
        
        do {
            guard let keyedBinding = try KeyedBinding(binding: binding, payload: payload) else {
                return payload
            }
            
            switch payload.dir {
            case .toJSON:
                let json = payload.json
                payload.json = try Crust.map(to: json, from: field, via: binding.key, using: binding.mapping, ifIn: payload.keys,
                                                     keyedBy: keyedBinding.codingKeys)
                
            case .fromJSON:
                try mapFromJSON(toCollection: &field, using: (keyedBinding, payload), uniquing: uniquing)
            }
        }
        catch let error {
            payload.error = error
        }
        
        return payload
}

@discardableResult
public func map<M: Mapping, K: MappingKey, MC: MappingPayload<K>, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC?,
     using binding:(key: Binding<K, M>, payload: MC),
     uniquing: UniquingFunctions<M.MappedObject, RRC>?)
    -> MC
    where RRC.Iterator.Element == M.MappedObject {
        
        let payload = binding.payload
        let binding = binding.key
        
        do {
            guard let keyedBinding = try KeyedBinding(binding: binding, payload: payload) else {
                return payload
            }
            
            let json = payload.json
            guard let baseJSON = try baseJSONForCollection(json: json, via: keyedBinding.binding.key, ifIn: payload.keys) else {
                return payload
            }
            
            switch payload.dir {
            case .toJSON:
                switch field {
                case .some(_):
                    try payload.json = Crust.map(
                        to: json,
                        from: field!,
                        via: binding.key,
                        using: binding.mapping,
                        ifIn: payload.keys,
                        keyedBy: keyedBinding.codingKeys)
                case .none:
                    payload.json = .null()
                }
                
            case .fromJSON:
                if field == nil {
                    field = RRC()
                }
                // Have to use `!` here or we'll be writing to a copy of `field`. Also, must go through mapping
                // even in "null" case to handle deletes.
                try mapFromJSON(toCollection: &field!, using: (keyedBinding, payload), uniquing: uniquing)
                
                if case .null() = baseJSON {
                    field = nil
                }
            }
        }
        catch let error as NSError {
            payload.error = error
        }
        
        return payload
}

/// Our top level mapping function for mapping from a sequence/collection to JSON.
private func map<T, M: Mapping, KC: KeyCollection, S: Sequence>(
    to json: JSONValue,
    from field: S,
    via key: KC.MappingKeyType,
    using mapping: M,
    ifIn parentKeys: KC,
    keyedBy nestedKeys: AnyKeyCollection<M.MappingKeyType>)
    throws -> JSONValue
    where M.MappedObject == T, S.Iterator.Element == T {
        
        var json = json
        
        guard shouldMapToJSON(via: key, ifIn: parentKeys) else {
            return json
        }
        
        let results = try field.map {
            try Mapper().mapFromObjectToJSON($0, mapping: mapping, keyedBy: nestedKeys)
        }
        json[key] = .array(results)
        
        return json
}

/// Our top level mapping function for mapping from JSON into a collection.
private func mapFromJSON<M: Mapping, K: MappingKey, MC: MappingPayload<K>, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC,
     using binding:(key: KeyedBinding<K, M>, payload: MC),
     uniquing: UniquingFunctions<M.MappedObject, RRC>?) throws
    where RRC.Iterator.Element == M.MappedObject {
        
        let keyedBinding = binding.key
        let mapping = keyedBinding.binding.mapping
        let parentContext = binding.payload
        
        guard parentContext.error == nil else {
            throw parentContext.error!
        }
        
        guard let baseJSON = try baseJSONForCollection(json: parentContext.json, via: keyedBinding.binding.key, ifIn: parentContext.keys) else {
            return
        }
        
        // Generate an extra sub-payload so that we batch our array operations to the Adapter.
        let payload = MappingPayload<K>(withObject: parentContext.object, json: parentContext.json, keys: parentContext.keys, adapterType: mapping.adapter.dataBaseTag, direction: MappingDirection.fromJSON)
        payload.parent = parentContext.typeErased()
        
        try mapping.start(payload: payload)
        
        let fieldCopy = field
        let contains = uniquing?.contains(fieldCopy) ?? { _ in false }
        let elementEquality = uniquing?.elementEquality ?? { _ in { _ in false } }
        let updatePolicy = keyedBinding.binding.collectionUpdatePolicy
        let codingKeys = keyedBinding.codingKeys
        let optionalNewValues = try generateNewValues(fromJsonArray: baseJSON,
                                                      with: updatePolicy,
                                                      using: mapping,
                                                      codingKeys: codingKeys,
                                                      newValuesContains: elementEquality,
                                                      fieldContains: contains,
                                                      payload: payload)
        
        let newValues = try transform(newValues: optionalNewValues, via: keyedBinding.binding.keyPath, forUpdatePolicyNullability: keyedBinding.binding.collectionUpdatePolicy)
        
        try insert(into: &field, newValues: newValues, using: mapping, updatePolicy: keyedBinding.binding.collectionUpdatePolicy, indexOf: uniquing?.indexOf)
        
        try mapping.completeMapping(objects: field, payload: payload)
}

/// Handles null JSON values. Only nullable collections do not error on null (newValues == nil).
private func transform<T, K: MappingKey>(
    newValues: [T]?,
    via key: K,
    forUpdatePolicyNullability updatePolicy: CollectionUpdatePolicy<T>)
    throws -> [T] {
    
    if let newValues = newValues {
        return newValues
    }
    else if updatePolicy.nullable {
        return []
    }
    else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Attempting to assign \"null\" to non-nullable collection on type \(T.self) using JSON at key path \(key.keyPath) from \(key) is not allowed. Please change the `CollectionUpdatePolicy` for this mapping to have `nullable: true`" ]
        throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
    }
}

/// Inserts final mapped values into the collection.
private func insert<M: Mapping, RRC: RangeReplaceableCollection>
    (into field: inout RRC,
     newValues: [M.MappedObject],
     using mapping: M,
     updatePolicy: CollectionUpdatePolicy<M.MappedObject>,
     indexOf: ((RRC) -> (M.MappedObject) -> RRC.Index?)?)
    throws
    where RRC.Iterator.Element == M.MappedObject {
    
        switch updatePolicy.insert {
        case .append:
            field.append(contentsOf: newValues)
            
        case .replace(delete: let deletionBlock):
            var orphans: RRC = field
            
            if let deletion = deletionBlock {
                // Check if any of our newly mapped objects previously existed in our collection
                // and prune them from orphans, because in which case, we don't want to delete them.
                if let indexOfFunc = indexOf {
                    newValues.forEach {
                        if let index = indexOfFunc(orphans)($0) {
                            orphans.remove(at: index)
                        }
                    }
                }
                
                // Unfortunately `AnyCollection<U.MappedObject>(orphans)` gives us "type is ambiguous without more payload".
                let arrayOrphans = Array(orphans)
                let shouldDelete = AnyCollection<M.MappedObject>(arrayOrphans)
                try deletion(shouldDelete).forEach {
                    try mapping.delete(obj: $0)
                }
            }
            
            field.removeAll(keepingCapacity: true)
            field.append(contentsOf: newValues)
        }
}

private func baseJSONForCollection<KC: KeyCollection>(json: JSONValue, via key: KC.MappingKeyType, ifIn keys: KC) throws -> JSONValue? {
    guard !(key is RootKey) else {
        return json
    }
    
    guard keys.containsKey(key) else {
        return nil
    }
    
    let baseJSON = json[key]
    
    // Walked an empty keypath, return the whole json payload if it's an empty array since subscripting on a json array calls `map`.
    // TODO: May be simpler to support `nil` keyPaths.
    if case .some(.array(let arr)) = baseJSON, key.keyPath == "", arr.count == 0 {
        return json
    }
    else if let baseJSON = baseJSON {
        return baseJSON
    }
    else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(key.keyPath) from key \(key) does not exist to map from" ]
        throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
    }
}

/// Generates and returns our new set of values from the JSON that will later be inserted into the collection
/// we're mapping into.
///
/// - returns: The array of mapped values, `nil` if JSON is "null".
private func generateNewValues<T, M: Mapping, K: MappingKey>(
    fromJsonArray json: JSONValue,
    with updatePolicy: CollectionUpdatePolicy<M.MappedObject>,
    using mapping: M,
    codingKeys: AnyKeyCollection<M.MappingKeyType>,
    newValuesContains: @escaping (T) -> (T) -> Bool,
    fieldContains: (T) -> Bool,
    payload: MappingPayload<K>)
    throws -> [T]?
    where M.MappedObject == T {
        
        if case .null() = json, updatePolicy.nullable {
            return nil
        }
    
        guard case .array(let jsonArray) = json else {
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "Trying to map json of type \(type(of: json)) to Collection of <\(T.self)>" ]
            throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
        }
        
        let mapper = Mapper()
        
        let isUnique = { (val: T, newValues: [T], fieldContains: (T) -> Bool) -> Bool in
            let newValuesContainsVal = newValues.contains(where: newValuesContains(val))
            
            switch updatePolicy.insert {
            case .replace(_):
                return !newValuesContainsVal
            case .append:
                return !(newValuesContainsVal || fieldContains(val))
            }
        }
        
        var newValues = [T]()
        
        for json in jsonArray {
            let val = try mapper.map(from: json, using: mapping, keyedBy: codingKeys, parentContext: payload)
            
            if updatePolicy.unique {
                if isUnique(val, newValues, fieldContains) {
                    newValues.append(val)
                }
            }
            else {
                newValues.append(val)
            }
        }
        
        return newValues
}
