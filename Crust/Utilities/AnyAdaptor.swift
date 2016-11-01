/// `MappedObject` type constraint required in `AnyMapping`.
public protocol AnyMappable {
    init()
}

/// A `Mapping` that does not require an adaptor of `typealias AdaptorKind`.
/// Use for structs or classes that require no storage when mapping.
public protocol AnyMapping: Mapping {
    associatedtype AdaptorKind: AnyAdaptor = AnyAdaptorImp<MappedObject>
    associatedtype MappedObject: AnyMappable
}

public extension AnyMapping {
    var adaptor: AnyAdaptorImp<MappedObject> {
        return AnyAdaptorImp<MappedObject>()
    }
    
    var primaryKeys: Dictionary<String, CRMappingKey>? {
        return nil
    }
}

/// Used internally to remove the need for structures conforming to `AnyMapping`
/// to specify a `typealias AdaptorKind`.
public struct AnyAdaptorImp<T: AnyMappable>: AnyAdaptor {
    public typealias BaseType = T
    public init() { }
}

/// A bare-bones `Adaptor`.
///
/// Conforming to `AnyAdaptor` automatically implements the requirements for `Adaptor`
/// outside of specifying the `BaseType`.
public protocol AnyAdaptor: Adaptor {
    associatedtype BaseType: AnyMappable
    associatedtype ResultsType = Array<BaseType>
}

public extension AnyAdaptor {
    
    func mappingBegins() throws { }
    func mappingEnded() throws { }
    func mappingErrored(_ error: Error) { }
    
    func fetchObjectsWithType(_ type: BaseType.Type, keyValues: Dictionary<String, CVarArg>) -> Array<BaseType>? {
        return nil
    }
    
    func createObject(_ objType: BaseType.Type) throws -> BaseType {
        return objType.init()
    }
    
    func deleteObject(_ obj: BaseType) throws { }
    func saveObjects(_ objects: [ BaseType ]) throws { }
}
