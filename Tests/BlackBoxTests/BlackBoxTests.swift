import XCTest
@testable import BlackBox

final class BlackBoxTests: XCTestCase {
    func testBlackBox() throws {
        func measured(_ closure: () throws -> Void) rethrows -> TimeInterval {
            let before = Date()
            try closure()
            let after = Date()

            return after.timeIntervalSince(before)
        }

        // The black-boxed block should take significantly longer to run than the empty placebo one:

        let placebo = measured {
            // intentionally left blank
        }

        let blackbox = measured {
            for i in 0..<1_000_000 {
                blackBox(i)
            }
        }

        let safetyFactor = 10.0
        XCTAssertGreaterThan(blackbox, safetyFactor * placebo)
    }
}
