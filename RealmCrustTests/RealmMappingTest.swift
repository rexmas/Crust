import XCTest
import Crust
import Realm

class RealmMappingTest: XCTestCase {
    var realm: RLMRealm!
    var adapter: RealmAdapter!
    
    override func setUp() {
        super.setUp()
        
        // Use an in-memory Realm identified by the name of the current test.
        // This ensures that each test can't accidentally access or modify the data
        // from other tests or the application itself, and because they're in-memory,
        // there's nothing that needs to be cleaned up.
        let config = RLMRealmConfiguration()
        config.inMemoryIdentifier = self.name
        RLMRealmConfiguration.setDefault(config)
        realm = RLMRealm.default()
        
        adapter = RealmAdapter(realm: realm)
    }
}


