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
public func <- <T: JSONable, K: Keypath, MC: MappingContext<K>>(field: inout T, keyPath:(key: K, context: MC)) -> MC where T == T.ConversionType {
    return map(to: &field, via: (keyPath, keyPath.context))
}

@discardableResult
public func <- <T: JSONable, K: Keypath, MC: MappingContext<K>>(field: inout T?, keyPath:(key: K, context: MC)) -> MC where T == T.ConversionType {
    return map(to: &field, via: (keyPath, keyPath.context))
}

// MARK: - To JSON

private func shouldMapToJSON<K: Keypath>(via keyPath: K, ifIn keys: Set<K>) -> Bool {
    return keys.contains(keyPath) || (keyPath is RootKeyPath)
}

private func map<T: JSONable, K: Keypath>(to json: JSONValue, from field: T?, via key: JSONKeypath, ifIn keys: Set<K>) -> JSONValue where T == T.ConversionType {
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
public func <- <T, M: Mapping, K: Keypath, MC: MappingContext<K>>(field: inout T, binding:(key: Binding<K, M>, context: MC)) -> MC where M.MappedObject == T {
    return map(to: &field, using: binding)
}

@discardableResult
public func <- <T, M: Mapping, K: Keypath, MC: MappingContext<K>>(field: inout T?, binding:(key: Binding<K, M>, context: MC)) -> MC where M.MappedObject == T {
    return map(to: &field, using: binding)
}

// Transform.

@discardableResult
public func <- <T: JSONable, TF: Transform, K: Keypath, MC: MappingContext<K>>(field: inout T, binding:(key: Binding<K, TF>, context: MC)) -> MC where TF.MappedObject == T, T == T.ConversionType {
    return map(to: &field, using: binding)
}

@discardableResult
public func <- <T: JSONable, TF: Transform, K: Keypath, MC: MappingContext<K>>(field: inout T?, binding:(key: Binding<K, TF>, context: MC)) -> MC where TF.MappedObject == T, T == T.ConversionType {
    return map(to: &field, using: binding)
}

// MARK: - Mapping.

/// - returns: The json to be used from mapping keyed by `keyPath`, or `nil` if `keyPath` is not in `keys`, or throws and error.
internal func baseJSON<K: Keypath>(from json: JSONValue, via keyPath: K, ifIn keys: Set<K>) throws -> JSONValue? {
    
    guard keys.contains(keyPath) else {
        return nil
    }
    
    guard !(keyPath is RootKeyPath) else {
        return json
    }
    
    let baseJSON = json[keyPath]
    
    // TODO: Test to get rid of this now that we have `RootKeyPath`.
    if baseJSON == nil && keyPath.keyPath == "" {
        return json
    }
    else if baseJSON == nil {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON does not have key path \(keyPath) to map from" ]
        throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
    }
    
    return baseJSON
}

// Arbitrary object.
public func map<T: JSONable, K: Keypath, MC: MappingContext<K>>(to field: inout T, via keyPath:(key: K, context: MC)) -> MC where T == T.ConversionType {
    
    let context = keyPath.context
    let key = keyPath.key
    
    guard context.error == nil else {
        return context
    }
    
    switch context.dir {
    case .toJSON:
        let json = context.json
        keyPath.context.json = Crust.map(to: json, from: field, via: key, ifIn: context.keys)
    case .fromJSON:
        do {
            guard let baseJSON = try baseJSON(from: context.json, via: key, ifIn: context.keys) else {
                return context
            }
            
            try map(from: baseJSON, to: &field)
        }
        catch let error as NSError {
            context.error = error
        }
    }
    
    return context
}

// Arbitrary Optional.
public func map<T: JSONable, K: Keypath, MC: MappingContext<K>>(to field: inout T?, via keyPath:(key: K, context: MC)) -> MC where T == T.ConversionType {
    
    let context = keyPath.context
    let key = keyPath.key
    
    guard context.error == nil else {
        return context
    }
    
    switch context.dir {
    case .toJSON:
        let json = context.json
        context.json = Crust.map(to: json, from: field, via: key, ifIn: context.keys)
    case .fromJSON:
        do {
            guard let baseJSON = try baseJSON(from: context.json, via: key, ifIn: context.keys) else {
                return context
            }
            
            try map(from: baseJSON, to: &field)
        }
        catch let error as NSError {
            context.error = error
        }
    }
    
    return context
}

// Mapping.
public func map<T, M: Mapping, K: Keypath, MC: MappingContext<K>>(to field: inout T, using binding: KeyedBinding<K, M>, context: MC) -> MC where M.MappedObject == T {
    
    guard context.error == nil else {
        return context
    }
    
    guard case .mapping(let key, let mapping) = binding.binding else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Expected KeyExtension.mapping to map type \(T.self)" ]
        context.error = NSError(domain: CrustMappingDomain, code: -1000, userInfo: userInfo)
        return context
    }
    
    do {
        switch context.dir {
        case .toJSON:
            let json = context.json
            context.json = try Crust.map(to: json, from: field, via: key, ifIn: context.keys, using: mapping, keyedBy: binding.codingKeys)
        case .fromJSON:
            guard let baseJSON = try baseJSON(from: context.json, via: key, ifIn: context.keys) else {
                return context
            }
            
            try map(from: baseJSON, to: &field, using: mapping, keyedBy: binding.codingKeys, context: context)
        }
    }
    catch let error {
        context.error = error
    }
    
    return context
}

