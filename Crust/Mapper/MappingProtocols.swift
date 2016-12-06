import Foundation
import JSONValueRX

public struct CRMappingOptions: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    public static let None = CRMappingOptions(rawValue: 0)
    public static let AllowDuplicatesInCollection = CRMappingOptions(rawValue: 1)
}

public protocol Mapping {
    associatedtype MappedObject
    associatedtype AdaptorKind: Adaptor
    
    var adaptor: AdaptorKind { get }
    var primaryKeys: Dictionary<String, Keypath>? { get }
    
    func mapping(_ tomap: inout MappedObject, context: MappingContext)
}

public protocol Adaptor {
    associatedtype BaseType
    associatedtype ResultsType: Collection
    
    func mappingBegins() throws
    func mappingEnded() throws
    func mappingErrored(_ error: Error)
    
    func fetchObjectsWithType(_ type: BaseType.Type, keyValues: Dictionary<String, CVarArg>) -> ResultsType?
    func createObject(_ objType: BaseType.Type) throws -> BaseType
    func deleteObject(_ obj: BaseType) throws
    func saveObjects(_ objects: [ BaseType ]) throws
}

public protocol Transform: AnyMapping {
    func fromJSON(_ json: JSONValue) throws -> MappedObject
    func toJSON(_ obj: MappedObject) -> JSONValue
}

public extension Transform {
    func mapping(_ tomap: inout MappedObject, context: MappingContext) {
        switch context.dir {
        case .fromJSON:
            do {
                try tomap = self.fromJSON(context.json)
            } catch let err as NSError {
                context.error = err
            }
        case .toJSON:
            context.json = self.toJSON(tomap)
        }
    }
}

public enum Spec<T: Mapping>: Keypath {
    case mapping(Keypath, T)
    indirect case mappingOptions(Spec, CRMappingOptions)
    
    public var keyPath: String {
        switch self {
        case .mapping(let keyPath, _):
            return keyPath.keyPath
        case .mappingOptions(let keyPath, _):
            return keyPath.keyPath
        }
    }
    
    public var options: CRMappingOptions {
        switch self {
        case .mappingOptions(_, let options):
            return options
        default:
            return [ .None ]
        }
    }
    
    public var mapping: T {
        switch self {
        case .mapping(_, let mapping):
            return mapping
        case .mappingOptions(let mapping, _):
            return mapping.mapping
        }
    }
}
