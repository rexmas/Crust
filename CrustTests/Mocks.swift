import Crust

class MockAdapter<T: AnyMappable>: Adapter {
    var deletedObjects = [T]()
    var numberOfCallsToMappingWillBegin: Int = 0
    
    typealias BaseType = T
    typealias ResultsType = [T]
    
    var dataBaseTag: String = "none"
    var isInTransaction: Bool = false
    func mappingWillBegin() throws {
        self.numberOfCallsToMappingWillBegin += 1
        self.isInTransaction = true
    }
    func mappingDidEnd() throws { }
    func mappingErrored(_ error: Error) { }
    func sanitize(primaryKeyProperty property: String, forValue value: CVarArg, ofType type: T.Type) -> CVarArg? { return nil }
    func fetchObjects(baseType type: BaseType.Type, primaryKeyValues: [[String : CVarArg]], isMapping: Bool) -> ResultsType? { return [] }
    func createObject(baseType type: BaseType.Type) throws -> BaseType { return type.init() }
    func deleteObject(_ obj: BaseType) throws { deletedObjects.append(obj) }
    func save(objects: [ BaseType ]) throws { }
}

protocol MockMapping: Mapping {
    associatedtype BaseType: AnyMappable
    init(adapter: MockAdapter<BaseType>)
}
