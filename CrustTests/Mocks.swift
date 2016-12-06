import Crust

class MockAdaptor<T: AnyMappable>: Adaptor {
    typealias BaseType = T
    typealias ResultsType = Array<T>
    
    func mappingBegins() throws { }
    func mappingEnded() throws { }
    func mappingErrored(_ error: Error) { }
    
    func fetchObjectsWithType(_ type: BaseType.Type, keyValues: Dictionary<String, CVarArg>) -> ResultsType? { return [] }
    func createObject(_ objType: BaseType.Type) throws -> BaseType { return objType.init() }
    func deleteObject(_ obj: BaseType) throws { }
    func saveObjects(_ objects: [ BaseType ]) throws { }
}

protocol MockMapping: Mapping {
    associatedtype BaseType: AnyMappable
    init(adaptor: MockAdaptor<BaseType>)
}
