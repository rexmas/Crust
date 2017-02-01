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

// Map arbitrary object.

@discardableResult
public func <- <T: JSONable, C: MappingContext>(field: inout T, map:(key: JSONKeypath, context: C)) -> C where T == T.ConversionType {
    return mapField(&field, map: map)
}

@discardableResult
public func <- <T: JSONable, C: MappingContext>(field: inout T?, map:(key: JSONKeypath, context: C)) -> C where T == T.ConversionType {
    return mapField(&field, map: map)
}

// Map a Mappable.

@discardableResult
public func <- <T, U: Mapping, C: MappingContext>(field: inout T, map:(key: Spec<U>, context: C)) -> C where U.MappedObject == T {
    return mapFieldWithMapping(&field, map: map)
}

@discardableResult
public func <- <T, U: Mapping, C: MappingContext>(field: inout T?, map:(key: Spec<U>, context: C)) -> C where U.MappedObject == T {
    return mapFieldWithMapping(&field, map: map)
}

// Transform.

@discardableResult
public func <- <T: JSONable, U: Transform, C: MappingContext>(field: inout T, map:(key: Spec<U>, context: C)) -> C where U.MappedObject == T, T == T.ConversionType {
    return mapFieldWithMapping(&field, map: map)
}

@discardableResult
public func <- <T: JSONable, U: Transform, C: MappingContext>(field: inout T?, map:(key: Spec<U>, context: C)) -> C where U.MappedObject == T, T == T.ConversionType {
    return mapFieldWithMapping(&field, map: map)
}

// MARK: - Map funcs

// Arbitrary object.
public func mapField<T: JSONable, C: MappingContext>(_ field: inout T, map:(key: JSONKeypath, context: C)) -> C where T == T.ConversionType {
    
    guard map.context.error == nil else {
        return map.context
    }
    
    switch map.context.dir {
    case .toJSON:
        let json = map.context.json
        map.context.json = mapToJson(json, fromField: field, viaKey: map.key)
    case .fromJSON:
        do {
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: &field)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "Could not find value in JSON \(map.context.json) from keyPath \(map.key)" ]
                throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
            }
        }
        catch let error as NSError {
            map.context.error = error
        }
    }
    
    return map.context
}

// Arbitrary Optional.
public func mapField<T: JSONable, C: MappingContext>(_ field: inout T?, map:(key: JSONKeypath, context: C)) -> C where T == T.ConversionType {
    
    guard map.context.error == nil else {
        return map.context
    }
    
    switch map.context.dir {
    case .toJSON:
        let json = map.context.json
        map.context.json = mapToJson(json, fromField: field, viaKey: map.key)
    case .fromJSON:
        do {
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: &field)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "Value not present in JSON \(map.context.json) from keyPath \(map.key)" ]
                throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
            }
        }
        catch let error as NSError {
            map.context.error = error
        }
    }
    
    return map.context
}

// Mappable.
public func mapFieldWithMapping<T, U: Mapping, C: MappingContext>(_ field: inout T, map:(key: Spec<U>, context: C)) -> C where U.MappedObject == T {
    
    guard map.context.error == nil else {
        return map.context
    }
    
    guard case .mapping(let key, let mapping) = map.key else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Expected KeyExtension.mapping to map type \(T.self)" ]
        map.context.error = NSError(domain: CrustMappingDomain, code: -1000, userInfo: userInfo)
        return map.context
    }
    
    do {
        switch map.context.dir {
        case .toJSON:
            let json = map.context.json
            try map.context.json = mapToJson(json, fromField: field, viaKey: key, mapping: mapping)
        case .fromJSON:
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: &field, mapping: mapping, context: map.context)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(map.key) does not exist to map from" ]
                throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
            }
        }
    }
    catch let error as NSError {
        map.context.error = error
    }
    
    return map.context
}

public func mapFieldWithMapping<T, U: Mapping, C: MappingContext>(_ field: inout T?, map:(key: Spec<U>, context: C)) -> C where U.MappedObject == T {
    
    guard map.context.error == nil else {
        return map.context
    }
    
    guard case .mapping(let key, let mapping) = map.key else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Expected KeyExtension.mapping to map type \(T.self)" ]
        map.context.error = NSError(domain: CrustMappingDomain, code: -1000, userInfo: userInfo)
        return map.context
    }
    
    do {
        switch map.context.dir {
        case .toJSON:
            let json = map.context.json
            try map.context.json = mapToJson(json, fromField: field, viaKey: key, mapping: mapping)
        case .fromJSON:
            if let baseJSON = map.context.json[map.key] {
                try mapFromJson(baseJSON, toField: &field, mapping: mapping, context: map.context)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(map.key) does not exist to map from" ]
                throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
            }
        }
    }
    catch let error as NSError {
        map.context.error = error
    }
    
    return map.context
}

// MARK: - To JSON

private func mapToJson<T: JSONable>(_ json: JSONValue, fromField field: T?, viaKey key: JSONKeypath) -> JSONValue where T == T.ConversionType {
    var json = json
    
    if let field = field {
        json[key] = T.toJSON(field)
    }
    else {
        json[key] = .null()
    }
    
    return json
}

