import XCTest

extension CRMapperTests {
    static let __allTests = [
        ("testMapFromJSONUsesParentPayload", testMapFromJSONUsesParentPayload),
    ]
}

extension CollectionMappingTests {
    static let __allTests = [
        ("testAssigningNullToCollectionWhenAppendNullableDoesNothing", testAssigningNullToCollectionWhenAppendNullableDoesNothing),
        ("testAssigningNullToCollectionWhenNonNullableThrows", testAssigningNullToCollectionWhenNonNullableThrows),
        ("testAssigningNullToCollectionWhenReplaceNullableRemovesAllAndDeletes", testAssigningNullToCollectionWhenReplaceNullableRemovesAllAndDeletes),
        ("testAssigningNullToOptionalCollectionWhenNonNullableThrows", testAssigningNullToOptionalCollectionWhenNonNullableThrows),
        ("testAssigningNullToOptionalCollectionWhenReplaceNullableAssignsNullAndDeletes", testAssigningNullToOptionalCollectionWhenReplaceNullableAssignsNullAndDeletes),
        ("testDefaultInsertionPolicyIsReplaceUniqueNullable", testDefaultInsertionPolicyIsReplaceUniqueNullable),
        ("testMappingCollection", testMappingCollection),
        ("testMappingCollectionByAppend", testMappingCollectionByAppend),
        ("testMappingCollectionByReplace", testMappingCollectionByReplace),
        ("testMappingCollectionByReplaceDelete", testMappingCollectionByReplaceDelete),
        ("testMappingEquatableCollectionByReplaceDeleteUnique", testMappingEquatableCollectionByReplaceDeleteUnique),
    ]
}

extension CompanyMappingTests {
    static let __allTests = [
        ("testJsonToCompany", testJsonToCompany),
        ("testNestedJsonToCompany", testNestedJsonToCompany),
        ("testNilOptionalNilsRelationship", testNilOptionalNilsRelationship),
        ("testUsesExistingObject", testUsesExistingObject),
    ]
}

extension EmployeeMappingTests {
    static let __allTests = [
        ("testJsonToEmployee", testJsonToEmployee),
    ]
}

extension NestedMappingTests {
    static let __allTests = [
        ("testMappingBeginCalledWhenNestedMappingOfDifferentAdapter", testMappingBeginCalledWhenNestedMappingOfDifferentAdapter),
        ("testMappingWillBeginCalledOnlyOnceWhenNestedMappingOfSameAdapter", testMappingWillBeginCalledOnlyOnceWhenNestedMappingOfSameAdapter),
    ]
}

extension StructMappingTests {
    static let __allTests = [
        ("testNilClearsOptionalValue", testNilClearsOptionalValue),
        ("testStructMapping", testStructMapping),
    ]
}

extension TransformTests {
    static let __allTests = [
        ("testCustomTransformOverridesDefaultOne", testCustomTransformOverridesDefaultOne),
        ("testMappingFromJSON", testMappingFromJSON),
        ("testMappingToJSON", testMappingToJSON),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CRMapperTests.__allTests),
        testCase(CollectionMappingTests.__allTests),
        testCase(CompanyMappingTests.__allTests),
        testCase(EmployeeMappingTests.__allTests),
        testCase(NestedMappingTests.__allTests),
        testCase(StructMappingTests.__allTests),
        testCase(TransformTests.__allTests),
    ]
}
#endif
