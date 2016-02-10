import Crust

class MockAdaptor<T: AnyMappable> : Adaptor {
    typealias BaseType = T
    typealias ResultsType = Array<T>
    
    func mappingBegins() throws { }
    func mappingEnded() throws { }
    func mappingErrored(error: ErrorType) { }
    
    func fetchObjectsWithType(type: BaseType.Type, keyValues: Dictionary<String, CVarArgType>) -> ResultsType? { return [] }
    func createObject(objType: BaseType.Type) throws -> BaseType { return objType.init() }
    func deleteObject(obj: BaseType) throws { }
    func saveObjects(objects: [ BaseType ]) throws { }
}

protocol MockMapping : Mapping {
    typealias BaseType: AnyMappable
    init(adaptor: MockAdaptor<BaseType>)
}
