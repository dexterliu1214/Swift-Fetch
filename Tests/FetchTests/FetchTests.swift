import XCTest
@testable import Fetch

final class FetchTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let expect = expectation(description: #function)
        fetch("https://example.com") {
            switch $0 {
            case .failure(let error):
                print(error)
            case .success(let response):
                print(response.data.text()!)
                XCTAssert(response.ok)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.0)
    }
}
