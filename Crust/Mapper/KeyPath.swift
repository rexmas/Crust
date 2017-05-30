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
    func nestedMappingKeys<Key: Keypath>() -> AnyKeyProvider<Key>?
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
    func nestedMappingKeys<Key: Keypath>() -> AnyKeyProvider<Key>?
}

// Use in place of `MappingKey` if the keys have no nested values.
public protocol RawMappingKey: Keypath { }
extension RawMappingKey {
    public func nestedKeyCollection() -> AnyKeyPathKeyProvider? {
        return nil
    }
    
    public func nestedMappingKeys<K: Keypath>() -> AnyKeyProvider<K>? {
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
    
    public func nestedKeyCollection() -> AnyKeyPathKeyProvider? {
        return AnyKeyPathKeyProvider(AnyKeyProvider([self]))
    }
    
    public func nestedMappingKeys<K: Keypath>() -> AnyKeyProvider<K>? {
        return AnyKeyProvider.wrapAs([self])
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
    
    public func nestedMappingKeys<Key: Keypath>() -> AnyKeyProvider<Key>? {
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
public protocol KeyCollection: DynamicKeyProvider {
    associatedtype MappingKeyType: Keypath
    
    init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == MappingKeyType
    func containsKey(_ key: MappingKeyType) -> Bool
    func nestedKeyCollection<Key: Keypath>(`for` key: MappingKeyType) -> AnyKeyProvider<Key>?
}

public extension KeyCollection {
    public func nestedDynamicKeyCollection<Key: Keypath>(`for` key: Any) -> AnyKeyProvider<Key>? {
        guard case let key as MappingKeyType = key else {
            return nil
        }
        return self.nestedKeyCollection(for: key)
    }
    
    func nestedKeyCollection<Key: Keypath>(`for` key: MappingKeyType) throws -> AnyKeyProvider<Key> {
        guard let nested = (self.nestedKeyCollection(for: key) as AnyKeyProvider<Key>?) else {
            throw CrustError.nestedCodingKeyError(type: MappingKeyType.self, keyPath: key.keyPath)
        }
        return nested
    }
}

/// This exists to get around the fact that `AnyKeyProvider` cannot capture `nestedKeyCollection<K: Keypath>` in a closure.
public protocol DynamicKeyProvider {
    /// This exists to get around the fact that `AnyKeyProvider` cannot capture `nestedKeyCollection<K: Keypath>` in a closure.
    /// This is automatically implemented for `KeyProvider`.
    func nestedDynamicKeyCollection<Key: Keypath>(`for` key: Any) -> AnyKeyProvider<Key>?
}

public struct AnyKeyProvider<K: Keypath>: KeyCollection {
    public let mappingKeyType: K.Type
    public let keyProviderType: Any.Type
    private let _containsKey: (K) -> Bool
    private let dynamicKeyProvider: DynamicKeyProvider
    
    /// This function is really dumb. `AnyKeyProvider<K> as? AnyKeyProvider<K2>` always fails (though `Set<K> as? Set<K2>` doesn't)
    /// so we check and force cast here. This should be fixed in Swift 4.
    public static func wrapAs<P: KeyCollection, K2: Keypath>(_ keyProvider: P) -> AnyKeyProvider<K2>? where P.MappingKeyType == K {
        guard K.self is K2.Type else {
            return nil
        }
        let provider = AnyKeyProvider(keyProvider)
        return unsafeBitCast(provider, to: AnyKeyProvider<K2>.self)
    }
    
    public static func wrapAs<Source: Sequence, K2: Keypath>(_ keys: Source) -> AnyKeyProvider<K2>? where Source.Iterator.Element == K {
        guard K.self is K2.Type else {
            return nil
        }
        let provider = AnyKeyProvider(SetKeyProvider(keys))
        return unsafeBitCast(provider, to: AnyKeyProvider<K2>.self)
    }
    
    public init?(_ anyKeyPathKeyProvider: AnyKeyPathKeyProvider) {
        guard case let mappingKeyType as K.Type = anyKeyPathKeyProvider.mappingKeyType else {
            return nil
        }
        
        self.keyProviderType = anyKeyPathKeyProvider.keyProviderType
        self.mappingKeyType = mappingKeyType
        self._containsKey = { key in
            return anyKeyPathKeyProvider.containsKey(key)
        }
        self.dynamicKeyProvider = anyKeyPathKeyProvider
    }
    
    public init<P: KeyCollection>(_ keyProvider: P) where P.MappingKeyType == K {
        self.keyProviderType = P.self
        self.mappingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
        self.dynamicKeyProvider = keyProvider
    }
    
    public init(arrayLiteral elements: K...) {
        let keyProvider = SetKeyProvider(Set(elements))
        self.keyProviderType = type(of: keyProvider).self
        self.mappingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
        self.dynamicKeyProvider = keyProvider
    }
    
    public init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (K) {
        let keyProvider = SetKeyProvider(Set(sequence))
        self.keyProviderType = type(of: keyProvider).self
        self.mappingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
        self.dynamicKeyProvider = keyProvider
    }
    
    public func containsKey(_ key: K) -> Bool {
        return self._containsKey(key)
    }
    
    public func nestedKeyCollection<Key: Keypath>(for key: K) -> AnyKeyProvider<Key>? {
        return self.dynamicKeyProvider.nestedDynamicKeyCollection(for: key)
    }
}

public struct AnyKeyPathKeyProvider: KeyCollection {
    public let mappingKeyType: Any.Type
    public let keyProviderType: Any.Type
    private let _containsKey: (Any) -> Bool
    private let dynamicKeyProvider: DynamicKeyProvider
    
    public init<P: KeyCollection>(_ keyProvider: P) {
        self.mappingKeyType = P.MappingKeyType.self
        self._containsKey = { key in
            guard case let key as P.MappingKeyType = key else {
                return false
            }
            return keyProvider.containsKey(key)
        }
        self.keyProviderType = P.self
        self.dynamicKeyProvider = keyProvider
    }
    
    public init(_ anyKeyPathKeyProvider: AnyKeyPathKeyProvider) {
        self = anyKeyPathKeyProvider
    }
    
    public init<Source, KeyType: Keypath>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (KeyType) {
        let keyProvider = SetKeyProvider(Set(sequence))
        self.mappingKeyType = KeyType.self
        self._containsKey = { key in
            guard case let key as KeyType = key else {
                return false
            }
            return keyProvider.containsKey(key)
        }
        self.keyProviderType = SetKeyProvider<KeyType>.self
        self.dynamicKeyProvider = keyProvider
    }
    
    public func containsKey(_ key: AnyKeyPath) -> Bool {
        return self._containsKey(key)
    }
    
    public func containsKey<K: Keypath>(_ key: K) -> Bool {
        return self._containsKey(key)
    }
    
    public func nestedKeyCollection<Key: Keypath>(for key: AnyKeyPath) -> AnyKeyProvider<Key>? {
        return self.dynamicKeyProvider.nestedDynamicKeyCollection(for: key.base)
    }
}

public struct AllKeysProvider<K: Keypath>: KeyCollection {
    public init() {}
    public init(arrayLiteral elements: K...) { }
    public init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (K) { }
    
    public func containsKey(_ key: K) -> Bool {
        return true
    }
    
    public func nestedKeyCollection<Key: Keypath>(for key: K) -> AnyKeyProvider<Key>? {
        return AnyKeyProvider(AllKeysProvider<Key>())
    }
}

// TODO: Can make Set follow protocol once conditional conformances are available in Swift 4.
public struct SetKeyProvider<K: Keypath>: KeyCollection, ExpressibleByArrayLiteral {
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
    
    public func nestedKeyCollection<Key: Keypath>(for key: K) -> AnyKeyProvider<Key>? {
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
    
    func nestedKeyCollection<Key: Keypath>(for key: RootKey) -> AnyKeyProvider<Key>? {
        return AnyKeyProvider.wrapAs(self.nestedKeys)
    }
    
    func nestedMappingKeys<Key: Keypath>() -> AnyKeyProvider<Key>? {
        return AnyKeyProvider.wrapAs(self.nestedKeys)
    }
}

public struct KeyedBinding<K: Keypath, M: Mapping> {
    public let binding: Binding<K, M>
    public let codingKeys: AnyKeyProvider<M.CodingKeys>
    
    public init<KC: KeyCollection>(binding: Binding<K, M>, codingKeys: KC) where KC.MappingKeyType == M.CodingKeys {
        self.binding = binding
        self.codingKeys = AnyKeyProvider(codingKeys)
    }
    
    public init(binding: Binding<K, M>, codingKeys: AnyKeyProvider<M.CodingKeys>) {
        self.binding = binding
        self.codingKeys = codingKeys
    }
    
    public init?(binding: Binding<K, M>, context: MappingContext<K>) throws {
        guard context.keys.containsKey(binding.key) else {
            return nil
        }
        
        let codingKeys: AnyKeyProvider<M.CodingKeys> = try {
            if M.CodingKeys.self is RootKeyPath.Type {
                return AnyKeyProvider([RootKeyPath() as! M.CodingKeys])
            }
            
            return try context.keys.nestedKeyCollection(for: binding.key)
        }()
        
        self.init(binding: binding, codingKeys: codingKeys)
    }
}
