import Foundation
import RealmSwift

public enum MappingDirection {
    case FromJSON
    case ToJSON
}

public protocol CRMappingKey : JSONKeypath { }

extension String : CRMappingKey { }
extension Int : CRMappingKey { }

public enum KeyExtensions : CRMappingKey {
    case ForeignKey(CRMappingKey)
    case Transform(CRMappingKey, String) // TODO: Second element should be Transform type to define later
    
    public var keyPath: String {
        switch self {
            
        case .ForeignKey(let keyPath):
            return keyPath.keyPath
            
        case .Transform(let keyPath, _):
            return keyPath.keyPath
        }
    }
}

public protocol Mapping {
    typealias MappedObject: Mappable
    typealias AdaptorKind: Adaptor
    
    var adaptor: AdaptorKind { get }
    var primaryKeys: Array<CRMappingKey> { get }
    
    func mapping(tomap: MappedObject, context: MappingContext)
}

// Do we need this in the end?
public protocol Mappable { }

public protocol Adaptor {
    typealias BaseType
    typealias ResultsType: CollectionType
    
    func fetchObjectWithType(type: BaseType.Type, keyValues: Dictionary<String, CVarArgType>) -> BaseType?
    func fetchObjectsWithType(type: BaseType.Type, predicate: NSPredicate) -> ResultsType
    func createObject(objType: BaseType.Type) -> BaseType
    func deleteObject(obj: BaseType)
    
    // TODO: Add threading model here or in separate protocol.
}

public class MappingContext {
    public var json: JSONValue
    public var object: Mappable
    public private(set) var dir: MappingDirection
    public internal(set) var error: ErrorType?
    
    init(withObject object:Mappable, json: JSONValue, direction: MappingDirection) {
        self.dir = direction
        self.object = object
        self.json = json
    }
}

// Global method caller used to perform mappings.
public struct CRMapper<T: Mappable, U: Mapping where U.MappedObject == T, T == U.AdaptorKind.BaseType> {
    
    func mapFromJSONToNewObject(json: JSONValue, mapping: U) throws -> T {
        let object = getInstance(mapping)
        return try mapFromJSON(json, toObject: object, mapping: mapping)
    }
    
    func mapFromJSON(json: JSONValue, var toObject object: T, mapping: U) throws -> T {
        let context = MappingContext(withObject: object, json: json, direction: MappingDirection.FromJSON)
        try performMappingWithObject(&object, mapping: mapping, context: context)
        return object
    }
    
    func mapFromObjectToJSON(var object: T, mapping: U) throws -> JSONValue {
        let context = MappingContext(withObject: object, json: JSONValue.JSONObject([:]), direction: MappingDirection.ToJSON)
        try performMappingWithObject(&object, mapping: mapping, context: context)
        return context.json
    }
    
    internal func performMappingWithObject(inout object: T, mapping: U, context: MappingContext) throws {
        mapping.mapping(object, context: context)
        if let error = context.error {
            throw error
        }
        context.object = object
    }
    
    internal func getInstance(mapping: U) -> T {
        return mapping.adaptor.createObject(T.self)
    }
}

// For Network lib have something along the lines of. Will need to properly handle the typing constraints.
// func registerMapping(mapping: Mapping, forPath path: URLPath)