public func map<T, M: Mapping, K: Keypath, MC: MappingContext<K>>(to field: inout T?, using binding: KeyedBinding<K, M>, context: MC) -> MC where M.MappedObject == T {
    
    guard context.error == nil else {
        return context
    }
    
    guard case .mapping(let key, let mapping) = binding.binding else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Expected KeyExtension.mapping to map type \(T.self)" ]
        context.error = NSError(domain: CrustMappingDomain, code: -1000, userInfo: userInfo)
        return context
    }
    
    do {
        switch context.dir {
        case .toJSON:
            let json = context.json
            context.json = try Crust.map(to: json, from: field, via: key, ifIn: context.keys, using: mapping, keyedBy: binding.codingKeys)
        case .fromJSON:
            guard let baseJSON = try baseJSON(from: context.json, via: key, ifIn: context.keys) else {
                return context
            }
            
            try map(from: baseJSON, to: &field, using: mapping, keyedBy: binding.codingKeys, context: context)
        }
    }
    catch let error {
        context.error = error
    }
    
    return context
}

// MARK: - To JSON

private func map<T, M: Mapping, K: Keypath>(to json: JSONValue, from field: T?, via key: K, ifIn keys: Set<K>, using mapping: M, keyedBy nestedKeys: Set<M.CodingKeys>) throws -> JSONValue where M.MappedObject == T {
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

private func map<T, M: Mapping, K: Keypath>(from json: JSONValue, to field: inout T, using mapping: M, keyedBy keys: Set<M.CodingKeys>, context: MappingContext<K>) throws where M.MappedObject == T {
    
    let mapper = Mapper()
    field = try mapper.map(from: json, using: mapping, keyedBy: keys, parentContext: context)
}

private func map<T, M: Mapping, K: Keypath>(from json: JSONValue, to field: inout T?, using mapping: M, keyedBy keys: Set<M.CodingKeys>, context: MappingContext<K>) throws where M.MappedObject == T {
    
    if case .null = json {
        field = nil
        return
    }
    
    let mapper = Mapper()
    field = try mapper.map(from: json, using: mapping, keyedBy: keys, parentContext: context)
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
public func <- <T, M: Mapping, K: Keypath, MC: MappingContext<K>, RRC: RangeReplaceableCollection>(field: inout RRC, binding:(key: Binding<K, M>, context: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject, T: Equatable {
    
    return map(toCollection: &field, using: binding)
}

/// This is for Collections with non-Equatable objects.
@discardableResult
public func <- <T, M: Mapping, K: Keypath, MC: MappingContext<K>, RRC: RangeReplaceableCollection>(field: inout RRC, binding:(key: Binding<K, M>, context: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject {
    
    return map(toCollection: &field, using: binding, uniquing: nil)
}

//// Optional types.

@discardableResult
public func <- <T, M: Mapping, K: Keypath, MC: MappingContext<K>, RRC: RangeReplaceableCollection>(field: inout RRC?, binding:(key: Binding<K, M>, context: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject, T: Equatable {
    
    return map(toCollection: &field, using: binding, uniquing: RRC.defaultUniquingFunctions())
}

/// This is for Collections with non-Equatable objects.
@discardableResult
public func <- <M: Mapping, K: Keypath, MC: MappingContext<K>, RRC: RangeReplaceableCollection>(field: inout RRC?, binding:(key: Binding<K, M>, context: MC)) -> MC where RRC.Iterator.Element == M.MappedObject {
    
    return map(toCollection: &field, using: binding, uniquing: nil)
}

/// Map into a `RangeReplaceableCollection` with `Equatable` `Element`.
@discardableResult
public func map<T, M: Mapping, K: Keypath, MC: MappingContext<K>, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC,
     using binding:(key: Binding<K, M>, context: MC))
    -> MC
    where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject, T: Equatable {
        
        return map(toCollection: &field, using: binding, uniquing: RRC.defaultUniquingFunctions())
}

/// General function for mapping JSON into a `RangeReplaceableCollection`.
///
/// Providing uniqing functions for equality comparison, fetching by index, and checking existence of elements allows
/// for uniquing during insertion (merging/eliminating duplicates).
@discardableResult
public func map<M: Mapping, K: Keypath, MC: MappingContext<K>, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC,
     using binding:(key: Binding<K, M>, context: MC),
     uniquing: UniquingFunctions<M.MappedObject, RRC>?)
    -> MC
    where RRC.Iterator.Element == M.MappedObject {
    
    do {
        switch binding.context.dir {
        case .toJSON:
            let json = binding.context.json
            binding.context.json = try Crust.map(to: json, from: field, via: binding.key.key, using: binding.key.mapping, ifIn: context.keys,
                                                 keyedBy: extractedKeys)
            
        case .fromJSON:
            try mapFromJSON(toCollection: &field, using: binding, uniquing: uniquing)
        }
    }
    catch let error {
        binding.context.error = error
    }
    
    return binding.context
}

@discardableResult
public func map<M: Mapping, K: Keypath, MC: MappingContext<K>, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC?,
     using binding:(key: Binding<K, M>, context: MC),
     uniquing: UniquingFunctions<M.MappedObject, RRC>?)
    -> MC
    where RRC.Iterator.Element == M.MappedObject {
        
        let context = binding.context
        
        guard shouldMapToJSON(via: binding.key.key, ifIn: context.keys) else {
            return context
        }
        
        do {
            let json = context.json
            let baseJSON = try baseJSONForCollection(json: json, keyPath: binding.key.keyPath)
            
            switch context.dir {
            case .toJSON:
                switch field {
                case .some(_):
                    try context.json = Crust.map(
                        to: json,
                        from: field!,
                        via: binding.key.key,
                        using: binding.key.mapping,
                        ifIn: context.keys,
                        keyedBy: binding.key.codingKeys)
                case .none:
                    context.json = .null()
                }
                
            case .fromJSON:
                if field == nil {
                    field = RRC()
                }
                // Have to use `!` here or we'll be writing to a copy of `field`. Also, must go through mapping
                // even in "null" case to handle deletes.
                try mapFromJSON(toCollection: &field!, using: binding, uniquing: uniquing)
                
                if case .null() = baseJSON {
                    field = nil
                }
            }
        }
        catch let error as NSError {
            context.error = error
        }
        
        return context
}

/// Our top level mapping function for mapping from a sequence/collection to JSON.
private func map<T, M: Mapping, K: Keypath, S: Sequence>(
    to json: JSONValue,
    from field: S,
    via key: K,
    using mapping: M,
    ifIn parentKeys: Set<K>,
    keyedBy nestedKeys: Set<M.CodingKeys>)
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
private func mapFromJSON<M: Mapping, K: Keypath, MC: MappingContext<K>, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC,
     using binding:(key: KeyedBinding<K, M>, context: MC),
     uniquing: UniquingFunctions<M.MappedObject, RRC>?) throws
    where RRC.Iterator.Element == M.MappedObject {
        
        let mapping = binding.key.binding.mapping
        let parentContext = binding.context
        
        guard parentContext.error == nil else {
            throw parentContext.error!
        }
        
        // Generate an extra sub-context so that we batch our array operations to the Adapter.
        let context = MappingContext(withObject: parentContext.object, json: parentContext.json, keys: parentContext.keys, adapterType: mapping.adapter.dataBaseTag, direction: MappingDirection.fromJSON)
        context.parent = parentContext.typeErased()
        let nestedBinding = (binding.key, context)
        
        try mapping.start(context: context)
        
        let fieldCopy = field
        let contains = uniquing?.contains(fieldCopy) ?? { _ in false }
        let elementEquality = uniquing?.elementEquality ?? { _ in { _ in false } }
        let optionalNewValues = try mapFromJsonToSequenceOfNewValues(
            map: nestedBinding,
            newValuesContains: elementEquality,
            fieldContains: contains)
        
        let newValues = try transform(newValues: optionalNewValues, via: nestedBinding.0.binding.keyPath, forUpdatePolicyNullability: nestedBinding.0.binding.collectionUpdatePolicy)
        
        try insert(into: &field, newValues: newValues, using: mapping, updatePolicy: nestedBinding.0.binding.collectionUpdatePolicy, indexOf: uniquing?.indexOf)
        
        try mapping.completeMapping(objects: field, context: context)
}

/// Handles null JSON values. Only nullable collections do not error on null (newValues == nil).
private func transform<T, K: Keypath>(
    newValues: [T]?,
    via keyPath: K,
    forUpdatePolicyNullability updatePolicy: CollectionUpdatePolicy<T>)
    throws -> [T] {
    
    if let newValues = newValues {
        return newValues
    }
    else if updatePolicy.nullable {
        return []
    }
    else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Attempting to assign \"null\" to non-nullable collection on type \(T.self) using JSON at key path \(keyPath) is not allowed. Please change the `CollectionUpdatePolicy` for this mapping to have `nullable: true`" ]
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
                
                // Unfortunately `AnyCollection<U.MappedObject>(orphans)` gives us "type is ambiguous without more context".
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

private func baseJSONForCollection<K: Keypath>(json: JSONValue, keyPath: K, ifIn keys: Set<K>) throws -> JSONValue {
    let baseJSON = json[keyPath]
    
    // Walked an empty keypath, return the whole json payload if it's an empty array since subscripting on a json array calls `map`.
    // TODO: May be simpler to support `nil` keyPaths.
    if case .some(.array(let arr)) = baseJSON, keyPath.keyPath == "", arr.count == 0 {
        return json
    }
    else if let baseJSON = baseJSON {
        return baseJSON
    }
    else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(keyPath) does not exist to map from" ]
        throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
    }
}

/// Gets all newly mapped data and returns it in an array.
///
/// - returns: The array of mapped values, `nil` if JSON at keypath is "null".
private func mapFromJsonToSequenceOfNewValues<M: Mapping, K: Keypath, MC: MappingContext<K>>(
    map:(key: KeyedBinding<K, M>, context: MC),
    newValuesContains: @escaping (M.MappedObject) -> (M.MappedObject) -> Bool,
    fieldContains: (M.MappedObject) -> Bool)
    throws -> [M.MappedObject]? {
    
        guard map.context.error == nil else {
            throw map.context.error!
        }
        
        let mapping = map.key.binding.mapping
        let codingKeys = map.key.codingKeys
        let baseJSON = try baseJSONForCollection(json: map.context.json, keyPath: map.key.binding.keyPath)
        let updatePolicy = map.key.binding.collectionUpdatePolicy
        
        let newValues = try generateNewValues(fromJsonArray: baseJSON,
                                              with: updatePolicy,
                                              using: mapping,
                                              codingKeys: codingKeys,
                                              newValuesContains: newValuesContains,
                                              fieldContains: fieldContains,
                                              context: map.context)
        
        return newValues
}

/// Generates and returns our new set of values from the JSON that will later be inserted into the collection
/// we're mapping into.
///
/// - returns: The array of mapped values, `nil` if JSON is "null".
private func generateNewValues<T, M: Mapping, K: Keypath>(
    fromJsonArray json: JSONValue,
    with updatePolicy: CollectionUpdatePolicy<M.MappedObject>,
    using mapping: M,
    codingKeys: Set<M.CodingKeys>,
    newValuesContains: @escaping (T) -> (T) -> Bool,
    fieldContains: (T) -> Bool,
    context: MappingContext<K>)
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
            let val = try mapper.map(from: json, using: mapping, keyedBy: codingKeys, parentContext: context)
            
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
