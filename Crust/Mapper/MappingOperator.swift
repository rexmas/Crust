import Foundation
import JSONValueRX

// MARK: - Merge right into tuple operator definition

infix operator >*< : AssignmentPrecedence

public func >*< <T, U>(left: T, right: U) -> (T, U) {
    return (left, right)
}

// MARK: - Map value operator definition

infix operator <- : AssignmentPrecedence

// Map with a key path.

@discardableResult
public func <- <T: JSONable, MC: MappingContext>(field: inout T, keyPath:(key: String, context: MC)) -> MC where T == T.ConversionType {
    return map(to: &field, via: (keyPath.key as JSONKeypath, keyPath.context))
}

@discardableResult
public func <- <T: JSONable, MC: MappingContext>(field: inout T?, keyPath:(key: String, context: MC)) -> MC where T == T.ConversionType {
    return map(to: &field, via: (keyPath.key as JSONKeypath, keyPath.context))
}

@discardableResult
public func <- <T: JSONable, MC: MappingContext>(field: inout T, keyPath:(key: Int, context: MC)) -> MC where T == T.ConversionType {
    return map(to: &field, via: (keyPath.key as JSONKeypath, keyPath.context))
}

@discardableResult
public func <- <T: JSONable, MC: MappingContext>(field: inout T?, keyPath:(key: Int, context: MC)) -> MC where T == T.ConversionType {
    return map(to: &field, via: (keyPath.key as JSONKeypath, keyPath.context))
}

// Map with a generic binding.

@discardableResult
public func <- <T, M: Mapping, MC: MappingContext>(field: inout T, binding:(key: Binding<M>, context: MC)) -> MC where M.MappedObject == T {
    return map(to: &field, using: binding)
}

@discardableResult
public func <- <T, M: Mapping, MC: MappingContext>(field: inout T?, binding:(key: Binding<M>, context: MC)) -> MC where M.MappedObject == T {
    return map(to: &field, using: binding)
}

// Transform.

@discardableResult
public func <- <T: JSONable, TF: Transform, MC: MappingContext>(field: inout T, binding:(key: Binding<TF>, context: MC)) -> MC where TF.MappedObject == T, T == T.ConversionType {
    return map(to: &field, using: binding)
}

@discardableResult
public func <- <T: JSONable, U: Transform, C: MappingContext>(field: inout T?, binding:(key: Binding<U>, context: C)) -> C where U.MappedObject == T, T == T.ConversionType {
    return map(to: &field, using: binding)
}

// MARK: - Map funcs

// Arbitrary object.
public func map<T: JSONable, C: MappingContext>(to field: inout T, via keyPath:(key: JSONKeypath, context: C)) -> C where T == T.ConversionType {
    
    guard keyPath.context.error == nil else {
        return keyPath.context
    }
    
    switch keyPath.context.dir {
    case .toJSON:
        let json = keyPath.context.json
        keyPath.context.json = Crust.map(to: json, from: field, via: keyPath.key)
    case .fromJSON:
        do {
            if let baseJSON = keyPath.context.json[keyPath.key] {
                try map(from: baseJSON, to: &field)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "Could not find value in JSON \(keyPath.context.json.values()) from keyPath \(keyPath.key)" ]
                throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
            }
        }
        catch let error as NSError {
            keyPath.context.error = error
        }
    }
    
    return keyPath.context
}

// Arbitrary Optional.
public func map<T: JSONable, MC: MappingContext>(to field: inout T?, via keyPath:(key: JSONKeypath, context: MC)) -> MC where T == T.ConversionType {
    
    guard keyPath.context.error == nil else {
        return keyPath.context
    }
    
    switch keyPath.context.dir {
    case .toJSON:
        let json = keyPath.context.json
        keyPath.context.json = Crust.map(to: json, from: field, via: keyPath.key)
    case .fromJSON:
        do {
            if let baseJSON = keyPath.context.json[keyPath.key] {
                try map(from: baseJSON, to: &field)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "Value not present in JSON \(keyPath.context.json.values()) from keyPath \(keyPath.key)" ]
                throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
            }
        }
        catch let error as NSError {
            keyPath.context.error = error
        }
    }
    
    return keyPath.context
}

// Mappable.
public func map<T, M: Mapping, MC: MappingContext>(to field: inout T, using binding:(key: Binding<M>, context: MC)) -> MC where M.MappedObject == T {
    
    guard binding.context.error == nil else {
        return binding.context
    }
    
    guard case .mapping(let key, let mapping) = binding.key else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Expected KeyExtension.mapping to map type \(T.self)" ]
        binding.context.error = NSError(domain: CrustMappingDomain, code: -1000, userInfo: userInfo)
        return binding.context
    }
    
    do {
        switch binding.context.dir {
        case .toJSON:
            let json = binding.context.json
            try binding.context.json = Crust.map(to: json, from: field, via: key, using: mapping)
        case .fromJSON:
            // TODO: again, need to allow for `nil` keypaths.
            if let baseJSON: JSONValue = {
                let key = binding.key
                let json = binding.context.json[binding.key.keyPath]
                if json == nil && key.keyPath == "" {
                    return binding.context.json
                }
                return json
            }() {
                try map(from: baseJSON, to: &field, using: mapping, context: binding.context)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(binding.key) does not exist to map from" ]
                throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
            }
        }
    }
    catch let error as NSError {
        binding.context.error = error
    }
    
    return binding.context
}

