import Crust

class MockAdapter<T: AnyMappable>: Adapter {
    var deletedObjects = [T]()
    
    typealias BaseType = T
    typealias ResultsType = [T]
    
    func mappingBegins() throws { }
    func mappingEnded() throws { }
    func mappingErrored(_ error: Error) { }
    public func sanitize(primaryKeyProperty property: String, forValue value: CVarArg, ofType type: T.Type) -> CVarArg? { return nil }
    func fetchObjects(type: BaseType.Type, primaryKeyValues: [[String : CVarArg]], isMapping: Bool) -> ResultsType? { return [] }
    func createObject(type: BaseType.Type) throws -> BaseType { return type.init() }
    func deleteObject(_ obj: BaseType) throws { deletedObjects.append(obj) }
    func save(objects: [ BaseType ]) throws { }
}

protocol MockMapping: Mapping {
    associatedtype BaseType: AnyMappable
    init(adapter: MockAdapter<BaseType>)
}
