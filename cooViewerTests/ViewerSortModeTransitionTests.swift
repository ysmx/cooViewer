//
//  ViewerSortModeTransitionTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerSortModeTransitionTests: XCTestCase {

	// canSortByDate: name(0) -> creation(2) -> modification(3) -> shuffle(1) -> name(0)
	func testCyclesThroughAllFourModesWhenDateSortingIsSupported() {
		XCTAssertEqual(ViewerSortModeTransition.next(current: 0, canSortByDate: true), 2)
		XCTAssertEqual(ViewerSortModeTransition.next(current: 2, canSortByDate: true), 3)
		XCTAssertEqual(ViewerSortModeTransition.next(current: 3, canSortByDate: true), 1)
		XCTAssertEqual(ViewerSortModeTransition.next(current: 1, canSortByDate: true), 0)
	}

	// !canSortByDate: name(0) <-> shuffle(1), and date modes (2/3) collapse
	// back to name(0) since they're not selectable without date support.
	func testCollapsesToNameAndShuffleWhenDateSortingIsUnsupported() {
		XCTAssertEqual(ViewerSortModeTransition.next(current: 0, canSortByDate: false), 1)
		XCTAssertEqual(ViewerSortModeTransition.next(current: 1, canSortByDate: false), 0)
		XCTAssertEqual(ViewerSortModeTransition.next(current: 2, canSortByDate: false), 0)
		XCTAssertEqual(ViewerSortModeTransition.next(current: 3, canSortByDate: false), 0)
	}

	func testOutOfRangeCurrentIsLeftUnchanged() {
		XCTAssertEqual(ViewerSortModeTransition.next(current: 99, canSortByDate: true), 99)
		XCTAssertEqual(ViewerSortModeTransition.next(current: 99, canSortByDate: false), 99)
	}
}
