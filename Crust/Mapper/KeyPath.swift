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
    func nestedCodingKey<K: Keypath>(for codingKey: Self) throws -> Set<K>
}

public extension Keypath {
    public var hashValue: Int {
        return self.keyPath.hashValue
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.keyPath == rhs.keyPath
    }
    
    public func nestedCodingKey<K>(for codingKey: Self) throws -> Set<K> where K : Keypath {
        throw CrustError.nestedCodingKeyError(type: Self.self, keyPath: self.keyPath)
    }
}

public struct RootKeyPath: Keypath {
    public let keyPath: String = ""
}

extension String: Keypath { }
extension Int: Keypath { }

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
    
    func nestedCodingKey<K>(for codingKey: NestedCodingKey<RootKey, NestedKey>) throws -> Set<K> where K : Keypath {
        guard codingKey == self, self.nestedKeys is Set<K> else {
            throw CrustError.nestedCodingKeyError(type: type(of: codingKey), keyPath: rootKey.keyPath)
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
}
