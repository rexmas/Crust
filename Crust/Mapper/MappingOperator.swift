import Foundation
import JSONValueRX

// MARK: - Merge right into tuple operator definition

infix operator >*< : AssignmentPrecedence

public func >*< <T, U>(left: T, right: U) -> (T, U) {
    return (left, right)
}

public func >*< <T: JSONKeypath, U>(left: T, right: U) -> (JSONKeypath, U) {
    return (left, right)
}

// MARK: - Map value operator definition

infix operator <- : AssignmentPrecedence

// Map with a key path.

@discardableResult
public func <- <T: JSONable, C: MappingContext>(field: inout T, keyPath:(key: JSONKeypath, context: C)) -> C where T == T.ConversionType {
    return map(to: &field, via: keyPath)
}

@discardableResult
public func <- <T: JSONable, C: MappingContext>(field: inout T?, keyPath:(key: JSONKeypath, context: C)) -> C where T == T.ConversionType {
    return map(to: &field, via: keyPath)
}

// Map with a generic binding.

@discardableResult
public func <- <T, U: Mapping, C: MappingContext>(field: inout T, binding:(key: Binding<U>, context: C)) -> C where U.MappedObject == T {
    return map(to: &field, using: binding)
}

@discardableResult
public func <- <T, U: Mapping, C: MappingContext>(field: inout T?, binding:(key: Binding<U>, context: C)) -> C where U.MappedObject == T {
    return map(to: &field, using: binding)
}

// Transform.

