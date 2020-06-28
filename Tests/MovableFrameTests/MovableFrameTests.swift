import XCTest
@testable import MovableFrame

final class MovableFrameTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MovableFrame().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
