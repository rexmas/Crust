import Foundation
import Crust

struct Person : AnyMappable {
    
    var bankAccounts: NSArray = [ 1234, 5678 ]
}

class PersonMapping : AnyMapping {
    
    typealias MappedObject = Person
    
    var primaryKeys: Array<CRMappingKey> {
        return []
    }
    
    func mapping(tomap: Person, context: MappingContext) {
        
    }
}