@discardableResult
public func <- <T: JSONable, U: Transform, C: MappingContext>(field: inout T, binding:(key: Binding<U>, context: C)) -> C where U.MappedObject == T, T == T.ConversionType {
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
        keyPath.context.json = Crust.map(to: json, fromField: field, viaKey: keyPath.key)
    case .fromJSON:
        do {
            if let baseJSON = keyPath.context.json[keyPath.key] {
                try mapFromJson(baseJSON, toField: &field)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "Could not find value in JSON \(keyPath.context.json) from keyPath \(keyPath.key)" ]
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
public func map<T: JSONable, C: MappingContext>(to field: inout T?, via keyPath:(key: JSONKeypath, context: C)) -> C where T == T.ConversionType {
    
    guard keyPath.context.error == nil else {
        return keyPath.context
    }
    
    switch keyPath.context.dir {
    case .toJSON:
        let json = keyPath.context.json
        keyPath.context.json = Crust.map(to: json, fromField: field, viaKey: keyPath.key)
    case .fromJSON:
        do {
            if let baseJSON = keyPath.context.json[keyPath.key] {
                try mapFromJson(baseJSON, toField: &field)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "Value not present in JSON \(keyPath.context.json) from keyPath \(keyPath.key)" ]
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
public func map<T, U: Mapping, C: MappingContext>(to field: inout T, using binding:(key: Binding<U>, context: C)) -> C where U.MappedObject == T {
    
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
            try binding.context.json = Crust.map(to: json, fromField: field, viaKey: key, mapping: mapping)
        case .fromJSON:
            // TODO: again, need to allow for `nil` keypaths.
            if let baseJSON: JSONValue = {
                let key = binding.key
                let json = binding.context.json[binding.key]
                if json == nil && key.keyPath == "" {
                    return binding.context.json
                }
                return json
            }() {
                try mapFromJson(baseJSON, toField: &field, mapping: mapping, context: binding.context)
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

public func map<T, U: Mapping, C: MappingContext>(to field: inout T?, using binding:(key: Binding<U>, context: C)) -> C where U.MappedObject == T {
    
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
            try binding.context.json = Crust.map(to: json, fromField: field, viaKey: key, mapping: mapping)
        case .fromJSON:
            if let baseJSON = binding.context.json[binding.key] {
                try mapFromJson(baseJSON, toField: &field, mapping: mapping, context: binding.context)
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

private func map<T: JSONable>(to json: JSONValue, fromField field: T?, viaKey key: JSONKeypath) -> JSONValue where T == T.ConversionType {
    var json = json
    
    if let field = field {
        json[key] = T.toJSON(field)
    }
    else {
        json[key] = .null()
    }
    
    return json
}

private func map<T, U: Mapping>(to json: JSONValue, fromField field: T?, viaKey key: Keypath, mapping: U) throws -> JSONValue where U.MappedObject == T {
    var json = json
    
    guard let field = field else {
        json[key] = .null()
        return json
    }
    
    json[key] = try Mapper<U>().mapFromObjectToJSON(field, mapping: mapping)
    return json
}

// MARK: - From JSON

private func mapFromJson<T: JSONable>(_ json: JSONValue, toField field: inout T) throws where T.ConversionType == T {
    
    if let fromJson = T.fromJSON(json) {
        field = fromJson
    }
    else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Conversion of JSON \(json) to type \(T.self) failed" ]
        throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
    }
}

private func mapFromJson<T: JSONable>(_ json: JSONValue, toField field: inout T?) throws where T.ConversionType == T {
    
    if case .null = json {
        field = nil
        return
    }
    
    if let fromJson = T.fromJSON(json) {
        field = fromJson
    }
    else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Conversion of JSON \(json) to type \(T.self) failed" ]
        throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
    }
}

private func mapFromJson<T, U: Mapping>(_ json: JSONValue, toField field: inout T, mapping: U, context: MappingContext) throws where U.MappedObject == T {
    
    let mapper = Mapper<U>()
    field = try mapper.map(from: json, using: mapping, parentContext: context)
}

private func mapFromJson<T, U: Mapping>(_ json: JSONValue, toField field: inout T?, mapping: U, context: MappingContext) throws where U.MappedObject == T {
    
    if case .null = json {
        field = nil
        return
    }
    
    let mapper = Mapper<U>()
    field = try mapper.map(from: json, using: mapping, parentContext: context)
}

// MARK: - Appendable - RangeReplaceableCollectionType subset (Array and Realm List follow this protocol while RLMArray follows Appendable)

public protocol Appendable: Sequence {
    static func createInstance(with class: Swift.AnyClass) -> Self
    mutating func append(_ newElement: Self.Iterator.Element)
    mutating func append(contentsOf newElements: [Iterator.Element])
    mutating func remove(at i: UInt)
    mutating func removeAll(keepingCapacity keepCapacity: Bool)
    
    // Can't be index(of object:) because Realm Obj-C.
    func findIndex(of object: Self.Iterator.Element) -> UInt
}

@discardableResult
public func <- <T, U: Mapping, C: MappingContext>(field: inout U.SequenceKind, map:(key: Binding<U>, context: C)) -> C where U.MappedObject == T, U.SequenceKind: RangeReplaceableCollection, U.SequenceKind.Iterator.Element == U.MappedObject, T: Equatable {
    
    return mapFromJson(toCollection: &field, map: map)
}

private func map<T, U: Mapping, V: Sequence>(
    to json: JSONValue,
    fromField field: V,
    viaKey key: Keypath,
    mapping: U)
    throws -> JSONValue
    where U.MappedObject == T, V.Iterator.Element == T, U.SequenceKind.Iterator.Element == U.MappedObject {
        
        var json = json
        
        let results = try field.map {
            try Mapper<U>().mapFromObjectToJSON($0, mapping: mapping)
        }
        json[key] = .array(results)
        
        return json
}

@discardableResult
public func mapFromJson<T, U: Mapping, C: MappingContext>(toCollection field: inout U.SequenceKind, map:(key: Binding<U>, context: C)) -> C where U.MappedObject == T, U.SequenceKind: RangeReplaceableCollection, U.SequenceKind.Iterator.Element == U.MappedObject, T: Equatable {
    
    do {
        switch map.context.dir {
        case .toJSON:
            let json = map.context.json
            try map.context.json = Crust.map(to: json, fromField: field, viaKey: map.key, mapping: map.key.mapping)
            
        case .fromJSON:
            let fieldCopy = field
            let (newObjects, _) = try mapFromJsonToSequence(map: map) {
                fieldCopy.contains($0)
            }
            
            switch map.key.collectionUpdatePolicy.insert {
            case .append:
                field.append(contentsOf: newObjects)
                
            case .replace(delete: let deletionBlock):
                var orphans = field
                field = U.SequenceKind(newObjects)
                
                if let deletion = deletionBlock {
                    field.forEach {
                        if let index = orphans.index(of: $0) {
                            orphans.remove(at: index)
                        }
                    }
                    
                    try deletion(orphans).forEach {
                        try map.key.mapping.delete(obj: $0)
                    }
                }
            }
        }
    }
    catch let error as NSError {
        map.context.error = error
    }
    
    return map.context
}

// Gets all newly mapped data and returns it in an array, caller can decide to append and what-not.
public func mapFromJsonToSequence<T, U: Mapping, C: MappingContext>(
    map:(key: Binding<U>, context: C),
    fieldContains: (T) -> Bool)
    throws -> (newObjects: [T], context: C)
    where U.MappedObject == T, U.SequenceKind.Iterator.Element == U.MappedObject, T: Equatable {
    
        guard map.context.error == nil else {
            throw map.context.error!
        }
        
        let mapping = map.key.mapping
        var newObjects: [T] = []
        
        let json = map.context.json
        let baseJSON = json[map.key]
        let updatePolicy = map.key.collectionUpdatePolicy
        
        // TODO: Stupid hack for empty string keypaths. Fix by allowing `nil` keyPath.
        if case .some(.array(let arr)) = baseJSON, map.key.keyPath == "", arr.count == 0 {
            newObjects = try generateNewValues(fromJsonArray: json,
                                     with: updatePolicy,
                                     using: mapping,
                                     fieldContains: fieldContains,
                                     context: map.context)
        }
        else if let baseJSON = baseJSON {
            newObjects = try generateNewValues(fromJsonArray: baseJSON,
                                     with: updatePolicy,
                                     using: mapping,
                                     fieldContains: fieldContains,
                                     context: map.context)
        }
        else {
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(map.key) does not exist to map from" ]
            throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
        }
        
        return (newObjects, map.context)
}

private func generateNewValues<T, U: Mapping, S: Sequence>(
    fromJsonArray json: JSONValue,
    with updatePolicy: CollectionUpdatePolicy<S>,
    using mapping: U,
    fieldContains: (T) -> Bool,
    context: MappingContext)
    throws -> [T]
    where U.MappedObject == T, T: Equatable, U.SequenceKind.Iterator.Element == U.MappedObject {
    
        guard case .array(let jsonArray) = json else {
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "Trying to map json of type \(type(of: json)) to \(U.SequenceKind.self)<\(T.self)>" ]
            throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
        }
        
        let mapper = Mapper<U>()
        
        var newObjects = [T]()
        
        let isUnique = { (obj: T, newObjects: [T], fieldContains: (T) -> Bool) -> Bool in
            let newObjectsContainsObj = newObjects.contains(obj)
            
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