private func mapToJson<T, U: Mapping>(_ json: JSONValue, fromField field: T?, viaKey key: Keypath, mapping: U) throws -> JSONValue where U.MappedObject == T {
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

// TODO: When using `RangeReplaceableCollection` vs `Array` we get a lot of "ambiguous use of operator '<-'".
// This seems to be an issue with the type checker since when `field` is `String` this can still happen. We're
// thus forced to create a separate operator :(. Isolate and report a bug.

infix operator <*- : AssignmentPrecedence

@discardableResult
public func <*- <T, U: Mapping, C: MappingContext>(field: inout U.SequenceKind, map:(key: Spec<U>, context: C)) -> C where U.MappedObject == T, U.SequenceKind: RangeReplaceableCollection, U.SequenceKind.Iterator.Element == U.MappedObject, T: Equatable {
    
    return mapFromJson(toCollection: &field, map: map)
}

@discardableResult
public func mapFromJson<T, U: Mapping, C: MappingContext>(toCollection field: inout U.SequenceKind, map:(key: Spec<U>, context: C)) -> C where U.MappedObject == T, U.SequenceKind: RangeReplaceableCollection, U.SequenceKind.Iterator.Element == U.MappedObject, T: Equatable {
    
    do {
        let fieldCopy = field
        let (newObjects, _) = try mapFromJson(toCollection: field, map: map) {
            fieldCopy.contains($0)
        }
    
        if case .replace(let deletionBlock) = map.key.collectionInsertionMethod {
            
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
    catch let error as NSError {
        map.context.error = error
    }
    
    return map.context
}

public func mapFromJson<T, U: Mapping, C: MappingContext>(
    toCollection field: U.SequenceKind,
    map:(key: Spec<U>, context: C),
    contains: (T) -> Bool)
    throws -> (newObjects: [T], context: C)
    where U.MappedObject == T, U.SequenceKind.Iterator.Element == U.MappedObject, T: Equatable {
    
        guard map.context.error == nil else {
            throw map.context.error!
        }
        
        let mapping = map.key.mapping
        var newObjects: [T] = []
        
        switch map.context.dir {
        case .toJSON:
            let json = map.context.json
            try map.context.json = mapToJson(json, fromField: field, viaKey: map.key, mapping: mapping)
            
        case .fromJSON:
            let json = map.context.json
            let baseJSON = json[map.key]
            let insertionMethod = map.key.collectionInsertionMethod
            if case .some(.array(let arr)) = baseJSON, map.key.keyPath == "", arr.count == 0 {
                newObjects = try mapFrom(json: json,
                                         toCollection: field,
                                         with: insertionMethod,
                                         using: mapping,
                                         contains: contains,
                                         context: map.context)
            }
            else if let baseJSON = baseJSON {
                newObjects = try mapFrom(json: baseJSON,
                                         toCollection: field,
                                         with: insertionMethod,
                                         using: mapping,
                                         contains: contains,
                                         context: map.context)
            }
            else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "JSON at key path \(map.key) does not exist to map from" ]
                throw NSError(domain: CrustMappingDomain, code: 0, userInfo: userInfo)
            }
        }
        
        return (newObjects, map.context)
}

private func mapToJson<T, U: Mapping, V: Sequence>(
    _ json: JSONValue,
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

private func mapFrom<T, U: Mapping>(
    json: JSONValue,
    toCollection field: U.SequenceKind,
    with insertionMethod: CollectionInsertionMethod<U.SequenceKind>,
    using mapping: U,
    contains: (T) -> Bool,
    context: MappingContext)
    throws -> [T]
    where U.MappedObject == T, T: Equatable, U.SequenceKind.Iterator.Element == U.MappedObject {
    
    guard case .array(let xs) = json else {
        let userInfo = [ NSLocalizedFailureReasonErrorKey : "Trying to map json of type \(type(of: json)) to \(U.SequenceKind.self)<\(T.self)>" ]
        throw NSError(domain: CrustMappingDomain, code: -1, userInfo: userInfo)
    }
    
    let mapper = Mapper<U>()
    
    var newObjects = [T]()
    
    for x in xs {
        let obj = try mapper.map(from: x, using: mapping, parentContext: context)
        
        switch insertionMethod {
        case .append, .replace(_):
            newObjects.append(obj)
            
        case .union:
            if !contains(obj) {
                newObjects.append(obj)
            }
        }
    }
    
    return newObjects
}
/*
@discardableResult
public func <- <T, U: Mapping, V: Appendable, C: MappingContext>(
    field: inout V,
    map:(key: Spec<U>, context: C))
    -> C
    where U.MappedObject == T, U.SequenceKind == V, V.Iterator.Element == T, T: Equatable {
        
        do {
            let fieldCopy = field
            let (newObjects, _) = try mapFromJson(toCollection: field, map: map) {
                fieldCopy.contains($0)
            }
            //todo
            if case .replace(let deletionBlock) = map.key.collectionInsertionMethod {
                
                var orphans = field
                field.removeAll(keepingCapacity: false)
                field.append(contentsOf: newObjects)
                
                if let deletion = deletionBlock {
                    field.forEach {
                        let index = orphans.findIndex(of: $0)
                        if index != UInt.max {
                            orphans.remove(at: index)
                        }
                    }
                    
                    try deletion(orphans).forEach {
                        try map.key.mapping.delete(obj: $0)
                    }
                }
            }
        }
        catch let error as NSError {
            map.context.error = error
        }
        
        return map.context
}
*/
