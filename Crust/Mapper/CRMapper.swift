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

public struct CRMappingOptions : OptionSetType {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    static let None = CRMappingOptions(rawValue: 0)
    static let AllowDuplicatesInCollection = CRMappingOptions(rawValue: 1)
}

protocol Transform : AnyMapping {
    func fromJSON(json: JSONValue) throws -> MappedObject
    func toJSON(obj: MappedObject) -> JSONValue
}

extension Transform {
    func mapping(inout tomap: MappedObject, context: MappingContext) {
        switch context.dir {
        case .FromJSON:
            do {
                try tomap = self.fromJSON(context.json)
            } catch let err as NSError {
                context.error = err
            }
        case .ToJSON:
            context.json = self.toJSON(tomap)
        }
    }
}

public enum KeyExtensions<T: Mapping> : CRMappingKey {
    case Mapping(CRMappingKey, T)
    indirect case MappingOptions(KeyExtensions, CRMappingOptions)
    
    public var keyPath: String {
        switch self {
        case .Mapping(let keyPath, _):
            return keyPath.keyPath
        case .MappingOptions(let keyPath, _):
            return keyPath.keyPath
        }
    }
    
    public var options: CRMappingOptions {
        switch self {
        case .MappingOptions(_, let options):
            return options
        default:
            return [ .None ]
        }
    }
    
    // TODO: Will consruct function as if Transform will fail for now to future proof.
    // Possible option: Have Transform construct a base Mapping and convert Mapping to ObjectMapping : Mapping.
    // Then this func won't have to throw...
    public func getMapping() throws -> T {
        switch self {
        case .Mapping(_, let mapping):
            return mapping
        case .MappingOptions(let mapping, _):
            return try mapping.getMapping()
        }
    }
}

public protocol Mappable { }

public protocol Mapping {
    typealias MappedObject: Mappable
    typealias AdaptorKind: Adaptor
    
    var adaptor: AdaptorKind { get }
    var primaryKeys: Array<CRMappingKey> { get }
    
    func mapping(inout tomap: MappedObject, context: MappingContext)
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

// Method caller used to perform mappings.
public struct CRMapper<T: Mappable, U: Mapping where U.MappedObject == T> {
    
    public init() { }
    
    public func mapFromJSONToNewObject(json: JSONValue, mapping: U) throws -> T {
        let object = try mapping.getNewInstance()
        return try mapFromJSON(json, toObject: object, mapping: mapping)
    }
    
    public func mapFromJSONToExistingObject(json: JSONValue, mapping: U, parentContext: MappingContext? = nil) throws -> T {
        var object = try mapping.getExistingInstanceFromJSON(json)
        if object == nil {
            object = try mapping.getNewInstance()
        }
        return try mapFromJSON(json, toObject: object!, mapping: mapping, parentContext: parentContext)
    }
    
    public func mapFromJSON(json: JSONValue, var toObject object: T, mapping: U, parentContext: MappingContext? = nil) throws -> T {
        let context = MappingContext(withObject: object, json: json, direction: MappingDirection.FromJSON)
        context.parent = parentContext
        try mapping.performMappingWithObject(&object, context: context)
        return object
    }
    
    public func mapFromObjectToJSON(var object: T, mapping: U) throws -> JSONValue {
        let context = MappingContext(withObject: object, json: JSONValue.JSONObject([:]), direction: MappingDirection.ToJSON)
        try mapping.performMappingWithObject(&object, context: context)
        return context.json
    }
}

public extension Mapping {
    func getExistingInstanceFromJSON(json: JSONValue) throws -> MappedObject? {
        
        // NOTE: This sux but `MappedObject: AdaptorKind.BaseType` as a type constraint throws a compiler error as of 7.1 Xcode
        // and `MappedObject == AdaptorKind.BaseType` doesn't work with sub-types (i.e. expects MappedObject to be that exact type)
        guard MappedObject.self is AdaptorKind.BaseType.Type else {
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "Type of object \(MappedObject.self) is not a subtype of \(AdaptorKind.BaseType.self)" ]
            throw NSError(domain: CRMappingDomain, code: -1, userInfo: userInfo)
        }
        
        let primaryKeys = self.primaryKeys
        var keyValues = [ String : CVarArgType ]()
        try primaryKeys.forEach {
            let keyPath = $0.keyPath
            if let val = json[keyPath] {
                keyValues[keyPath] = val.valuesAsNSObjects()
            } else {
                let userInfo = [ NSLocalizedFailureReasonErrorKey : "Primary key of \(keyPath) does not exist in JSON but is expected from mapping \(Self.self)" ]
                throw NSError(domain: CRMappingDomain, code: -1, userInfo: userInfo)
            }
        }
        
        return self.adaptor.fetchObjectWithType(MappedObject.self as! AdaptorKind.BaseType.Type, keyValues: keyValues) as! MappedObject?
    }
    
    func getNewInstance() throws -> MappedObject {
        
        // NOTE: This sux but `MappedObject: AdaptorKind.BaseType` as a type constraint throws a compiler error as of 7.1 Xcode
        // and `MappedObject == AdaptorKind.BaseType` doesn't work with sub-types (i.e. expects MappedObject to be that exact type)
        guard MappedObject.self is AdaptorKind.BaseType.Type else {
            let userInfo = [ NSLocalizedFailureReasonErrorKey : "Type of object \(MappedObject.self) is not a subtype of \(AdaptorKind.BaseType.self)" ]
            throw NSError(domain: CRMappingDomain, code: -1, userInfo: userInfo)
        }
        
        return try self.adaptor.createObject(MappedObject.self as! AdaptorKind.BaseType.Type) as! MappedObject
    }
    
    internal func startMappingWithContext(context: MappingContext) throws {
        if context.parent == nil {
            var underlyingError: NSError?
            do {
                try self.adaptor.mappingBegins()
            } catch let err as NSError {    // We can handle NSErrors higher up.
                underlyingError = err
            } catch {
                var userInfo = Dictionary<NSObject, AnyObject>()
                userInfo[NSLocalizedFailureReasonErrorKey] = "Errored during mappingBegins for adaptor \(self.adaptor)"
                userInfo[NSUnderlyingErrorKey] = underlyingError
                throw NSError(domain: CRMappingDomain, code: -1, userInfo: userInfo)
            }
        }
    }
    
    internal func endMappingWithContext(context: MappingContext) throws {
        if context.parent == nil {
            var underlyingError: NSError?
            do {
                try self.adaptor.mappingEnded()
            } catch let err as NSError {
                underlyingError = err
            } catch {
                var userInfo = Dictionary<NSObject, AnyObject>()
                userInfo[NSLocalizedFailureReasonErrorKey] = "Errored during mappingEnded for adaptor \(self.adaptor)"
                userInfo[NSUnderlyingErrorKey] = underlyingError
                throw NSError(domain: CRMappingDomain, code: -1, userInfo: userInfo)
            }
        }
    }
    
    public func executeMappingWithObject(inout object: MappedObject, context: MappingContext) {
        self.mapping(&object, context: context)
    }
    
    internal func performMappingWithObject(inout object: MappedObject, context: MappingContext) throws {
        
        try self.startMappingWithContext(context)
        
        self.executeMappingWithObject(&object, context: context)
        
        if let error = context.error {
            if context.parent == nil {
                self.adaptor.mappingErrored(error)
            }
            throw error
        }
        
        try self.endMappingWithContext(context)
        
        context.object = object
    }
}

// For Network lib have something along the lines of. Will need to properly handle the typing constraints.
// func registerMapping(mapping: Mapping, forPath path: URLPath)
