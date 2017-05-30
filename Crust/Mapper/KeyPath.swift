import Foundation
import JSONValueRX

enum CrustError: LocalizedError {
    case nestedCodingKeyError(type: Any.Type, keyPath: String)
    
    var errorDescription: String? {
        switch self {
        case .nestedCodingKeyError(let type, let keyPath):
            return "No nested coding key for type \(type) with keyPath \(keyPath)"
        }
    }
}

// TODO: Change to MappingKey
public protocol Keypath: JSONKeypath, DynamicMappingKey, Hashable {
    /// Return the collection of coding keys for a nested set of JSON. A non-nil value is required for every key
    /// that is used to key into JSON passed to a nested `Mapping`, otherwise the mapping operation
    /// for that nested type will fail and throw an error.
    ///
    /// - returns: Collection of MappingKeys for the nested JSON. `nil` on error - results in error during mapping.
    func nestedMappingKeys<Key: Keypath>() -> AnyKeyCollection<Key>?
}

public extension Keypath {
    public var hashValue: Int {
        return self.keyPath.hashValue
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.keyPath == rhs.keyPath
    }
}

public protocol DynamicMappingKey {
    func nestedMappingKeys<Key: Keypath>() -> AnyKeyCollection<Key>?
}

// Use in place of `MappingKey` if the keys have no nested values.
public protocol RawMappingKey: Keypath { }
extension RawMappingKey {
    public func nestedKeyCollection() -> AnyKeyPathKeyCollection? {
        return nil
    }
    
    public func nestedMappingKeys<K: Keypath>() -> AnyKeyCollection<K>? {
        return nil
    }
}

public extension RawRepresentable where Self: Keypath, RawValue == String {
    public var keyPath: String {
        return self.rawValue
    }
}

public struct RootKeyPath: Keypath {
    public let keyPath: String = ""
    public init() { }
    
    public func nestedKeyCollection() -> AnyKeyPathKeyCollection? {
        return AnyKeyPathKeyCollection(AnyKeyCollection([self]))
    }
    
    public func nestedMappingKeys<K: Keypath>() -> AnyKeyCollection<K>? {
        return AnyKeyCollection.wrapAs([self])
    }
}

extension String: RawMappingKey { }

extension Int: RawMappingKey { }

public struct AnyKeyPath: Keypath, ExpressibleByStringLiteral {
    public var hashValue: Int {
        return _hashValue()
    }
    private let _hashValue: () -> Int
    
    public var keyPath: String {
        return _keyPath()
    }
    private let _keyPath: () -> String
    
    public let type: Any.Type
    public let base: DynamicMappingKey
    
    public init<K>(_ base: K) where K: Keypath {
        self.base = base
        self.type = K.self
        self._keyPath = { base.keyPath }
        self._hashValue = { base.hashValue }
    }
    
    public func nestedMappingKeys<Key: Keypath>() -> AnyKeyCollection<Key>? {
        return self.base.nestedMappingKeys()
    }
    
    public typealias UnicodeScalarLiteralType = StringLiteralType
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(value)
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

// TODO: Change this to KeyContainer maybe.
public protocol KeyCollection: DynamicKeyCollection {
    associatedtype MappingKeyType: Keypath
    
    init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == MappingKeyType
    func containsKey(_ key: MappingKeyType) -> Bool
    func nestedKeyCollection<Key: Keypath>(`for` key: MappingKeyType) -> AnyKeyCollection<Key>?
}

public extension KeyCollection {
    public func nestedDynamicKeyCollection<Key: Keypath>(`for` key: Any) -> AnyKeyCollection<Key>? {
        guard case let key as MappingKeyType = key else {
            return nil
        }
        return self.nestedKeyCollection(for: key)
    }
    
