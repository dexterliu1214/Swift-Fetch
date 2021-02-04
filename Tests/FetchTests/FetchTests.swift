import XCTest
@testable import Fetch

final class FetchTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Fetch().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
