import Foundation
import RealmSwift

public enum MappingDirection {
    case FromJSON
    case ToJSON
}

internal let CRMappingDomain = "CRMappingDomain"

public protocol CRMappingKey : JSONKeypath { }

extension String : CRMappingKey { }
extension Int : CRMappingKey { }

public enum KeyExtensions<T: Mapping> : CRMappingKey {
    case ForeignKey(CRMappingKey)
    case Transform(CRMappingKey, String) // TODO: Second element should be Transform type to define later
    case Mapping(CRMappingKey, T)
    
    public var keyPath: String {
        switch self {
        case .ForeignKey(let keyPath):
            return keyPath.keyPath
        case .Transform(let keyPath, _):
            return keyPath.keyPath
        case .Mapping(let keyPath, _):
            return keyPath.keyPath
        }
    }
}

// Do we need this in the end?
public protocol Mappable { }

public protocol Mapping {
    typealias MappedObject: Mappable
    typealias AdaptorKind: Adaptor
    
    var adaptor: AdaptorKind { get }
    var primaryKeys: Array<CRMappingKey> { get }
    
    func mapping(tomap: MappedObject, context: MappingContext)
}

public protocol Adaptor {
    typealias BaseType
    typealias ResultsType: CollectionType
    
    func mappingBegins() throws
    func mappingEnded() throws
    func mappingErrored(error: ErrorType)
    
    func fetchObjectWithType(type: BaseType.Type, keyValues: Dictionary<String, CVarArgType>) -> BaseType?
    func fetchObjectsWithType(type: BaseType.Type, predicate: NSPredicate) -> ResultsType
    func createObject(objType: BaseType.Type) throws -> BaseType
    func deleteObject(obj: BaseType) throws
    func saveObjects(objects: [ BaseType ]) throws
    
    // TODO: Add threading model here or in separate protocol.
}

public class MappingContext {
    public var json: JSONValue
    public var object: Mappable
    public private(set) var dir: MappingDirection
    public internal(set) var error: ErrorType?
    public internal(set) var parent: MappingContext? = nil
    
    init(withObject object:Mappable, json: JSONValue, direction: MappingDirection) {
        self.dir = direction
        self.object = object
        self.json = json
    }
}

// Global method caller used to perform mappings.
public struct CRMapper<T: Mappable, U: Mapping where U.MappedObject == T> {
    
    public init() { }
    
    public func mapFromJSONToNewObject(json: JSONValue, mapping: U) throws -> T {
        let object = try getNewInstance(mapping)
        return try mapFromJSON(json, toObject: object, mapping: mapping)
    }
    
    public func mapFromJSONToExistingObject(json: JSONValue, mapping: U, parentContext: MappingContext? = nil) throws -> T {
        var object = try getInstance(mapping, fromJSON: json)
        if object == nil {
            object = try getNewInstance(mapping)
        }
        return try mapFromJSON(json, toObject: object!, mapping: mapping, parentContext: parentContext)
    }
    
    public func mapFromJSON(json: JSONValue, var toObject object: T, mapping: U, parentContext: MappingContext? = nil) throws -> T {
        let context = MappingContext(withObject: object, json: json, direction: MappingDirection.FromJSON)
        context.parent = parentContext
        try performMappingWithObject(&object, mapping: mapping, context: context)
        return object
    }
    
    public func mapFromObjectToJSON(var object: T, mapping: U) throws -> JSONValue {
        let context = MappingContext(withObject: object, json: JSONValue.JSONObject([:]), direction: MappingDirection.ToJSON)
        try performMappingWithObject(&object, mapping: mapping, context: context)
        return context.json
    }
    
    internal func performMappingWithObject(inout object: T, mapping: U, context: MappingContext) throws {
        
        if context.parent == nil {
            var underlyingError: NSError?
            do {
                try mapping.adaptor.mappingBegins()
            } catch let err as NSError {    // We can handle NSErrors higher up.
                underlyingError = err
            } catch {
                var userInfo = Dictionary<NSObject, AnyObject>()
                userInfo[NSLocalizedFailureReasonErrorKey] = "Errored during mappingBegins for adaptor \(mapping.adaptor)"
                userInfo[NSUnderlyingErrorKey] = underlyingError
                throw NSError(domain: CRMappingDomain, code: -1, userInfo: userInfo)
            }
        }
        
        mapping.mapping(object, context: context)
        if let error = context.error {
            if context.parent == nil {
                mapping.adaptor.mappingErrored(error)
            }
            throw error
        }
        
        if context.parent == nil {
            var underlyingError: NSError?
            do {
                try mapping.adaptor.mappingEnded()
            } catch let err as NSError {
                underlyingError = err
            } catch {
                var userInfo = Dictionary<NSObject, AnyObject>()
                userInfo[NSLocalizedFailureReasonErrorKey] = "Errored during mappingEnded for adaptor \(mapping.adaptor)"
                userInfo[NSUnderlyingErrorKey] = underlyingError
                throw NSError(domain: CRMappingDomain, code: -1, userInfo: userInfo)
            }
        }
        
        context.object = object
    }
    
    internal func getInstance(mapping: U, fromJSON json: JSONValue) throws -> T? {
        
        // NOTE: This sux but `T: U.AdaptorKind.BaseType` as a type constraint throws a compiler error as of 7.1 Xcode
        // and `T == U.AdaptorKind.BaseType` doesn't work with sub-types (i.e. expects T to be that exact type)
        guard T.self is U.AdaptorKind.BaseType.Type else {
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "Type of object \(T.self) is not a subtype of \(U.AdaptorKind.BaseType.self)" ]
            throw NSError(domain: CRMappingDomain, code: -1, userInfo: userInfo)
        }
        
        let primaryKeys = mapping.primaryKeys
        var keyValues = [ String : CVarArgType ]()
        try primaryKeys.forEach {
            let keyPath = $0.keyPath
            if let val = json[keyPath] {
                keyValues[keyPath] = val.valuesAsNSObjects()
            } else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "Primary key of \(keyPath) does not exist in JSON but is expected from mapping \(U.self)" ]
                throw NSError(domain: CRMappingDomain, code: -1, userInfo: userInfo)
            }
        }
        
        return mapping.adaptor.fetchObjectWithType(T.self as! U.AdaptorKind.BaseType.Type, keyValues: keyValues) as! T?
    }
    
    internal func getNewInstance(mapping: U) throws -> T {
        
        // NOTE: This sux but `T: U.AdaptorKind.BaseType` as a type constraint throws a compiler error as of 7.1 Xcode
        // and `T == U.AdaptorKind.BaseType` doesn't work with sub-types (i.e. expects T to be that exact type)
        guard T.self is U.AdaptorKind.BaseType.Type else {
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "Type of object \(T.self) is not a subtype of \(U.AdaptorKind.BaseType.self)" ]
            throw NSError(domain: CRMappingDomain, code: -1, userInfo: userInfo)
        }
        
        return try mapping.adaptor.createObject(T.self as! U.AdaptorKind.BaseType.Type) as! T
    }
}

// For Network lib have something along the lines of. Will need to properly handle the typing constraints.
// func registerMapping(mapping: Mapping, forPath path: URLPath)