    func nestedKeyCollection<Key: Keypath>(`for` key: MappingKeyType) throws -> AnyKeyCollection<Key> {
        guard let nested = (self.nestedKeyCollection(for: key) as AnyKeyCollection<Key>?) else {
            throw CrustError.nestedCodingKeyError(type: MappingKeyType.self, keyPath: key.keyPath)
        }
        return nested
    }
}

/// This exists to get around the fact that `AnyKeyCollection` cannot capture `nestedKeyCollection<K: Keypath>` in a closure.
public protocol DynamicKeyCollection {
    /// This exists to get around the fact that `AnyKeyCollection` cannot capture `nestedKeyCollection<K: Keypath>` in a closure.
    /// This is automatically implemented for `KeyCollection`.
    func nestedDynamicKeyCollection<Key: Keypath>(`for` key: Any) -> AnyKeyCollection<Key>?
}

public struct AnyKeyCollection<K: Keypath>: KeyCollection {
    public let mappingKeyType: K.Type
    public let keyProviderType: Any.Type
    private let _containsKey: (K) -> Bool
    private let dynamicKeyCollection: DynamicKeyCollection
    
    /// This function is really dumb. `AnyKeyCollection<K> as? AnyKeyCollection<K2>` always fails (though `Set<K> as? Set<K2>` doesn't)
    /// so we check and force cast here. This should be fixed in Swift 4.
    public static func wrapAs<P: KeyCollection, K2: Keypath>(_ keyProvider: P) -> AnyKeyCollection<K2>? where P.MappingKeyType == K {
        guard K.self is K2.Type else {
            return nil
        }
        let provider = AnyKeyCollection(keyProvider)
        return unsafeBitCast(provider, to: AnyKeyCollection<K2>.self)
    }
    
    public static func wrapAs<Source: Sequence, K2: Keypath>(_ keys: Source) -> AnyKeyCollection<K2>? where Source.Iterator.Element == K {
        guard K.self is K2.Type else {
            return nil
        }
        let provider = AnyKeyCollection(SetKeyCollection(keys))
        return unsafeBitCast(provider, to: AnyKeyCollection<K2>.self)
    }
    
    public init?(_ anyKeyPathKeyCollection: AnyKeyPathKeyCollection) {
        guard case let mappingKeyType as K.Type = anyKeyPathKeyCollection.mappingKeyType else {
            return nil
        }
        
        self.keyProviderType = anyKeyPathKeyCollection.keyProviderType
        self.mappingKeyType = mappingKeyType
        self._containsKey = { key in
            return anyKeyPathKeyCollection.containsKey(key)
        }
        self.dynamicKeyCollection = anyKeyPathKeyCollection
    }
    
    public init<P: KeyCollection>(_ keyProvider: P) where P.MappingKeyType == K {
        self.keyProviderType = P.self
        self.mappingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
        self.dynamicKeyCollection = keyProvider
    }
    
    public init(arrayLiteral elements: K...) {
        let keyProvider = SetKeyCollection(Set(elements))
        self.keyProviderType = type(of: keyProvider).self
        self.mappingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
        self.dynamicKeyCollection = keyProvider
    }
    
    public init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (K) {
        let keyProvider = SetKeyCollection(Set(sequence))
        self.keyProviderType = type(of: keyProvider).self
        self.mappingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
        self.dynamicKeyCollection = keyProvider
    }
    
    public func containsKey(_ key: K) -> Bool {
        return self._containsKey(key)
    }
    
    public func nestedKeyCollection<Key: Keypath>(for key: K) -> AnyKeyCollection<Key>? {
        return self.dynamicKeyCollection.nestedDynamicKeyCollection(for: key)
    }
}

public struct AnyKeyPathKeyCollection: KeyCollection {
    public let mappingKeyType: Any.Type
    public let keyProviderType: Any.Type
    private let _containsKey: (Any) -> Bool
    private let dynamicKeyCollection: DynamicKeyCollection
    
    public init<P: KeyCollection>(_ keyProvider: P) {
        self.mappingKeyType = P.MappingKeyType.self
        self._containsKey = { key in
            guard case let key as P.MappingKeyType = key else {
                return false
            }
            return keyProvider.containsKey(key)
        }
        self.keyProviderType = P.self
        self.dynamicKeyCollection = keyProvider
    }
    
    public init(_ anyKeyPathKeyCollection: AnyKeyPathKeyCollection) {
        self = anyKeyPathKeyCollection
    }
    
