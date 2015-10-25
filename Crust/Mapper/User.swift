struct User : Mappable {
    var derp: String
    var blah: Int
    var array: Array<Any>
    
    static func newInstance() -> User {
        return User(derp: "", blah: 0, array: [])
    }
    
    static func foreignKeys() -> Array<CRMappingKey> {
        return [ "Blah" as CRMappingKey ]
    }
    
    mutating func mapping(context: MappingContext) {
        
        // TODO: fix compiler error. Likely do to operator precedence.
//        blah <- CRMapping.Transform("Blah", "Blah") >*<
        derp <- "Derp" >*<
        context
    }
}
