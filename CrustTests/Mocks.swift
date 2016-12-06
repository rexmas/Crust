import Crust

class MockAdaptor<T: AnyMappable>: Adaptor {
    typealias BaseType = T
    typealias ResultsType = [T]
    
    func mappingBegins() throws { }
    func mappingEnded() throws { }
    func mappingErrored(_ error: Error) { }
    
    func fetchObjects(type: BaseType.Type, keyValues: [String : CVarArg]) -> ResultsType? { return [] }
    func createObject(type: BaseType.Type) throws -> BaseType { return type.init() }
    func deleteObject(_ obj: BaseType) throws { }
    func save(objects: [ BaseType ]) throws { }
}

protocol MockMapping: Mapping {
    associatedtype BaseType: AnyMappable
    init(adaptor: MockAdaptor<BaseType>)
}
