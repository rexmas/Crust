import Foundation

public struct AnyAdaptorImp<T: AnyMappable> : AnyAdaptor {
    public typealias BaseType = T
    public init() { }
}

public protocol AnyMappable : Mappable {
    init()
}

public protocol AnyMapping : Mapping {
    typealias AdaptorKind: AnyAdaptor = AnyAdaptorImp<MappedObject>
    typealias MappedObject: AnyMappable
}

public extension AnyMapping {
    var adaptor: AnyAdaptorImp<MappedObject> {
        return AnyAdaptorImp<MappedObject>()
    }
    
    var primaryKeys: Array<CRMappingKey> {
        return []
    }
}

public protocol AnyAdaptor : Adaptor {
    typealias BaseType: AnyMappable
    typealias ResultsType = Array<BaseType>
}

public extension AnyAdaptor {
    
    func mappingBegins() throws { }
    func mappingEnded() throws { }
    func mappingErrored(error: ErrorType) { }
    
    func fetchObjectWithType(type: BaseType.Type, keyValues: Dictionary<String, CVarArgType>) -> BaseType? {
        return nil
    }
    
    func fetchObjectsWithType(type: BaseType.Type, predicate: NSPredicate) -> Array<BaseType> {
        return Array<BaseType>()
    }
    
    func createObject(objType: BaseType.Type) throws -> BaseType {
        return objType.init()
    }
    
    func deleteObject(obj: BaseType) throws { }
    func saveObjects(objects: [ BaseType ]) throws { }
}
