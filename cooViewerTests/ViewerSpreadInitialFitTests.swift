//
//  ViewerSpreadInitialFitTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerSpreadInitialFitTests: XCTestCase {

	func testWidthLimitedPageIsScaledByTheSmallerWidthRate() {
		// 200x200 into a 400x600 half: width rate 2.0 < height rate 3.0, width wins.
		let r = ViewerSpreadInitialFit.assign(widthValue01: 200, heightValue01: 200, widthValue02: 100, heightValue02: 300,
											   screenWidth: 400, screenHeight: 600, maxEnlargement: 0)
		XCTAssertEqual(r.widthValue1, 400)
		XCTAssertEqual(r.heightValue1, 400)
	}

	func testHeightLimitedPageIsScaledByTheSmallerHeightRate() {
		// 100x300 into a 400x600 half: width rate 4.0 > height rate 2.0, height wins.
		let r = ViewerSpreadInitialFit.assign(widthValue01: 200, heightValue01: 200, widthValue02: 100, heightValue02: 300,
											   screenWidth: 400, screenHeight: 600, maxEnlargement: 0)
		XCTAssertEqual(r.widthValue2, 200)
		XCTAssertEqual(r.heightValue2, 600)
	}

	func testZeroMaxEnlargementDoesNotCapTheRate() {
		let r = ViewerSpreadInitialFit.assign(widthValue01: 100, heightValue01: 100, widthValue02: 100, heightValue02: 100,
											   screenWidth: 1000, screenHeight: 1000, maxEnlargement: 0)
		XCTAssertEqual(r.widthValue1, 1000)
		XCTAssertEqual(r.heightValue1, 1000)
	}

	func testNonZeroMaxEnlargementCapsTheRate() {
		let r = ViewerSpreadInitialFit.assign(widthValue01: 100, heightValue01: 100, widthValue02: 100, heightValue02: 100,
											   screenWidth: 1000, screenHeight: 1000, maxEnlargement: 2)
		XCTAssertEqual(r.widthValue1, 200)
		XCTAssertEqual(r.heightValue1, 200)
		XCTAssertEqual(r.widthValue2, 200)
		XCTAssertEqual(r.heightValue2, 200)
	}
}
