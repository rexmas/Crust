import Foundation

extension NSNumber {
    
    var isBool : Bool {
        
        let trueNumber = NSNumber(bool: true)
        let falseNumber = NSNumber(bool: false)
        let trueObjCType = String.fromCString(trueNumber.objCType)
        let falseObjCType = String.fromCString(falseNumber.objCType)
        
        let objCType = String.fromCString(self.objCType)
        let isTrueNumber = (self.compare(trueNumber) == NSComparisonResult.OrderedSame && objCType == trueObjCType)
        let isFalseNumber = (self.compare(falseNumber) == NSComparisonResult.OrderedSame && objCType == falseObjCType)
        
        return isTrueNumber || isFalseNumber
    }
}

extension Dictionary {
    
    func mapValues<OutValue>(@noescape transform: Value throws -> OutValue) rethrows -> [Key : OutValue] {
        
        var outDict = [Key : OutValue]()
        try self.forEach { (key, value) in
            outDict[key] = try transform(value)
        }
        return outDict
    }
}