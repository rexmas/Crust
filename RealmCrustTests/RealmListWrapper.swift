import RealmSwift

public final class WrapperRLMIterator<T: Object>: IteratorProtocol {
    private var i: UInt = 0
    private let generatorBase: NSFastEnumerationIterator
    
    init(collection: RLMCollection) {
        generatorBase = NSFastEnumerationIterator(collection)
    }
    
    public func next() -> T? {
        guard let next = generatorBase.next() else {
            return nil
        }
        return unsafeBitCast(next, to: T.self)
    }
}

public final class RLMArrayBridgeIterator<T: RLMObject>: IteratorProtocol {
    private let iteratorBase: NSFastEnumerationIterator
    
    internal init(collection: RLMCollection) {
        iteratorBase = NSFastEnumerationIterator(collection)
    }
    
    public func next() -> T? {
        return iteratorBase.next() as! T?
    }
}

public class RLMArrayBridge<T: RLMObject>: RangeReplaceableCollection {
    
    public typealias Element = T
    public let _rlmArray: RLMArray<T>
    
    // MARK: Properties
    
    public var realm: RLMRealm? {
        return _rlmArray.realm
    }
    
    public var isInvalidated: Bool { return _rlmArray.isInvalidated }
    
    // MARK: Initializers
    
    public required init() {
        self._rlmArray = RLMArray(objectClassName: String(describing: T.self))
    }
    
    public init(rlmArray: RLMArray<T>) {
        self._rlmArray = rlmArray
    }
    
    // MARK: Index Retrieval
    
    public func index(of object: T) -> Int? {
        let index = self._rlmArray.index(of: object)
        if index == UInt(NSNotFound) {
            return nil
        }
        return Int(index)
    }
    
    public func index(matching predicate: NSPredicate) -> Int? {
        let index = self._rlmArray.indexOfObject(with: predicate)
        if index == UInt(NSNotFound) {
            return nil
        }
        return Int(index)
    }
    
    public func index(matching predicateFormat: String, _ args: Any...) -> Int? {
        return index(matching: NSPredicate(format: predicateFormat, argumentArray: args))
    }
    
    // MARK: Object Retrieval
    
    public subscript(position: Int) -> T {
        get {
            return self._rlmArray.object(at: UInt(position))
        }
        set {
            return self._rlmArray.replaceObject(at: UInt(position), with: newValue)
        }
    }
    
    public var first: T? { return self._rlmArray.firstObject() }
    public var last: T? { return self._rlmArray.lastObject() }
    
    // MARK: KVC
    
    public func value(forKey key: String) -> Any? {
        return self.value(forKeyPath: key)
    }
    
    public func value(forKeyPath keyPath: String) -> Any? {
        return self._rlmArray.value(forKeyPath: keyPath)
    }
    
    public func setValue(_ value: Any?, forKey key: String) {
        return self._rlmArray.setValue(value, forKeyPath: key)
    }
    
    // MARK: Filtering
    
    public func filter(_ predicateFormat: String, _ args: Any...) -> RLMResults<T> {
        return self._rlmArray.objects(with: NSPredicate(format: predicateFormat, argumentArray: args))
    }
    
    public func filter(_ predicate: NSPredicate) -> RLMResults<T> {
        return self._rlmArray.objects(with: predicate)
    }
    
    // MARK: Sorting
    
    public func sorted(byKeyPath keyPath: String, ascending: Bool = true) -> RLMResults<T> {
        return sorted(by: [SortDescriptor(keyPath: keyPath, ascending: ascending)])
    }
    
    public func sorted<S: Sequence>(by sortDescriptors: S) -> RLMResults<T> where S.Iterator.Element == SortDescriptor {
        return self._rlmArray.sortedResults(using: sortDescriptors.map { RLMSortDescriptor(keyPath: $0.keyPath, ascending: $0.ascending) })
    }
    
    // MARK: Aggregate Operations
    
    public func min<U: MinMaxType>(ofProperty property: String) -> U? {
        return self.filter(NSPredicate(value: true)).min(ofProperty: property) as! U?
    }
    
    public func max<U: MinMaxType>(ofProperty property: String) -> U? {
        return self.filter(NSPredicate(value: true)).max(ofProperty: property) as! U?
    }
    
    public func sum<U: AddableType>(ofProperty property: String) -> U {
        return self.filter(NSPredicate(value: true)).sum(ofProperty: property) as! U
    }
    
    public func average<U: AddableType>(ofProperty property: String) -> U? {
        return self.filter(NSPredicate(value: true)).average(ofProperty: property) as! U?
    }
    
    // MARK: Mutation
    
    public func append(_ object: T) {
        self._rlmArray.add(object)
    }
    
    public func append<S: Sequence>(objectsIn objects: S) where S.Iterator.Element == T {
        for obj in objects {
            self._rlmArray.add(obj)
        }
    }
    
    public func insert(_ object: T, at index: Int) {
        self._rlmArray.insert(object, at: UInt(index))
    }
    
    public func remove(objectAtIndex index: Int) {
        self._rlmArray.removeObject(at: UInt(index))
    }
    
    public func removeLast() {
        self._rlmArray.removeLastObject()
    }
    
    public func removeAll() {
        self._rlmArray.removeAllObjects()
    }
    
    public func replace(index: Int, object: T) {
        self._rlmArray.replaceObject(at: UInt(index), with: object)
    }
    
    public func move(from: Int, to: Int) { // swiftlint:disable:this variable_name
        self._rlmArray.moveObject(at: UInt(from), to: UInt(to))
    }
    