public func map<T, M: Mapping, MC: MappingContext>(to field: inout T?, using binding:(key: Binding<M>, context: MC)) -> MC where M.MappedObject == T {
    
    guard binding.context.error == nil else {
        return binding.context
    }
    
    guard case .mapping(let key, let mapping) = binding.key else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Expected KeyExtension.mapping to map type \(T.self)" ]
        binding.context.error = NSError(domain: CrustMappingDomain, code: -1000, userInfo: userInfo)
        return binding.context
    }
    
    do {
        switch binding.context.dir {
        case .toJSON:
            let json = binding.context.json
            try binding.context.json = Crust.map(to: json, from: field, via: key, using: mapping)
        case .fromJSON:
            if let baseJSON = binding.context.json[binding.key.keyPath] {
                try map(from: baseJSON, to: &field, using: mapping, context: binding.context)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(binding.key) does not exist to map from" ]
                throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
            }
        }
    }
    catch let error as NSError {
        binding.context.error = error
    }
    
    return binding.context
}

// MARK: - To JSON

private func map<T: JSONable>(to json: JSONValue, from field: T?, via key: JSONKeypath) -> JSONValue where T == T.ConversionType {
    var json = json
    
    if let field = field {
        json[key] = T.toJSON(field)
    }
    else {
        json[key] = .null()
    }
    
    return json
}

