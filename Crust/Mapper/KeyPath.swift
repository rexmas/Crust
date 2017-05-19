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
public protocol Keypath: JSONKeypath, Hashable {
    /// Return the coding keys for a nested set of JSON. A non-nil value is required for every key
    /// that is used to key into JSON passed to a nested `Mapping`, otherwise the mapping operation
    /// for that nested type will fail and throw an error.
    ///
    /// Default implementation returns `nil`.
    func nestedCodingKey<P: KeyProvider>() -> P?
}

public extension Keypath {
    public var hashValue: Int {
        return self.keyPath.hashValue
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.keyPath == rhs.keyPath
    }
    
    func nestedCodingKey<P: KeyProvider>() -> P? {
        return nil
    }
    
    public func nestedCodingKey<P: KeyProvider>() throws -> P {
        guard let nested = (self.nestedCodingKey() as P?) else {
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
}

extension String: Keypath { }
extension Int: Keypath { }

// TODO: Change this to KeyContainer maybe.
public protocol KeyProvider: ExpressibleByArrayLiteral {
    associatedtype CodingKeyType: Keypath
    func containsKey(_ key: CodingKeyType) -> Bool
    init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == CodingKeyType
}

public struct AnyKeyProvider<K: Keypath>: KeyProvider {
    private let _containsKey: (K) -> Bool
    public let codingKeyType: Any.Type
    
    public init<P: KeyProvider>(keyProvider: P) where P.CodingKeyType == K {
        self.codingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
    }
    
    public init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (K) {
        let keyProvider = SetKeyProvider(Set(sequence))
        self.codingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
    }
    
    public init(arrayLiteral elements: K...) {
        let keyProvider = SetKeyProvider(Set(elements))
        self.codingKeyType = K.self
        self._containsKey = { key in
            return keyProvider.containsKey(key)
        }
    }
    
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
    
    public init(arrayLiteral elements: AnyKeyPath...) {
        let keyProvider = SetKeyProvider(Set(elements))
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
    public func containsKey(_ key: K) -> Bool {
        return true
    }
    
    public init() {}
    public init(arrayLiteral elements: K...) { }
    public init<Source>(_ sequence: Source) where Source : Sequence, Source.Iterator.Element == (K) { }
}

// TODO: Can make Set follow protocol once conditional conformances are available in Swift 4.
public struct SetKeyProvider<K: Keypath>: KeyProvider {
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
    
    func nestedCodingKey<P: KeyProvider>() -> P? {
        return self.nestedKeys as? P
    }
}

public struct AnyKeyPath: Keypath {
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
}

public struct KeyedBinding<K: Keypath, M: Mapping> {
    public let binding: Binding<K, M>
    public let codingKeys: AnyKeyProvider<M.CodingKeys>
    
    public init<P: KeyProvider>(binding: Binding<K, M>, codingKeys: P) where P.CodingKeyType == M.CodingKeys {
        self.binding = binding
        self.codingKeys = AnyKeyProvider(keyProvider: codingKeys)
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
