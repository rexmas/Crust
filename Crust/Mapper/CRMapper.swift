import Foundation
import RealmSwift

public enum MappingDirection {
    case FromJSON
    case ToJSON
}

public protocol CRMappingKey : JSONKeypath { }

extension Dictionary where Value : JSONable, Value.J == Value {
    
    public static func toJSON(x: Dictionary<String, Value>) -> JSONValue {
        return JDictionary<Value, Value>.toJSON(x)
    }
    
    public static func fromJSON(x: JSONValue) -> Dictionary<String, Value>? {
        return JDictionary<Value, Value>.fromJSON(x)
    }
}

extension Set where Element : JSONable, Element.J == Element {
    
    public static func toJSON(x: Set<Element>) -> JSONValue {
        let array = Array(x)
        return JArray<Element, Element>.toJSON(array)
    }
    
    public static func fromJSON(x: JSONValue) -> Set<Element>? {
        if let array = JArray<Element, Element>.fromJSON(x) {
            return Set(array)
        } else {
            return nil
        }
    }
}

//extension Array : JSON {
//    
//    public static func toJSON(xs: Array) -> JSONValue {
//        for x in xs {
//            switch x {
//            case is JSON:
//            break
//            default:
//            break
//            }
//        }
//        return self.toJSON(self)
//    }
//    
//    public static func fromJSON(x: JSONValue) -> Array? {
//        <#code#>
//    }
//    
//    func toJSON<T: JSON>(x: Array<T>) -> JSONValue {
//        
//    }
//}

extension Array where Element : JSONable, Element.J == Element {
    
    public func toJSON(x: Array<Element>) -> JSONValue {
        return JArray<Element, Element>.toJSON(x)
    }
    
    public func fromJSON(x: JSONValue) -> Array? {
        return JArray<Element, Element>.fromJSON(x)
    }
}

//extension Array : CRFieldType {
//    public func asJSON() -> Result<JSONValue> {
//        
//        switch Element.self {
//        case is CRFieldType.Type:
//            
//            var resultArray = Array<JSONValue>()
//            
//            for val in self {
//                let val = val as! CRFieldType
//                let result = val.asJSON()
//                
//                switch result {
//                case .Value(let val):
//                    print(val)
//                    resultArray.append(val)
//                    print(resultArray)
//                case .Error(_):
//                    return result
//                }
//            }
//            print(resultArray)
//            return Result.Value(JSONValue.JSONArray(resultArray))
//            
//        default:
//            return Result.Error(NSError(domain: "", code: 0, userInfo: nil))
//        }
//    }
//}

public enum CRMapping : CRMappingKey {
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

public class CRMappingContext {
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

// Global methods caller uses to perform mappings.
public struct CRMapper<T: Mappable> {
    
    func mapFromJSONToObject(json: JSONValue) throws -> T {
        let object = getInstance()
        return try mapFromJSON(json, toObject: object)
    }
    
    func mapFromJSON(json: JSONValue, var toObject object: T) throws -> T {
        let context = CRMappingContext(withObject: object, json: json, direction: MappingDirection.FromJSON)
        try performMappingWithObject(&object, context: context)
        return object
    }
    
    func mapFromObjectToJSON(var object: T) throws -> JSONValue {
        let context = CRMappingContext(withObject: object, json: JSONValue.JSONObject([:]), direction: MappingDirection.ToJSON)
        try performMappingWithObject(&object, context: context)
        return context.json
    }
    
    internal func performMappingWithObject(inout object: T, context: CRMappingContext) throws {
        object.mapping(context)
        if let error = context.error {
            throw error
        }
        context.object = object
    }
    
    internal func getInstance() -> T {
        // TODO: Find by foreignKeys else...
        return T.newInstance() as! T
    }
}

extension Employee: Mappable {
    
}

class EmployeeMapping : Mapping {
    func mapping(tomap: Employee, context: CRMappingContext) {
        
    }
}

public protocol Mappable {
    static func newInstance() -> Self
    static func primaryKeys() -> Array<CRMappingKey>
    mutating func mapping(context: CRMappingContext)
}

public protocol Adaptor {
    typealias BaseType
    typealias ResultsType: CollectionType
    
    func fetchObjectWithType(type: BaseType.Type, keyValues: Dictionary<String, CVarArgType>) -> BaseType?
    func fetchObjectsWithType(type: BaseType.Type, predicate: NSPredicate) -> ResultsType
    func createObject(obj: BaseType) -> BaseType
    func deleteObject(obj: BaseType)
}

class RealmAdaptor : Adaptor {
    
    typealias BaseType = Object
    typealias ResultsType = Results<Object>
    
    var realm: Realm
    
    init(realm: Realm) {
        self.realm = realm
    }
    
    convenience init() throws {
        self.init(realm: try Realm())
    }
    
    func createObject(obj: BaseType) -> BaseType {
        return Object()
    }
    
    func deleteObject(obj: BaseType) {
        realm.write {
            self.realm.delete(obj)
        }
    }
    
    func fetchObjectWithType(type: BaseType.Type, keyValues: Dictionary<String, CVarArgType>) -> BaseType? {
        
        var predicates = Array<NSPredicate>()
        for (key, value) in keyValues {
            let predicate = NSPredicate(format: "%@ = %@", key, value)
            predicates.append(predicate)
        }
        
        let andPredicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: predicates)
        
        return fetchObjectsWithType(type, predicate: andPredicate).first
    }
    
    func fetchObjectsWithType(type: BaseType.Type, predicate: NSPredicate) -> ResultsType {
        
        return realm.objects(type).filter(predicate)
    }
}

protocol Mapping {
    typealias MappedObject: Mappable
    typealias AdaptorKind: Adaptor
    
    var adaptor: AdaptorKind { get }
    
    func foreignKeys() -> Array<CRMappingKey>
    mutating func mapping(tomap: MappedObject, context: CRMappingContext)
}

// Have something along the lines of.
// func registerMapping(mapping: Mapping, forPath path: URLPath)
