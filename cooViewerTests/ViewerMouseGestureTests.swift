//
//  ViewerMouseGestureTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerMouseGestureTests: XCTestCase {

	// gestureCode's movedX is the VERTICAL delta and movedY the HORIZONTAL
	// delta, mirroring how CustomImageView packs cursorMoved.

	func testSmallMovementsAreAClickNotAGesture() {
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: 0, movedY: 0), -1)
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: 30, movedY: -30), -1)
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: -30, movedY: 30), -1)
	}

	func testHorizontalDeltaMapsToLeftAndRight() {
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: 0, movedY: -31), 0)
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: 0, movedY: 31), 1)
	}

	func testVerticalDeltaMapsToUpAndDown() {
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: 31, movedY: 0), 2)
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: -31, movedY: 0), 3)
	}

	func testLargerMagnitudeWinsWhenBothExceedTheThreshold() {
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: 40, movedY: 35), 2)
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: 35, movedY: -40), 0)
	}

	func testExactTiePrefersTheHorizontalGesture() {
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: 40, movedY: 40), 1)
		XCTAssertEqual(ViewerMouseGesture.gestureCode(movedX: -40, movedY: -40), 0)
	}

	func testPageBarFractionSpansTheInsetBarLeftToRight() {
		let bar = CGRect(x: 10, y: 0, width: 104, height: 20)
		// Inset by 2 -> inner spans x 12..112, width 100.
		XCTAssertEqual(ViewerMouseGesture.pageBarFraction(pointX: 12, barRect: bar, readFromLeft: true), 0, accuracy: 0.001)
		XCTAssertEqual(ViewerMouseGesture.pageBarFraction(pointX: 62, barRect: bar, readFromLeft: true), 0.5, accuracy: 0.001)
		XCTAssertEqual(ViewerMouseGesture.pageBarFraction(pointX: 112, barRect: bar, readFromLeft: true), 1, accuracy: 0.001)
	}

	func testPageBarFractionMirrorsForRightToLeftReading() {
		let bar = CGRect(x: 10, y: 0, width: 104, height: 20)
		// Right-to-left flips the axis (with the original's extra -1pt bias).
		XCTAssertEqual(ViewerMouseGesture.pageBarFraction(pointX: 12, barRect: bar, readFromLeft: false), 0.99, accuracy: 0.001)
		XCTAssertEqual(ViewerMouseGesture.pageBarFraction(pointX: 112, barRect: bar, readFromLeft: false), -0.01, accuracy: 0.001)
	}
}
