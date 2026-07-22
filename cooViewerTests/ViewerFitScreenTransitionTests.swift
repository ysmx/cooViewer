//
//  ViewerFitScreenTransitionTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerFitScreenTransitionTests: XCTestCase {

	// Size order (smallest to largest): 0 (fitToScreen) -> 1 (fitToScreenWidth)
	// -> 3 (fitToScreenWidthDivide) -> 2 (noScale).

	func testCycleWrapsThroughAllFourModes() {
		XCTAssertEqual(ViewerFitScreenTransition.target(current: 0, direction: .cycle), 1)
		XCTAssertEqual(ViewerFitScreenTransition.target(current: 1, direction: .cycle), 3)
		XCTAssertEqual(ViewerFitScreenTransition.target(current: 3, direction: .cycle), 2)
		XCTAssertEqual(ViewerFitScreenTransition.target(current: 2, direction: .cycle), 0)
	}

	func testEnlargeStepsUpAndStopsAtTheLargestMode() {
		XCTAssertEqual(ViewerFitScreenTransition.target(current: 0, direction: .enlarge), 1)
		XCTAssertEqual(ViewerFitScreenTransition.target(current: 1, direction: .enlarge), 3)
		XCTAssertEqual(ViewerFitScreenTransition.target(current: 3, direction: .enlarge), 2)
		XCTAssertNil(ViewerFitScreenTransition.target(current: 2, direction: .enlarge))
	}

	func testReduceStepsDownAndStopsAtTheSmallestMode() {
		XCTAssertEqual(ViewerFitScreenTransition.target(current: 2, direction: .reduce), 3)
		XCTAssertEqual(ViewerFitScreenTransition.target(current: 3, direction: .reduce), 1)
		XCTAssertEqual(ViewerFitScreenTransition.target(current: 1, direction: .reduce), 0)
		XCTAssertNil(ViewerFitScreenTransition.target(current: 0, direction: .reduce))
	}

	func testUnrecognizedCurrentModeReturnsNilForAllDirections() {
		XCTAssertNil(ViewerFitScreenTransition.target(current: 99, direction: .cycle))
		XCTAssertNil(ViewerFitScreenTransition.target(current: 99, direction: .enlarge))
		XCTAssertNil(ViewerFitScreenTransition.target(current: 99, direction: .reduce))
	}
}
