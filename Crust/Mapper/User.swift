struct User : Mappable {
    var derp: String
    var blah: Int
    var array: Array<Any>
    
    static func newInstance() -> Mappable {
        return User(derp: "", blah: 0, array: [])
    }
    
    static func foreignKeys() -> Array<CRMappingKey> {
        return [ "Blah" ]
    }
    
    mutating func mapping(context: CRMappingContext) {
        
        blah <- CRMapping.Transform("Blah", "Blah") >*<
        derp <- "Derp" >*<
        context
    }
}
