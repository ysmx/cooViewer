//
//  ViewerSpreadCenterOffsetsTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerSpreadCenterOffsetsTests: XCTestCase {

	func testCentersBothPagesWhenShorterThanScreen() {
		let r = ViewerSpreadCenterOffsets.assign(fullscreenWidth: 800, fullscreenHeight: 600,
												  widthValue1: 200, heightValue1: 400,
												  widthValue2: 200, heightValue2: 500)
		XCTAssertEqual(r.center1, 100) // (600-400)/2
		XCTAssertEqual(r.center2, 50)  // (600-500)/2
	}

	func testClampsCenterToZeroWhenPageIsTallerThanScreen() {
		let r = ViewerSpreadCenterOffsets.assign(fullscreenWidth: 800, fullscreenHeight: 600,
												  widthValue1: 200, heightValue1: 700,
												  widthValue2: 200, heightValue2: 600)
		XCTAssertEqual(r.center1, 0)
		XCTAssertEqual(r.center2, 0)
	}

	func testHorizontalOffsetCentersTheCombinedPairWidth() {
		let r = ViewerSpreadCenterOffsets.assign(fullscreenWidth: 800, fullscreenHeight: 600,
												  widthValue1: 200, heightValue1: 400,
												  widthValue2: 300, heightValue2: 400)
		XCTAssertEqual(r.x, 150) // (800-200-300)/2
	}

	func testHorizontalOffsetTruncatesTowardZeroWhenNegative() {
		// Combined width exceeds the screen: (800-500-500)/2 = -100/2 = -50, an exact case;
		// use an odd remainder to pin down truncation-toward-zero (not floor) semantics.
		let r = ViewerSpreadCenterOffsets.assign(fullscreenWidth: 800, fullscreenHeight: 600,
												  widthValue1: 500, heightValue1: 400,
												  widthValue2: 501, heightValue2: 400)
		// (800-500-501) = -201, -201/2 truncates toward zero to -100 (not floor -101).
		XCTAssertEqual(r.x, -100)
	}
}
