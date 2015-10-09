//
//  Company.swift
//  Crust
//
//  Created by Lucas Swift on 10/8/15.
//  Copyright © 2015 Lucas Swift. All rights reserved.
//

import RealmSwift

class Company: Object {
    
    let employees = List<Employee>()
    dynamic var uuid: String?
    dynamic var foundingDate: NSDate?
    dynamic var founder: Employee?
    dynamic var pendingLawsuits: Int64?
    
// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return []
//  }
}
