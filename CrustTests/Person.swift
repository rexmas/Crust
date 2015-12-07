import Foundation
import Crust

struct Person : AnyMappable {
    
    var bankAccounts: NSArray = [ 1234, 5678 ]
    var attitude: String = "awesome"
}

class PersonMapping : AnyMapping {
    
    typealias MappedObject = Person
    
    var primaryKeys: Array<CRMappingKey> {
        return []
    }
    
    func mapping(var tomap: Person, context: MappingContext) {
        tomap.attitude <- "traits.attitude" >*<
        context
    }
}

class PersonStub {
    
    var bankAccounts: NSArray = [ 0987, 6543 ]
    var attitude: String = "whoaaaa"
    
    init() { }
    
    func generateJsonObject() -> Dictionary<String, AnyObject> {
        return [
            "traits" : [
                "attitude" : "chill"
            ],
        ]
    }
    
    func matches(object: Person) -> Bool {
        var matches = true
        matches &&= attitude == object.attitude
        
        return matches
    }
}
