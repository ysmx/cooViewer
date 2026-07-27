//
//  ViewerSpreadHeightFitTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerSpreadHeightFitTests: XCTestCase {

	func testKeepsCurrentValuesWhenAlreadyAtScreenHeightAndNoOverflow() {
		let r = ViewerSpreadHeightFit.assign(widthValue01: 100, heightValue01: 200, widthValue02: 150, heightValue02: 200,
											  currentWidthValue1: 100, currentHeightValue1: 200,
											  currentWidthValue2: 150, currentHeightValue2: 200,
											  screenHeight: 200, maxEnlargement: 0, fullscreenWidth: 1000)
		XCTAssertEqual(r.widthValue1, 100)
		XCTAssertEqual(r.heightValue1, 200)
		XCTAssertEqual(r.widthValue2, 150)
		XCTAssertEqual(r.heightValue2, 200)
	}

	func testRescalesPageOneWhenItsCurrentHeightDoesNotMatchTheScreen() {
		let r = ViewerSpreadHeightFit.assign(widthValue01: 100, heightValue01: 300, widthValue02: 90, heightValue02: 300,
											  currentWidthValue1: 50, currentHeightValue1: 150,
											  currentWidthValue2: 90, currentHeightValue2: 300,
											  screenHeight: 300, maxEnlargement: 0, fullscreenWidth: 1000)
		XCTAssertEqual(r.widthValue1, 100)
		XCTAssertEqual(r.heightValue1, 300)
		// Page two already matched screenHeight, so it's untouched.
		XCTAssertEqual(r.widthValue2, 90)
		XCTAssertEqual(r.heightValue2, 300)
	}

	func testRescaleIsClampedByMaxEnlargement() {
		let r = ViewerSpreadHeightFit.assign(widthValue01: 50, heightValue01: 50, widthValue02: 100, heightValue02: 100,
											  currentWidthValue1: 25, currentHeightValue1: 25,
											  currentWidthValue2: 100, currentHeightValue2: 100,
											  screenHeight: 100, maxEnlargement: 2, fullscreenWidth: 1000)
		// Unclamped rate would be 100/50=4.0; clamped to maxEnlargement=2.
		XCTAssertEqual(r.widthValue1, 100)
		XCTAssertEqual(r.heightValue1, 100)
	}

	func testShrinksBothPagesProportionallyWhenCombinedWidthOverflows() {
		let r = ViewerSpreadHeightFit.assign(widthValue01: 100, heightValue01: 100, widthValue02: 100, heightValue02: 100,
											  currentWidthValue1: 100, currentHeightValue1: 100,
											  currentWidthValue2: 100, currentHeightValue2: 100,
											  screenHeight: 100, maxEnlargement: 0, fullscreenWidth: 150)
		// Combined width 200 > fullscreenWidth 150: shrink both by 150/200=0.75.
		XCTAssertEqual(r.widthValue1, 75)
		XCTAssertEqual(r.heightValue1, 75)
		XCTAssertEqual(r.widthValue2, 75)
		XCTAssertEqual(r.heightValue2, 75)
	}

	func testDoesNotShrinkWhenCombinedWidthFits() {
		let r = ViewerSpreadHeightFit.assign(widthValue01: 100, heightValue01: 100, widthValue02: 100, heightValue02: 100,
											  currentWidthValue1: 100, currentHeightValue1: 100,
											  currentWidthValue2: 100, currentHeightValue2: 100,
											  screenHeight: 100, maxEnlargement: 0, fullscreenWidth: 1000)
		XCTAssertEqual(r.widthValue1, 100)
		XCTAssertEqual(r.widthValue2, 100)
	}
}