    public init<Source, KeyType: Keypath>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (KeyType) {
        let keyProvider = SetKeyCollection(Set(sequence))
        self.mappingKeyType = KeyType.self
        self._containsKey = { key in
            guard case let key as KeyType = key else {
                return false
            }
            return keyProvider.containsKey(key)
        }
        self.keyProviderType = SetKeyCollection<KeyType>.self
        self.dynamicKeyCollection = keyProvider
    }
    
    public func containsKey(_ key: AnyKeyPath) -> Bool {
        return self._containsKey(key)
    }
    
    public func containsKey<K: Keypath>(_ key: K) -> Bool {
        return self._containsKey(key)
    }
    
    public func nestedKeyCollection<Key: Keypath>(for key: AnyKeyPath) -> AnyKeyCollection<Key>? {
        return self.dynamicKeyCollection.nestedDynamicKeyCollection(for: key.base)
    }
}

public struct AllKeys<K: Keypath>: KeyCollection {
    public init() {}
    public init(arrayLiteral elements: K...) { }
    public init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (K) { }
    
    public func containsKey(_ key: K) -> Bool {
        return true
    }
    
    public func nestedKeyCollection<Key: Keypath>(for key: K) -> AnyKeyCollection<Key>? {
        return AnyKeyCollection(AllKeys<Key>())
    }
}

// TODO: Can make Set follow protocol once conditional conformances are available in Swift 4.
public struct SetKeyCollection<K: Keypath>: KeyCollection, ExpressibleByArrayLiteral {
    public let keys: Set<K>
    
    public init(_ keys: Set<K>) {
        self.keys = keys
    }
    
    public init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (K) {
        self.keys = Set(sequence)
    }
    
    public init(arrayLiteral elements: K...) {
        self.keys = Set(elements)
    }
    
    public init(array: [K]) {
        self.keys = Set(array)
    }
    
    public func containsKey(_ key: K) -> Bool {
        return self.keys.contains(key)
    }
    
    public func nestedKeyCollection<Key: Keypath>(for key: K) -> AnyKeyCollection<Key>? {
        guard let index = self.keys.index(of: key) else {
            return nil
        }
        let key = self.keys[index]
        return key.nestedMappingKeys()
    }
}

internal struct NestedMappingKey<RootKey: Keypath, NestedCollection: KeyCollection>: Keypath, KeyCollection {
    let rootKey: RootKey
    let nestedKeys: NestedCollection
    
    var keyPath: String {
        return self.rootKey.keyPath
    }
    
    init(rootKey: RootKey, nestedKeys: NestedCollection) {
        self.rootKey = rootKey
        self.nestedKeys = nestedKeys
    }
    
    @available(*, unavailable)
    init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (RootKey) {
        fatalError("Don't use this.")
    }
    
    func containsKey(_ key: RootKey) -> Bool {
        return key == rootKey
    }
    
    func nestedKeyCollection<Key: Keypath>(for key: RootKey) -> AnyKeyCollection<Key>? {
        return AnyKeyCollection.wrapAs(self.nestedKeys)
    }
    
    func nestedMappingKeys<Key: Keypath>() -> AnyKeyCollection<Key>? {
        return AnyKeyCollection.wrapAs(self.nestedKeys)
    }
}

public struct KeyedBinding<K: Keypath, M: Mapping> {
    public let binding: Binding<K, M>
    public let codingKeys: AnyKeyCollection<M.CodingKeys>
    
    public init<KC: KeyCollection>(binding: Binding<K, M>, codingKeys: KC) where KC.MappingKeyType == M.CodingKeys {
        self.binding = binding
        self.codingKeys = AnyKeyCollection(codingKeys)
    }
    
    public init(binding: Binding<K, M>, codingKeys: AnyKeyCollection<M.CodingKeys>) {
        self.binding = binding
        self.codingKeys = codingKeys
    }
    
    public init?(binding: Binding<K, M>, context: MappingContext<K>) throws {
        guard context.keys.containsKey(binding.key) else {
            return nil
        }
        
        let codingKeys: AnyKeyCollection<M.CodingKeys> = try {
            if M.CodingKeys.self is RootKeyPath.Type {
                return AnyKeyCollection([RootKeyPath() as! M.CodingKeys])
            }
            
            return try context.keys.nestedKeyCollection(for: binding.key)
        }()
        
        self.init(binding: binding, codingKeys: codingKeys)
    }
}
