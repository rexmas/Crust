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

public protocol SetMappingKey: Keypath {
    /// Return the collection of coding keys as a set for a nested set of JSON. A non-nil value is required for every key
    /// that is used to key into JSON passed to a nested `Mapping`, otherwise the mapping operation
    /// for that nested type will fail and throw an error.
    ///
    /// - returns: Set of MappingKeys for the nested JSON. `nil` on error - results in error during mapping.
    func nestedCodingKey<Key: Keypath>() -> Set<Key>?
}

extension SetMappingKey {
    func nestedCodingKey<Key: Keypath>() -> AnyKeyProvider<Key>? {
        guard let nested = self.nestedCodingKey() as Set<Key>? else {
            return nil
        }
        
        return AnyKeyProvider(SetKeyProvider(nested))
    }
}

// TODO: Change to MappingKey
public protocol Keypath: JSONKeypath, Hashable {
    /// Return the collection of coding keys for a nested set of JSON. A non-nil value is required for every key
    /// that is used to key into JSON passed to a nested `Mapping`, otherwise the mapping operation
    /// for that nested type will fail and throw an error.
    ///
    /// - returns: Collection of MappingKeys for the nested JSON. `nil` on error - results in error during mapping.
    func nestedCodingKey<Key: Keypath>() -> AnyKeyProvider<Key>?
}

public extension Keypath {
    public var hashValue: Int {
        return self.keyPath.hashValue
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.keyPath == rhs.keyPath
    }
    
    public func nestedCodingKey<K: Keypath>() throws -> AnyKeyProvider<K> {
        guard let nested = (self.nestedCodingKey() as AnyKeyProvider<K>?) else {
            throw CrustError.nestedCodingKeyError(type: Self.self, keyPath: self.keyPath)
        }
        return nested
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
    
    public func nestedCodingKey<Key : Keypath>() -> AnyKeyProvider<Key>? {
        guard self is Key else {
            return nil
        }
        return AnyKeyProvider.wrapAs([self])
    }
}

extension String: Keypath {
    public func nestedCodingKey<Key : Keypath>() -> AnyKeyProvider<Key>? { return nil }
}

extension Int: Keypath {
    public func nestedCodingKey<Key : Keypath>() -> AnyKeyProvider<Key>? { return nil }
}

// TODO: Change this to KeyContainer maybe.
public protocol KeyProvider {
    associatedtype CodingKeyType: Keypath
    
    init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == CodingKeyType
    func containsKey(_ key: CodingKeyType) -> Bool
}

public struct AnyKeyProvider<K: Keypath>: KeyProvider {
    public let codingKeyType: K.Type
    public let keyProviderType: Any.Type
    
    /// This function is really dumb. `AnyKeyProvider<K> as? AnyKeyProvider<K2>` always fails though `Set<K> as? Set<K2>` doesn't
    /// so we check and force cast here.
    public static func wrapAs<P: KeyProvider, K2: Keypath>(_ keyProvider: P) -> AnyKeyProvider<K2>? where P.CodingKeyType == K {
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
    
    public init<P: KeyProvider>(_ keyProvider: P) where P.CodingKeyType == K {
        self.keyProviderType = P.self
        self.codingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
    }
    
    public init(arrayLiteral elements: K...) {
        let keyProvider = SetKeyProvider(Set(elements))
        self.keyProviderType = type(of: keyProvider).self
        self.codingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
    }
    
    public init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (K) {
        let keyProvider = SetKeyProvider(Set(sequence))
        self.keyProviderType = type(of: keyProvider).self
        self.codingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
    }
    
    private let _containsKey: (K) -> Bool
    public func containsKey(_ key: K) -> Bool {
        return self._containsKey(key)
    }
}

public struct AnyKeyPathKeyProvider: KeyProvider {
    private let _containsKey: (Any) -> Bool
    public let codingKeyType: Any.Type
    
    public init<P: KeyProvider>(keyProvider: P) {
        self.codingKeyType = P.CodingKeyType.self
        self._containsKey = { key in
            guard case let key as P.CodingKeyType = key else {
                return false
            }
            return keyProvider.containsKey(key)
        }
    }
    
    public init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (AnyKeyPath) {
        let keyProvider = SetKeyProvider(Set(sequence))
        self.codingKeyType = SetKeyProvider<AnyKeyPath>.self
        self._containsKey = { key in
            guard case let key as AnyKeyPath = key else {
                return false
            }
            return keyProvider.containsKey(key)
        }
    }
    
    public func containsKey(_ key: AnyKeyPath) -> Bool {
        return self._containsKey(key)
    }
    
    public func containsKey<K: Keypath>(_ key: K) -> Bool {
        return self._containsKey(key)
    }
}

public struct AllKeysProvider<K: Keypath>: KeyProvider {
    public init() {}
    public init(arrayLiteral elements: K...) { }
    public init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (K) { }
    
    public func containsKey(_ key: K) -> Bool {
        return true
    }
}

// TODO: Can make Set follow protocol once conditional conformances are available in Swift 4.
public struct SetKeyProvider<K: Keypath>: KeyProvider, ExpressibleByArrayLiteral {
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
}

internal struct NestedCodingKey<RootKey: Keypath, NestedProvider: KeyProvider>: Keypath {
    let rootKey: RootKey
    let nestedKeys: NestedProvider
    
    var keyPath: String {
        return self.rootKey.keyPath
    }
    
    init(rootKey: RootKey, nestedKeys: NestedProvider) {
        self.rootKey = rootKey
        self.nestedKeys = nestedKeys
    }
    
    public func nestedCodingKey<Key: Keypath>() -> AnyKeyProvider<Key>? {
        return AnyKeyProvider.wrapAs(self.nestedKeys)
    }
}

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
    public let base: Any
    
    public init<K>(_ base: K) where K: Keypath {
        self.base = base
        self.type = K.self
        self._keyPath = { base.keyPath }
        self._hashValue = { base.hashValue }
    }
    
    public func nestedCodingKey<Key: Keypath>() -> AnyKeyProvider<Key>? { return nil }
    
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

public struct KeyedBinding<K: Keypath, M: Mapping> {
    public let binding: Binding<K, M>
    public let codingKeys: AnyKeyProvider<M.CodingKeys>
    
    public init<P: KeyProvider>(binding: Binding<K, M>, codingKeys: P) where P.CodingKeyType == M.CodingKeys {
        self.binding = binding
        self.codingKeys = AnyKeyProvider(codingKeys)
    }
    
    public init?(binding: Binding<K, M>, context: MappingContext<K>) throws {
        guard context.keys.containsKey(binding.key) else {
            return nil
        }
        
        let codingKeys: AnyKeyProvider<M.CodingKeys> = try {
            if M.CodingKeys.self is RootKeyPath.Type {
                return AnyKeyProvider([RootKeyPath() as! M.CodingKeys])
            }
            
            return try binding.key.nestedCodingKey()
        }()
        
        self.init(binding: binding, codingKeys: codingKeys)
    }
}
