//
//  ViewerLoupeRateTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerLoupeRateTests: XCTestCase {

	// loupeRatePlus has no upper clamp - preserved as-is from the original.
	func testIncreasedHasNoUpperClamp() {
		XCTAssertEqual(ViewerLoupeRate.increased(current: 5.0, by: 100.0), 105.0)
	}

	func testDecreasedSubtractsWhenResultStaysAboveFloor() {
		XCTAssertEqual(ViewerLoupeRate.decreased(current: 5.0, by: 1.0), 4.0)
	}

	func testDecreasedClampsToOneWhenResultWouldGoAtOrBelowFloor() {
		XCTAssertEqual(ViewerLoupeRate.decreased(current: 1.5, by: 1.0), 1.0)
		XCTAssertEqual(ViewerLoupeRate.decreased(current: 2.0, by: 1.0), 1.0)
	}
}
