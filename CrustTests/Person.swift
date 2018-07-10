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
    
    struct Mapping: StringRawValueTransform {
        typealias MappedObject = HairColor
    }
}

struct Person: AnyMappable {
    var bankAccounts: [Int] = [ 1234, 5678 ]
    var attitude: String = "awesome"
    var hairColor: HairColor = .Unknown
    var ownsCat: Bool? = nil
}

enum PersonCodingKey: String, RawMappingKey {
    case bankAccounts = "bank_accounts"
    case attitude = "traits.attitude"
    case hairColor = "traits.bodily.hair_color"
    case ownsCat = "owns_cat"
}

class PersonMapping: AnyMapping {
    typealias MappedObject = Person
    
    func mapping(toMap: inout Person, payload: MappingPayload<PersonCodingKey>) {
        toMap.bankAccounts  <- (.bankAccounts, payload)
        toMap.attitude      <- (.attitude, payload)
        toMap.hairColor     <- (.mapping(.hairColor, HairColor.Mapping()), payload)
        toMap.ownsCat       <- (.ownsCat, payload)
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
