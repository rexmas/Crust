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

// TODO: Change to CodingKey
public protocol Keypath: JSONKeypath, Hashable {
    /// Return the coding keys for a nested set of JSON. A non-nil value is required for every key
    /// that is used to key into JSON passed to a nested `Mapping`, otherwise the mapping operation
    /// for that nested type will fail and throw an error.
    ///
    /// Default implementation returns `nil`.
    func nestedCodingKey<K: Keypath>() -> Set<K>?
}

public extension Keypath {
    public var hashValue: Int {
        return self.keyPath.hashValue
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.keyPath == rhs.keyPath
    }
    
    public func nestedCodingKey<K: Keypath>() -> Set<K>? {
        return nil
    }
    
    public func nestedCodingKey<K: Keypath>() throws -> Set<K> {
        guard let nested = (self.nestedCodingKey() as Set<K>?) else {
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

// TODO: Change this to associated type. Make context use AnyKeyProvider.
public protocol KeyProvider {
    associatedtype CodingKeyType: Keypath
    func containsKey(_ key: CodingKeyType) -> Bool
}

public struct AnyKeyProvider<K: Keypath>: KeyProvider {
//    private let _containsKey: (Any) -> Bool
    private let _containsKey: (K) -> Bool
    public let codingKeyType: Any.Type
    
    init<P: KeyProvider>(keyProvider: P) where P.CodingKeyType == K {
        self.codingKeyType = K.self
        self._containsKey = { key in
//            guard case let key as K = key else {
//                return false
//            }
            return keyProvider.containsKey(key)
        }
    }
    
    public func containsKey(_ key: K) -> Bool {
        return self._containsKey(key)
    }
    
//    public func containsKey<K: Keypath>(_ key: K) -> Bool {
//        return self._containsKey(key)
//    }
}

public struct AnyKeyPathKeyProvider: KeyProvider {
    private let _containsKey: (Any) -> Bool
    public let codingKeyType: Any.Type
    
    init<P: KeyProvider>(keyProvider: P) {
        self.codingKeyType = P.CodingKeyType.self
        self._containsKey = { key in
            guard case let key as P.CodingKeyType = key else {
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
}

// TODO: Can make Set follow protocol once conditional conformances are available in Swift 4.
public struct SetKeyProvider<K: Keypath>: KeyProvider, ExpressibleByArrayLiteral {
    public let keys: Set<K>
    
    public init(_ keys: Set<K>) {
        self.keys = keys
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

internal struct NestedCodingKey<RootKey: Keypath, NestedKey: Keypath>: Keypath {
    let rootKey: RootKey
    let nestedKeys: Set<NestedKey>
    
    var keyPath: String {
        return self.rootKey.keyPath
    }
    
    init(rootKey: RootKey, nestedKeys: Set<NestedKey>) {
        self.rootKey = rootKey
        self.nestedKeys = nestedKeys
    }
    
    func nestedCodingKey<K: Keypath>() throws -> Set<K> {
        guard self.nestedKeys is Set<K> else {
            throw CrustError.nestedCodingKeyError(type: NestedCodingKey<RootKey, NestedKey>.self, keyPath: rootKey.keyPath)
        }
        return self.nestedKeys as! Set<K>
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
    public let codingKeys: Set<M.CodingKeys>
    
    public init(binding: Binding<K, M>, codingKeys: Set<M.CodingKeys>) {
        self.binding = binding
        self.codingKeys = codingKeys
    }
    
    public init?(binding: Binding<K, M>, context: MappingContext<K>) throws {
        guard context.keys.containsKey(binding.key) else {
            return nil
        }
        
        let codingKeys: Set<M.CodingKeys> = try {
            if M.CodingKeys.self is RootKeyPath.Type {
                return Set([RootKeyPath()]) as! Set<M.CodingKeys>
            }
            
            return try binding.key.nestedCodingKey()
        }()
        
        self.init(binding: binding, codingKeys: codingKeys)
    }
}
