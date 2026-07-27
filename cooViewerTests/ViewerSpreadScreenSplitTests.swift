//
//  ViewerSpreadScreenSplitTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerSpreadScreenSplitTests: XCTestCase {

	func testRotateMode0KeepsAxesAsIs() {
		let r = ViewerSpreadScreenSplit.assign(contentViewFrame: NSRect(x: 0, y: 0, width: 800, height: 600), rotateMode: 0)
		XCTAssertEqual(r.fullscreenRect, NSRect(x: 0, y: 0, width: 800, height: 600))
	}

	func testRotateMode2KeepsAxesAsIs() {
		let r = ViewerSpreadScreenSplit.assign(contentViewFrame: NSRect(x: 0, y: 0, width: 800, height: 600), rotateMode: 2)
		XCTAssertEqual(r.fullscreenRect, NSRect(x: 0, y: 0, width: 800, height: 600))
	}

	func testRotateMode1SwapsWidthAndHeight() {
		let r = ViewerSpreadScreenSplit.assign(contentViewFrame: NSRect(x: 0, y: 0, width: 800, height: 600), rotateMode: 1)
		XCTAssertEqual(r.fullscreenRect, NSRect(x: 0, y: 0, width: 600, height: 800))
	}

	func testRotateMode3SwapsWidthAndHeight() {
		let r = ViewerSpreadScreenSplit.assign(contentViewFrame: NSRect(x: 0, y: 0, width: 800, height: 600), rotateMode: 3)
		XCTAssertEqual(r.fullscreenRect, NSRect(x: 0, y: 0, width: 600, height: 800))
	}

	func testOddWidthIsTrimmedByOne() {
		let r = ViewerSpreadScreenSplit.assign(contentViewFrame: NSRect(x: 10, y: 10, width: 801, height: 600), rotateMode: 0)
		XCTAssertEqual(r.fullscreenRect, NSRect(x: 10, y: 10, width: 800, height: 600))
	}

	func testOddHeightIsTrimmedByOne() {
		let r = ViewerSpreadScreenSplit.assign(contentViewFrame: NSRect(x: 10, y: 10, width: 800, height: 601), rotateMode: 0)
		XCTAssertEqual(r.fullscreenRect, NSRect(x: 10, y: 10, width: 800, height: 600))
	}

	func testOddTrimIsAppliedAfterTheRotationSwap() {
		// Pre-swap width 601 (odd) becomes the post-swap height, which IS trimmed (odd);
		// pre-swap height 800 becomes the post-swap width and stays even (not trimmed).
		let r = ViewerSpreadScreenSplit.assign(contentViewFrame: NSRect(x: 0, y: 0, width: 601, height: 800), rotateMode: 1)
		XCTAssertEqual(r.fullscreenRect, NSRect(x: 0, y: 0, width: 800, height: 600))
	}

	func testLeftAndRightRectsBisectTheFullscreenRectAtItsMidpoint() {
		let r = ViewerSpreadScreenSplit.assign(contentViewFrame: NSRect(x: 10, y: 20, width: 800, height: 600), rotateMode: 0)
		XCTAssertEqual(r.leftRect, NSRect(x: 10, y: 20, width: 400, height: 600))
		XCTAssertEqual(r.rightRect, NSRect(x: 410, y: 20, width: 400, height: 600))
	}
}
