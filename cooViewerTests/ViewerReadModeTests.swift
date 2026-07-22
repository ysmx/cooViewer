//
//  ViewerReadModeTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerReadModeTests: XCTestCase {

	func testCyclesThroughAllFourModesAndWraps() {
		XCTAssertEqual(ViewerReadMode.next(current: 0), 1)
		XCTAssertEqual(ViewerReadMode.next(current: 1), 2)
		XCTAssertEqual(ViewerReadMode.next(current: 2), 3)
		XCTAssertEqual(ViewerReadMode.next(current: 3), 0)
	}

	func testOutOfRangeCurrentIsLeftUnchanged() {
		XCTAssertEqual(ViewerReadMode.next(current: 99), 99)
	}
}
