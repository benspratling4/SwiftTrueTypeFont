import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(NameTableTests.allTests),
		testCase(DataMSBTests.allTests),
    ]
}
#endif
