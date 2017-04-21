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
    
    if let fromJson = T.fromJSON(json) {
        field = fromJson
    }
    else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Conversion of JSON \(json.values()) to type \(T.self) failed" ]
        throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
    }
}

private func map<T: JSONable>(from json: JSONValue, to field: inout T?) throws where T.ConversionType == T {
    
    if case .null = json {
        field = nil
        return
    }
    
    if let fromJson = T.fromJSON(json) {
        field = fromJson
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

// MARK: - RangeReplaceableCollectionType (Array and Realm List follow this protocol).

/// This handles the case where our Collection contains Equatable objects, and thus can be uniqued during insertion and deletion.
@discardableResult
public func <- <T, M: Mapping, MC: MappingContext, RRC: RangeReplaceableCollection>(field: inout RRC, binding:(key: Binding<M>, context: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject, T: Equatable {
    
    return map(toCollection: &field, using: binding)
}

/// This is for Collections with non-Equatable objects.
@discardableResult
public func <- <T, M: Mapping, MC: MappingContext, RRC: RangeReplaceableCollection>(field: inout RRC, binding:(key: Binding<M>, context: MC)) -> MC where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject {
    
    return map(toCollection: &field, using: binding, elementEquality: nil, indexOf: nil, fieldContains: nil)
}

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
        
        return map(toCollection: &field, using: binding, elementEquality: equality, indexOf: RRC.index(of:), fieldContains: RRC.contains)
}

@discardableResult
public func map<T, M: Mapping, MC: MappingContext, RRC: RangeReplaceableCollection>
    (toCollection field: inout RRC,
     using binding:(key: Binding<M>, context: MC),
     elementEquality: ((T) -> (T) -> Bool)?,
     indexOf: ((RRC) -> (T) -> RRC.Index?)?,
     fieldContains: ((RRC) -> (T) -> Bool)?)
    -> MC
    where M.MappedObject == T, RRC.Iterator.Element == M.MappedObject {
    
    do {
        switch binding.context.dir {
        case .toJSON:
            let json = binding.context.json
            try binding.context.json = Crust.map(to: json, from: field, via: binding.key.keyPath, using: binding.key.mapping)
            
        case .fromJSON:
            let fieldCopy = field
            let contains = fieldContains?(fieldCopy)
            let (newObjects, _) = try mapFromJsonToSequence(
                map: binding,
                newObjectsContains: elementEquality ?? { _ in { _ in false } },
                fieldContains: contains ?? { _ in false })
            
            switch binding.key.collectionUpdatePolicy.insert {
            case .append:
                field.append(contentsOf: newObjects)
                
            case .replace(delete: let deletionBlock):
                var orphans: RRC = field
                
                if let deletion = deletionBlock {
                    newObjects.forEach {
                        if let index = indexOf?(orphans)($0) {
                            orphans.remove(at: index)
                        }
                    }
                    
                    // Unfortunately `AnyCollection<U.MappedObject>(orphans)` gives us "type is ambiguous without more context".
                    let arrayOrphans = Array(orphans)
                    let shouldDelete = AnyCollection<M.MappedObject>(arrayOrphans)
                    try deletion(shouldDelete).forEach {
                        try binding.key.mapping.delete(obj: $0)
                    }
                }
                
                field.removeAll(keepingCapacity: true)
                field.append(contentsOf: newObjects)
            }
        }
    }
    catch let error as NSError {
        binding.context.error = error
    }
    
    return binding.context
}

// Gets all newly mapped data and returns it in an array, caller can decide to append and what-not.
private func mapFromJsonToSequence<T, M: Mapping, MC: MappingContext>(
    map:(key: Binding<M>, context: MC),
    newObjectsContains: @escaping (T) -> (T) -> Bool,
    fieldContains: (T) -> Bool)
    throws -> (newObjects: [T], context: MC)
    where M.MappedObject == T {
    
        guard map.context.error == nil else {
            throw map.context.error!
        }
        
        let mapping = map.key.mapping
        var newObjects: [T] = []
        
        let json = map.context.json
        let baseJSON = json[map.key.keyPath]
        let updatePolicy = map.key.collectionUpdatePolicy
        
        // TODO: Stupid hack for empty string keypaths. Fix by allowing `nil` keyPath.
        if case .some(.array(let arr)) = baseJSON, map.key.keyPath == "", arr.count == 0 {
            newObjects = try generateNewValues(fromJsonArray: json,
                                     with: updatePolicy,
                                     using: mapping,
                                     newObjectsContains: newObjectsContains,
                                     fieldContains: fieldContains,
                                     context: map.context)
        }
        else if let baseJSON = baseJSON {
            newObjects = try generateNewValues(fromJsonArray: baseJSON,
                                     with: updatePolicy,
                                     using: mapping,
                                     newObjectsContains: newObjectsContains,
                                     fieldContains: fieldContains,
                                     context: map.context)
        }
        else {
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(map.key) does not exist to map from" ]
            throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
        }
        
        return (newObjects, map.context)
}

private func generateNewValues<T, M: Mapping>(
    fromJsonArray json: JSONValue,
    with updatePolicy: CollectionUpdatePolicy<M.MappedObject>,
    using mapping: M,
    newObjectsContains: @escaping (T) -> (T) -> Bool,
    fieldContains: (T) -> Bool,
    context: MappingContext)
    throws -> [T]
    where M.MappedObject == T {
    
        guard case .array(let jsonArray) = json else {
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "Trying to map json of type \(type(of: json)) to Collection of <\(T.self)>" ]
            throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
        }
        
        let mapper = Mapper()
        
        var newObjects = [T]()
        
        let isUnique = { (obj: T, newObjects: [T], fieldContains: (T) -> Bool) -> Bool in
            let newObjectsContainsObj = newObjects.contains(where: newObjectsContains(obj))
            
            switch updatePolicy.insert {
            case .replace(_):
                return !newObjectsContainsObj
            case .append:
                return !(newObjectsContainsObj || fieldContains(obj))
            }
        }
        
        for json in jsonArray {
            let obj = try mapper.map(from: json, using: mapping, parentContext: context)
            
            if updatePolicy.unique {
                if isUnique(obj, newObjects, fieldContains) {
                    newObjects.append(obj)
                }
            }
            else {
                newObjects.append(obj)
            }
        }
        
        return newObjects
}
