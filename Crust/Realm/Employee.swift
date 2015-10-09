//
//  Employee.swift
//  Crust
//
//  Created by Lucas Swift on 10/8/15.
//  Copyright © 2015 Lucas Swift. All rights reserved.
//

import RealmSwift

class Employee: Object {
    
    dynamic var employer: Company?
    dynamic var uuid: String?
    dynamic var name: String?
    dynamic var joinDate: NSDate?
    dynamic var salary: Int64?
    dynamic var isEmployeeOfMonth: Bool?
    dynamic var percentYearlyRaise: Double?
    
// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return []
//  }
}
