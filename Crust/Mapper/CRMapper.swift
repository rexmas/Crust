import Foundation
import RealmSwift

public enum MappingDirection {
    case FromJSON
    case ToJSON
}

public protocol CRMappingKey : JSONKeypath { }

extension String : CRMappingKey { }
extension Int : CRMappingKey { }

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

// Global method caller used to perform mappings.
public struct CRMapper<T: Mappable, U: Mapping where U.MappedObject == T, T == U.AdaptorKind.BaseType> {
    
    func mapFromJSONToNewObject(json: JSONValue, mapping: U) throws -> T {
        let object = getInstance(mapping)
        return try mapFromJSON(json, toObject: object, mapping: mapping)
    }
    
    func mapFromJSON(json: JSONValue, var toObject object: T, mapping: U) throws -> T {
        let context = CRMappingContext(withObject: object, json: json, direction: MappingDirection.FromJSON)
        try performMappingWithObject(&object, mapping: mapping, context: context)
        return object
    }
    
    func mapFromObjectToJSON(var object: T, mapping: U) throws -> JSONValue {
        let context = CRMappingContext(withObject: object, json: JSONValue.JSONObject([:]), direction: MappingDirection.ToJSON)
        try performMappingWithObject(&object, mapping: mapping, context: context)
        return context.json
    }
    
    internal func performMappingWithObject(inout object: T, mapping: U, context: CRMappingContext) throws {
        mapping.mapping(object, context: context)
        if let error = context.error {
            throw error
        }
        context.object = object
    }
    
    internal func getInstance(mapping: U) -> T {
        return mapping.adaptor.createObject(T.self)
    }
}

extension Employee: Mappable {
    
}

class EmployeeMapping : Mapping {
    var adaptor: RealmAdaptor
    var primaryKeys: Array<CRMappingKey> {
        return [ "uuid" ]
    }
    
    init(adaptor: RealmAdaptor) {
        self.adaptor = adaptor
    }
    
    func mapping(tomap: Employee, context: CRMappingContext) {
        
//        tomap.employer <- "employer" >*<
        //        var i: NSDate?
        //        mapField(&i, map: (key: "joinDate", context: context))
        
        tomap.joinDate <- "joinDate"  >*<
        tomap.uuid <- "uuid" >*<
        tomap.name <- "name" >*<
        tomap.joinDate <- "joinDate"  >*<
        tomap.salary <- "data.salary"  >*<
        tomap.isEmployeeOfMonth <- "data.is_employee_of_month"  >*<
        tomap.percentYearlyRaise <- "data.percent_yearly_raise" >*<
        context
    }
}

public protocol Mapping {
    typealias MappedObject: Mappable
    typealias AdaptorKind: Adaptor
    
    var adaptor: AdaptorKind { get }
    var primaryKeys: Array<CRMappingKey> { get }
    
    func mapping(tomap: MappedObject, context: CRMappingContext)
}

// Do we need this in the end?
public protocol Mappable {
}

public protocol Adaptor {
    typealias BaseType
    typealias ResultsType: CollectionType
    
    func fetchObjectWithType(type: BaseType.Type, keyValues: Dictionary<String, CVarArgType>) -> BaseType?
    func fetchObjectsWithType(type: BaseType.Type, predicate: NSPredicate) -> ResultsType
    func createObject(objType: BaseType.Type) -> BaseType
    func deleteObject(obj: BaseType)
    
    // TODO: Add threading model here or in separate protocol.
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
    
    func createObject(objType: BaseType.Type) -> BaseType {
        return objType.init()
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

// For Network lib have something along the lines of. Will need to properly handle the typing constraints.
// func registerMapping(mapping: Mapping, forPath path: URLPath)
