[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Crust.svg)](https://img.shields.io/cocoapods/v/Crust.svg)
[![Build Status](https://travis-ci.org/rexmas/Crust.svg)](https://travis-ci.org/rexmas/Crust)

## Crust
A flexible Swift framework for converting classes and structs to and from JSON with support for storage solutions such as Realm.

## Features 🎸
- [Structs and Classes](#structs-and-classes)
- [Separation of Concerns (Mapped Model, Mapping, Storage)](#separation-of-concerns)
- [Type safe JSON](#jsonvalue-for-type-safe-json)
- [How To Map](#how-to-map)
  - [Nested Mappings](#nested-mappings)
  - [Mapping Context](#mapping-context)
  - [Custom Transformations](#custom-transformations)
  - [Different Mappings for Same Model](#different-mappings-for-same-model)
- [Storage Adapter](#storage-adapter)
- [Realm](#realm)
- Supports Optional Types and Collections.

## Requirements
iOS 8.0+
Swift 3.0+

## Installation
### CocoaPods
```
platform :ios, '8.0'
use_frameworks!

pod 'Crust'
```

## Structs and Classes
Can map to/from classes or structs
```swift
class Company {
    var employees = Array<Employee>()
    var uuid: String = ""
    var name: String = ""
    var foundingDate: NSDate = NSDate()
    var founder: Employee?
    var pendingLawsuits: Int = 0
}
```
If you have no need for storage, which will generaly be the case for structs, use `AnyMappable`.
```swift
struct Person: AnyMappable {
    var bankAccounts: Array<Int> = [ 1234, 5678 ]
    var attitude: String = "awesome"
    var hairColor: HairColor = .Unknown
    var ownsCat: Bool? = nil
}
```

## Separation of Concerns

By design Crust is built with [separation of concerns](https://en.wikipedia.org/wiki/Separation_of_concerns) in mind. It makes no assumptions about how many ways a user would like to map to and from JSON and how many various ways the user would like to store their models.

Crust has 2 basic protocols:
- `Mapping`
	- How to map JSON to and from a particular model - (model is set by the `associatedtype MappedObject` if mapping to an sequence of objects set `associatedtype SequenceKind`).
	- May include primary key(s) and nested mapping(s).
- `Adapter`
	- How to store and retrieve model objects used for mapping from a backing store (e.g. Core Data, Realm, etc.).

And 2 additional protocols when no storage `Adapter` is required:
- `AnyMappable`
	- Inherited by the model (class or struct) to be mapped to and from JSON.
- `AnyMapping`
	- A `Mapping` that does not require an `Adapter`.

There are no limitations on the number of various `Mapping`s and `Adapter`s one may create per model for different use cases.

## JSONValue for type safe JSON
Crust relies on [JSONValue](https://github.com/rexmas/JSONValue) for it's JSON encoding and decoding mechanism. It offers many benefits including type safety, subscripting, and extensibility through protocols.

## How To Map

1. Create your mappings for your model using `Mapping` if with storage or `AnyMapping` if without storage.

    With storage (assume `CoreDataAdapter` conforms to `Adapter`)
    ```swift
    class EmployeeMapping: Mapping {
    
        var adapter: CoreDataAdapter
        var primaryKeys: [PrimaryKeyDescriptor]? {
            // property == attribute on the model, keyPath == keypath in the JSON blob, transform == tranform to apply to data from JSON blob.
            return [ (property: "uuid", keyPath: "data.uuid", transform: nil) ]
        }

        required init(adapter: CoreDataAdapter) {
            self.adapter = adapter
        }
    
        func mapping(toMap: inout Employee, context: MappingContext) {
            // Company must be transformed into something Core Data can use in this case.
            let companyMapping = CompanyTransformableMapping()
            
            // No need to map the primary key here.
            toMap.employer              <- .mapping("company", companyMapping) >*<
            toMap.name                  <- "data.name" >*<
            context
        }
    }
    ```
    Without storage
    ```swift
    class CompanyMapping: AnyMapping {
        // associatedtype MappedObject = Company is inferred by `toMap`
    
        func mapping(toMap: inout Company, context: MappingContext) {
            let employeeMapping = EmployeeMapping(adapter: CoreDataAdapter())
        
            toMap.employees             <- .mapping("employees", employeeMapping) >*<
            toMap.founder               <- .mapping("founder", employeeMapping) >*<
            toMap.uuid                  <- "uuid" >*<
            toMap.name                  <- "name" >*<
            toMap.foundingDate          <- "data.founding_date"  >*<
            toMap.pendingLawsuits       <- "data.lawsuits.pending"  >*<
            context
        }
    }
    ```

2. Create your Crust Mapper.
    ```swift
    let mapper = Mapper()
    ```

3. Use the mapper to convert to and from `JSONValue` objects
    ```swift
    let json = try! JSONValue(object: [
                "uuid" : "uuid123",
                "name" : "name",
                "employees" : [
                    [ "name" : "Fred", "uuid" : "ABC123" ],
                    [ "name" : "Wilma", "uuid" : "XYZ098" ]
                ]
                "founder" : NSNull(),
                "data" : [
                    "lawsuits" : [
                        "pending" : 5
                    ]
                ],
                "data.founding_date" : NSDate().toISOString(),
            ]
    )

    let company: Company = try! mapper.map(from: json, using: CompanyMapping())

    // Or if json is an array.
    let company: [Company] = try! mapper.map(from: json, using: CompanyMapping())
    ```

NOTE:
`JSONValue` can be converted back to an `AnyObject` variation of json via `json.values()` and to `NSData` via `try! json.encode()`.

### Nested Mappings
Crust supports nested mappings for nested models
E.g. from above
```swift
func mapping(inout toMap: Company, context: MappingContext) {
    let employeeMapping = EmployeeMapping(adapter: CoreDataAdapter())
    
    toMap.employees <- Binding.mapping("employees", employeeMapping) >*<
    context
}
```

### Binding and collections

`Binding` provides specialized directives when mapping collections. Use the `.collectionMapping` case to inform the mapper of these directives. They include
* replace and/or delete objects
* append objects to the collection
* unique objects in collection (merge duplicates)
  * Latest object overwrites existing object on merge.
  * Uniquing only works if the `Element` of the collection being mapped to follows `Equatable`.
  * If the `Element` does not follow `Equatable` it is also possible to use `map(toCollection field:, using binding:, elementEquality:, indexOf:, contains:)` to provide explicit comparison / indexing functions required for uniquing.
* Accept "null" values to map from the collection.

This table provides some examples of how "null" json values are mapped depending on the type of Collection being mapped to and given the value of `nullable` and whether values or "null" are present in the JSON payload.

| append / replace  | nullable  | vals / null | Array     | Array?      | RLMArray  |
|-------------------|-----------|-------------|-----------|-------------|-----------|
| append            | yes or no | vals        | append    | append      | append    |
| append            | yes       | null        | no-op     | no-op       | no-op     |
| replace           | yes or no | vals        | replace   | replace     | replace   |
| replace           | yes       | null        | removeAll | assign null | removeAll |
| append or replace | no        | null        | error     | error       | error     |

By default using `.mapping` will `(insert: .replace(delete: nil), unique: true, nullable: true)`.

```swift
public enum CollectionInsertionMethod<Container: Sequence> {
    case append
    case replace(delete: ((_ orphansToDelete: Container) -> Container)?)
}

public typealias CollectionUpdatePolicy<Container: Sequence> =
    (insert: CollectionInsertionMethod<Container>, unique: Bool, nullable: Bool)

public enum Binding<M: Mapping>: Keypath {
    case mapping(Keypath, M)
    case collectionMapping(Keypath, M, CollectionUpdatePolicy<M.SequenceKind>)
}
```

Usage:
```swift
let employeeMapping = EmployeeMapping(adapter: CoreDataAdapter())
let binding = Binding.collectionMapping("", employeeMapping, (.replace(delete: nil), true, true))
toMap.employees <- (binding, context)
```
Look in ./Mapper/MappingProtocols.swift for more.

### Mapping Context
Every `mapping` passes through a `context: MappingContext` which must be included during the mapping. The `context` includes error information that is propagated back from the mapping to the caller and contextual information about the json and object being mapped to/from.

There are two ways to include the context during mapping:

1. Include it as a tuple.

   ```swift
   func mapping(inout toMap: Company, context: MappingContext) {
       toMap.uuid <- ("uuid", context)
       toMap.name <- ("name", context)
   }
   ```
2. Use a specially included operator `>*<` which merges the result of the right expression with the left expression into a tuple. This may be chained in succession.

   ```swift
   func mapping(inout toMap: Company, context: MappingContext) {
       toMap.uuid <- "uuid" >*<
       toMap.name <- "name" >*<
       context
   }
   ```

### Custom Transformations
To create a simple custom transformation (such as to basic value types) implement the `Transform` protocol
```swift
public protocol Transform: AnyMapping {
    func fromJSON(_ json: JSONValue) throws -> MappedObject
    func toJSON(_ obj: MappedObject) -> JSONValue
}
```
and use it like any other `Mapping`.

### Different Mappings for Same Model
Multiple `Mapping`s are allowed for the same model.
```swift
class CompanyMapping: AnyMapping {
    func mapping(inout toMap: Company, context: MappingContext) {
        toMap.uuid <- "uuid" >*<
        toMap.name <- "name" >*<
        context
    }
}

class CompanyMappingWithNameUUIDReversed: AnyMapping {
	func mapping(inout toMap: Company, context: MappingContext) {
        toMap.uuid <- "name" >*<
        toMap.name <- "uuid" >*<
        context
    }
}
```
Just use two different mappings.
```swift
let mapper = Mapper()
let company1 = try! mapper.map(from: json, using: CompanyMapping())
let company2 = try! mapper.map(from: json, using: CompanyMappingWithNameUUIDReversed())
```

## Storage Adapter
Follow the `Adapter` protocol to create a storage adapter to Core Data, Realm, etc.

The object conforming to `Adapter` must include two `associatedtype`s:
- `BaseType` - the top level class for this storage systems model objects.
  - Core Data this would be `NSManagedObject`.
  - Realm this would be `RLMObject`.
  - RealmSwift this would be `Object`.
- `ResultsType: Collection` - Used for object lookups. Should return a collection of `BaseType`s.

The `Mapping` must then set it's `associatedtype AdapterKind = <Your Adapter>` to use it during mapping.

## Realm
There are tests included in `./RealmCrustTests` that include examples of how to use Crust with realm-cocoa (Obj-C).

If you wish to use Crust with RealmSwift check out this (slightly outdated) repo for examples.
https://github.com/rexmas/RealmCrust

## Contributing

Pull requests are welcome!

- Open an issue if you run into any problems.
- Fork the project and submit a pull request to contribute. Please include tests for new code.

## License
The MIT License (MIT)

Copyright (c) 2015-2017 Rex

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