    public func swap(index1: Int, _ index2: Int) {
        self._rlmArray.exchangeObject(at: UInt(index1), withObjectAt: UInt(index2))
    }
    
    // MARK: Sequence Support
    
    public func makeIterator() -> RLMArrayBridgeIterator<T> {
        return RLMArrayBridgeIterator<T>(collection: self._rlmArray)
    }
    
    // MARK: RangeReplaceableCollection Support
    
    public func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C : Collection, C.Iterator.Element == T {
            for _ in subrange.lowerBound..<subrange.upperBound {
                self.remove(objectAtIndex: subrange.lowerBound)
            }
            for x in newElements.reversed() {
                self.insert(x, at: subrange.lowerBound)
            }
    }
    
    public var startIndex: Int { return 0 }
    public var endIndex: Int { return Int(self._rlmArray.count) }
    
    public func index(after i: Int) -> Int { return i + 1 }
    public func index(before i: Int) -> Int { return i - 1 }
}

public class ListWrapper<T: Object>: RangeReplaceableCollection {
    
    public typealias Element = T
    
    public func contains(_ element: T) -> Bool {
        return self.list._rlmArray.contains(unsafeBitCast(element, to: RLMObject.self))
    }
    
    // MARK: Properties
    
    let list: List<T>
    
    public var realm: Realm? {
        return self.list.realm
    }
    
    public var isInvalidated: Bool { return self.list.isInvalidated }
    
    // MARK: Initializers
    
    init(list: List<T>) {
        self.list = list
    }
    
    public required init() {
        fatalError()
    }
    
    // MARK: Index Retrieval
    
    public func index(of object: T) -> Int? {
        return self.list.index(of: object)
    }
    
    public func index(matching predicate: NSPredicate) -> Int? {
        return self.list.index(matching: predicate)
    }
    
    public func index(matching predicateFormat: String, _ args: Any...) -> Int? {
        return self.list.index(matching: predicateFormat)
    }
    
    // MARK: Object Retrieval
    
    public subscript(position: Int) -> T {
        get {
            return self.list[position]
        }
        set {
            self.list[position] = newValue
        }
    }
    
    public var first: T? { return self.list.first }
    
    public var last: T? { return self.list.last }
    
    // MARK: KVC
    public func value(forKey key: String) -> Any? {
        return self.list.value(forKey: key)
    }
    public func value(forKeyPath keyPath: String) -> Any? {
        return self.list.value(forKeyPath: keyPath)
    }
    
    public func setValue(_ value: Any?, forKey key: String) {
        return self.list.setValue(value, forKey: key)
    }
    
    // MARK: Filtering
    
    public func filter(_ predicateFormat: String, _ args: Any...) -> Results<T> {
        return self.list.filter(predicateFormat, args)
    }
    
    public func filter(_ predicate: NSPredicate) -> Results<T> {
        return self.list.filter(predicate)
    }
    
    // MARK: Sorting
    
    public func sorted(byKeyPath keyPath: String, ascending: Bool = true) -> Results<T> {
        return self.list.sorted(byKeyPath: keyPath, ascending: ascending)
    }
    
    public func sorted<S: Sequence>(by sortDescriptors: S) -> Results<T> where S.Iterator.Element == SortDescriptor {
        return self.list.sorted(by: sortDescriptors)
    }
    
    // MARK: Aggregate Operations
    
    public func min<U: MinMaxType>(ofProperty property: String) -> U? {
        return self.list.min(ofProperty: property)
    }
    
    public func max<U: MinMaxType>(ofProperty property: String) -> U? {
        return self.list.max(ofProperty: property)
    }
    
    public func sum<U: AddableType>(ofProperty property: String) -> U {
        return self.list.sum(ofProperty: property)
    }
    
    public func average<U: AddableType>(ofProperty property: String) -> U? {
        return self.list.average(ofProperty: property)
    }
    
    // MARK: Mutation
    
    public func append(_ object: T) {
        self.list.append(object)
    }
    
    public func append<S: Sequence>(objectsIn objects: S) where S.Iterator.Element == T {
        self.list.append(objectsIn: objects)
    }
    
    public func insert(_ object: T, at index: Int) {
        self.list.insert(object, at: index)
    }
    
    public func remove(objectAtIndex index: Int) {
        self.list.remove(objectAtIndex: index)
    }
    
    public func removeLast() {
        self.list.removeLast()
    }
    
    public func removeAll() {
        self.list.removeAll()
    }
    
    public func replace(index: Int, object: T) {
        self.list.replace(index: index, object: object)
    }
    
    public func move(from: Int, to: Int) { // swiftlint:disable:this variable_name
        self.list.move(from: from, to: to)
    }
    
    public func swap(index1: Int, _ index2: Int) {
        self.list.swap(index1: index1, index2)
    }
    
    // MARK: Sequence Support
    
    /// Returns a `WrapperRLMIterator` that yields successive elements in the underlying `RLMArray`.
    public func makeIterator() -> WrapperRLMIterator<T> {
        return WrapperRLMIterator(collection: self.list._rlmArray)
    }
    
    // MARK: RangeReplaceableCollection Support
    
    public func replaceSubrange<C: Collection>(_ subrange: Range<Int>, with newElements: C)
        where C.Iterator.Element == T {
            self.list.replaceSubrange(subrange, with: newElements)
    }
    
    public var startIndex: Int { return self.list.startIndex }
    public var endIndex: Int { return self.list.endIndex }
    
    public func index(after i: Int) -> Int { return self.list.index(after: i) }
    public func index(before i: Int) -> Int { return self.list.index(before: i) }
}