private func map<T, M: Mapping>(to json: JSONValue, from field: T?, via key: Keypath, using mapping: M) throws -> JSONValue where M.MappedObject == T {
    var json = json
    
    guard let field = field else {
        json[key] = .null()
        return json
    }
    
    json[key] = try Mapper().mapFromObjectToJSON(field, mapping: mapping)
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

private func map<T, M: Mapping>(from json: JSONValue, to field: inout T, using mapping: M, context: MappingContext) throws where M.MappedObject == T {
    
    let mapper = Mapper()
    field = try mapper.map(from: json, using: mapping, parentContext: context)
}

private func map<T, M: Mapping>(from json: JSONValue, to field: inout T?, using mapping: M, context: MappingContext) throws where M.MappedObject == T {
    
    if case .null = json {
        field = nil
        return
    }
    
    let mapper = Mapper()
    field = try mapper.map(from: json, using: mapping, parentContext: context)
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
public func <- <T, M: Mapping, MC: MappingContext, RRC: RangeReplaceableCollection>(field: inout RRC, binding:(key: Binding<M>, context: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject, T: Equatable {
    
    return map(toCollection: &field, using: binding)
}

/// This is for Collections with non-Equatable objects.
@discardableResult
public func <- <T, M: Mapping, MC: MappingContext, RRC: RangeReplaceableCollection>(field: inout RRC, binding:(key: Binding<M>, context: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject {
    
    return map(toCollection: &field, using: binding, uniquing: nil)
}

//// Optional types.
//
//@discardableResult
//public func <- <T, M: Mapping, MC: MappingContext, RRC: RangeReplaceableCollection>(field: inout RRC?, binding:(key: Binding<M>, context: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject, T: Equatable {
//    
//    return map(toCollection: &field, using: binding)
//}
//
///// This is for Collections with non-Equatable objects.
//@discardableResult
//public func <- <M: Mapping, MC: MappingContext, RRC: RangeReplaceableCollection>(field: inout RRC?, binding:(key: Binding<M>, context: MC)) -> MC where RRC.Iterator.Element == M.MappedObject {
//    
//    let uniquingFunctions: UniquingFunctions<M.MappedObject, RRC> = ({ _ in { _ in false }}, { _ in { _ in nil }}, { _ in { _ in false }})
//    
//    return map(toCollection: &field, using: binding, uniquing: uniquingFunctions)
//}

/// Map into a `RangeReplaceableCollection` with `Equatable` `Element`.
@discardableResult
public func map<T, M: Mapping, MC: MappingContext, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC,
     using binding:(key: Binding<M>, context: MC))
    -> MC
    where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject, T: Equatable {
        
        let equality: (T) -> (T) -> Bool = { obj in
            { compared in
                obj == compared
            }
        }
        
        let uniquingFunctions = (equality, RRC.index(of:), RRC.contains)
        
        return map(toCollection: &field, using: binding, uniquing: uniquingFunctions)
}

/// General function to mapping JSON into a `RangeReplaceableCollection`.
///
/// Providing uniqing functions for equality comparison, fetching by index, and checking existence of elements allows
/// for uniquing (merging/eliminating duplicates).
@discardableResult
public func map<M: Mapping, MC: MappingContext, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC,
     using binding:(key: Binding<M>, context: MC),
     uniquing: UniquingFunctions<M.MappedObject, RRC>?)
    -> MC
    where RRC.Iterator.Element == M.MappedObject {
    
    do {
        switch binding.context.dir {
        case .toJSON:
            let json = binding.context.json
            try binding.context.json = Crust.map(to: json, from: field, via: binding.key.keyPath, using: binding.key.mapping)
            
        case .fromJSON:
            try mapFromJSON(toCollection: &field, using: binding, uniquing: uniquing)
        }
    }
    catch let error as NSError {
        binding.context.error = error
    }
    
    return binding.context
}

/// Our top level mapping function for mapping from a sequence/collection to JSON.
private func map<T, M: Mapping, S: Sequence>(
    to json: JSONValue,
    from field: S,
    via key: Keypath,
    using mapping: M)
    throws -> JSONValue
    where M.MappedObject == T, S.Iterator.Element == T {
        
        var json = json
        
        let results = try field.map {
            try Mapper().mapFromObjectToJSON($0, mapping: mapping)
        }
        json[key] = .array(results)
        
        return json
}

/// Our top level mapping function for mapping from JSON into a collection.
private func mapFromJSON<M: Mapping, MC: MappingContext, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC,
     using binding:(key: Binding<M>, context: MC),
     uniquing: UniquingFunctions<M.MappedObject, RRC>?) throws
    where RRC.Iterator.Element == M.MappedObject {
        
        let fieldCopy = field
        let contains = uniquing?.contains(fieldCopy) ?? { _ in false }
        let elementEquality = uniquing?.elementEquality ?? { _ in { _ in false } }
        let optionalNewValues = try mapFromJsonToSequenceOfNewValues(
            map: binding,
            newValuesContains: elementEquality,
            fieldContains: contains)
        
        let newValues = try transform(newValues: optionalNewValues, via: binding.key.keyPath, forUpdatePolicyNullability: binding.key.collectionUpdatePolicy)
        
        try insert(into: &field, newValues: newValues, using: binding.key.mapping, updatePolicy: binding.key.collectionUpdatePolicy, indexOf: uniquing?.indexOf)
}

/// Handles null JSON values. Only nullable collections do not error on null (newValues == nil).
private func transform<T>(
    newValues: [T]?,
    via keyPath: Keypath,
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
                if let indexOfFunc = indexOf?(orphans) {
                    newValues.forEach {
                        if let index = indexOfFunc($0) {
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

/// Gets all newly mapped data and returns it in an array.
///
/// - returns: The array of mapped values, `nil` if JSON at keypath is "null".
private func mapFromJsonToSequenceOfNewValues<M: Mapping, MC: MappingContext>(
    map:(key: Binding<M>, context: MC),
    newValuesContains: @escaping (M.MappedObject) -> (M.MappedObject) -> Bool,
    fieldContains: (M.MappedObject) -> Bool)
    throws -> [M.MappedObject]? {
    
        guard map.context.error == nil else {
            throw map.context.error!
        }
        
        let mapping = map.key.mapping
        let baseJSON: JSONValue = try {
            let json = map.context.json
            let baseJSON = json[map.key.keyPath]
            
            // Walked an empty keypath, return the whole json payload if it's an empty array since subscripting on a json array calls `map`.
            // TODO: May be simpler to support `nil` keyPaths.
            if case .some(.array(let arr)) = baseJSON, map.key.keyPath == "", arr.count == 0 {
                return json
            }
            else if let baseJSON = baseJSON {
                return baseJSON
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(map.key) does not exist to map from" ]
                throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
            }
        }()
        
        let updatePolicy = map.key.collectionUpdatePolicy
        
        let newValues = try generateNewValues(fromJsonArray: baseJSON,
                                              with: updatePolicy,
                                              using: mapping,
                                              newValuesContains: newValuesContains,
                                              fieldContains: fieldContains,
                                              context: map.context)
        
        return newValues
}

/// Generates and returns our new set of values from the JSON that will later be inserted into the collection
/// we're mapping into.
///
/// - returns: The array of mapped values, `nil` if JSON is "null".
private func generateNewValues<T, M: Mapping>(
    fromJsonArray json: JSONValue,
    with updatePolicy: CollectionUpdatePolicy<M.MappedObject>,
    using mapping: M,
    newValuesContains: @escaping (T) -> (T) -> Bool,
    fieldContains: (T) -> Bool,
    context: MappingContext)
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
            let val = try mapper.map(from: json, using: mapping, parentContext: context)
            
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
