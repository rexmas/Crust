import Crust

class MockAdapter<T: AnyMappable>: Adapter {
    var deletedObjects = [T]()
    var numberOfCallsToMappingBegins: Int = 0
    
    typealias BaseType = T
    typealias ResultsType = [T]
    
    var mappingDidBegin: Bool = false
    func mappingBegins() throws {
        self.numberOfCallsToMappingBegins += 1
        self.mappingDidBegin = true
    }
    func mappingEnded() throws { }
    func mappingErrored(_ error: Error) { }
    func sanitize(primaryKeyProperty property: String, forValue value: CVarArg, ofType type: T.Type) -> CVarArg? { return nil }
    func fetchObjects(type: BaseType.Type, primaryKeyValues: [[String : CVarArg]], isMapping: Bool) -> ResultsType? { return [] }
    func createObject(type: BaseType.Type) throws -> BaseType { return type.init() }
    func deleteObject(_ obj: BaseType) throws { deletedObjects.append(obj) }
    func save(objects: [ BaseType ]) throws { }
}

protocol MockMapping: Mapping {
    associatedtype BaseType: AnyMappable
    init(adapter: MockAdapter<BaseType>)
}
