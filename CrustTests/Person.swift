import Foundation
import Crust
import JSONValueRX

enum HairColor: String, AnyMappable {
    case Blue
    case Brown
    case Gold
    case Unknown
    
    init() {
        self = .Unknown
    }
}

struct Person: AnyMappable {
    
    var bankAccounts: [Int] = [ 1234, 5678 ]
    var attitude: String = "awesome"
    var hairColor: HairColor = .Unknown
    var ownsCat: Bool? = nil
}

class HairColorMapping: Transform {
    typealias MappedObject = HairColor
    
    func fromJSON(_ json: JSONValue) throws -> HairColor {
        switch json {
        case .string(let str):
            switch str {
            case "Gold":
                return .Gold
            case "Brown":
                return .Brown
            case "Blue":
                return .Blue
            default:
                return .Unknown
            }
        default:
            return .Unknown
        }
    }
    
    func toJSON(_ obj: HairColor) -> JSONValue {
        return .string(obj.rawValue)
    }
}

class PersonMapping: AnyMapping {
    
    typealias MappedObject = Person
    
    func mapping(toMap: inout Person, context: MappingContext) {
        toMap.bankAccounts  <- "bank_accounts" >*<
        toMap.attitude      <- "traits.attitude" >*<
        toMap.hairColor     <- .mapping("traits.bodily.hair_color", HairColorMapping()) >*<
        toMap.ownsCat       <- "owns_cat" >*<
        context
    }
}

class PersonStub {
    
    var bankAccounts: [Int] = [ 0987, 6543 ]
    var attitude: String = "whoaaaa"
    var hairColor: HairColor = .Blue
    var ownsCat: Bool? = true
    
    init() { }
    
    func generateJsonObject() -> [AnyHashable : Any] {
        var ownsCatVal: AnyObject
        if let cat = self.ownsCat {
            ownsCatVal = cat as AnyObject
        } else {
            ownsCatVal = NSNull()
        }
        
        return [
            "owns_cat" : ownsCatVal,
            "bank_accounts" : bankAccounts as AnyObject,
            "traits" : [
                "attitude" : attitude,
                "bodily" : [
                    "hair_color" : hairColor.rawValue
                ]
            ],
        ]
    }
    
    func matches(_ object: Person) -> Bool {
        var matches = true
        matches &&= attitude == object.attitude
        matches &&= hairColor == object.hairColor
        matches &&= bankAccounts == object.bankAccounts
        matches &&= ownsCat == object.ownsCat
        
        return matches
    }
}
