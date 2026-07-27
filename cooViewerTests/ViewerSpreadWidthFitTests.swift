//
//  ViewerSpreadWidthFitTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerSpreadWidthFitTests: XCTestCase {

	func testNonDivideModeScalesToFitTheFullFullscreenWidth() {
		let r = ViewerSpreadWidthFit.assign(widthValue01: 100, heightValue01: 100, widthValue02: 100, heightValue02: 100,
											 currentWidthValue1: 100, currentHeightValue1: 100,
											 currentWidthValue2: 100, currentHeightValue2: 100,
											 fullscreenWidth: 150, fullscreenHeight: 100, screenHeight: 100,
											 maxEnlargement: 0, isDivideMode: false)
		// rates = 150 / (100+100) = 0.75
		XCTAssertEqual(r.widthValue1, 75)
		XCTAssertEqual(r.heightValue1, 75)
		XCTAssertEqual(r.widthValue2, 75)
		XCTAssertEqual(r.heightValue2, 75)
		XCTAssertEqual(r.frameSize, NSSize(width: 150, height: 100))
	}

	func testDivideModeScalesAgainstHalfTheCombinedWidth() {
		let r = ViewerSpreadWidthFit.assign(widthValue01: 100, heightValue01: 100, widthValue02: 100, heightValue02: 100,
											 currentWidthValue1: 100, currentHeightValue1: 100,
											 currentWidthValue2: 100, currentHeightValue2: 100,
											 fullscreenWidth: 150, fullscreenHeight: 100, screenHeight: 100,
											 maxEnlargement: 0, isDivideMode: true)
		// rates = 150 / ((100+100)/2) = 150/100 = 1.5
		XCTAssertEqual(r.widthValue1, 150)
		XCTAssertEqual(r.heightValue1, 150)
		// highest (150) >= screenHeight (100): frame width is fullscreenWidth*2, height is the taller page.
		XCTAssertEqual(r.frameSize, NSSize(width: 300, height: 150))
	}

	func testDivideModeTruncatesTheWidthSumToAnIntegerBeforeHalving() {
		// widthSum=201 is odd: integer "/2" must truncate to 100 *before* dividing into
		// fullscreenWidth, not compute a float 100.5 (which would give a different rate).
		let r = ViewerSpreadWidthFit.assign(widthValue01: 101, heightValue01: 100, widthValue02: 100, heightValue02: 100,
											 currentWidthValue1: 101, currentHeightValue1: 100,
											 currentWidthValue2: 100, currentHeightValue2: 100,
											 fullscreenWidth: 100, fullscreenHeight: 100, screenHeight: 100,
											 maxEnlargement: 0, isDivideMode: true)
		// denominator = 201/2 (integer) = 100, rates = 100/100 = 1.0 exactly.
		XCTAssertEqual(r.widthValue1, 101)
		XCTAssertEqual(r.heightValue1, 100)
		XCTAssertEqual(r.widthValue2, 100)
	}

	func testMaxEnlargementResetsAPageToItsOriginalSizeWhenExceeded() {
		let r = ViewerSpreadWidthFit.assign(widthValue01: 100, heightValue01: 100, widthValue02: 50, heightValue02: 50,
											 currentWidthValue1: 100, currentHeightValue1: 100,
											 currentWidthValue2: 50, currentHeightValue2: 50,
											 fullscreenWidth: 300, fullscreenHeight: 100, screenHeight: 100,
											 maxEnlargement: 1.5, isDivideMode: false)
		// rates = 300/150 = 2.0; page1 scales to 200x200 (> 100*1.5=150) -> reset to original 100x100.
		// page2 scales to 100x100 (> 50*1.5=75) -> reset to original 50x50.
		XCTAssertEqual(r.widthValue1, 100)
		XCTAssertEqual(r.heightValue1, 100)
		XCTAssertEqual(r.widthValue2, 50)
		XCTAssertEqual(r.heightValue2, 50)
	}

	func testZeroMaxEnlargementNeverClamps() {
		let r = ViewerSpreadWidthFit.assign(widthValue01: 100, heightValue01: 100, widthValue02: 50, heightValue02: 50,
											 currentWidthValue1: 100, currentHeightValue1: 100,
											 currentWidthValue2: 50, currentHeightValue2: 50,
											 fullscreenWidth: 300, fullscreenHeight: 100, screenHeight: 100,
											 maxEnlargement: 0, isDivideMode: false)
		XCTAssertEqual(r.widthValue1, 200)
		XCTAssertEqual(r.widthValue2, 100)
	}
}
