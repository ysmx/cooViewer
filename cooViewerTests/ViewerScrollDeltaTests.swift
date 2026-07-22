//
//  ViewerScrollDeltaTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerScrollDeltaTests: XCTestCase {

	func testScrollUpNegatesValueOnYAxis() {
		let point = ViewerScrollDelta.point(value: 10, dx: 0, dy: -1)
		XCTAssertEqual(point.x, 0)
		XCTAssertEqual(point.y, -10)
	}

	func testScrollDownKeepsValuePositiveOnYAxis() {
		let point = ViewerScrollDelta.point(value: 10, dx: 0, dy: 1)
		XCTAssertEqual(point.x, 0)
		XCTAssertEqual(point.y, 10)
	}

	func testScrollLeftKeepsValuePositiveOnXAxis() {
		let point = ViewerScrollDelta.point(value: 10, dx: 1, dy: 0)
		XCTAssertEqual(point.x, 10)
		XCTAssertEqual(point.y, 0)
	}

	func testScrollRightNegatesValueOnXAxis() {
		let point = ViewerScrollDelta.point(value: 10, dx: -1, dy: 0)
		XCTAssertEqual(point.x, -10)
		XCTAssertEqual(point.y, 0)
	}

	func testZeroValueProducesZeroPointRegardlessOfDirection() {
		XCTAssertEqual(ViewerScrollDelta.point(value: 0, dx: 1, dy: -1), NSPoint(x: 0, y: 0))
	}
}
