//
//  ViewerMouseBindingTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerMouseBindingTests: XCTestCase {

	func testNoModifierBelowOneHundred() {
		let b = ViewerMouseBinding.decode(modifier: 0)
		XCTAssertEqual(b.clickIndex, 0)
		XCTAssertFalse(b.shift); XCTAssertFalse(b.option); XCTAssertFalse(b.control)
	}

	func testEachModifierBitBelowOneHundred() {
		XCTAssertTrue(ViewerMouseBinding.decode(modifier: 1).shift)
		XCTAssertTrue(ViewerMouseBinding.decode(modifier: 2).option)
		XCTAssertTrue(ViewerMouseBinding.decode(modifier: 4).control)
	}

	func testCombinedModifierBits() {
		let b = ViewerMouseBinding.decode(modifier: 7)
		XCTAssertTrue(b.shift); XCTAssertTrue(b.option); XCTAssertTrue(b.control)
	}

	func testUnrecognizedRemainderSetsNoModifiers() {
		// The original switch's `default: break` left all three checkboxes off.
		let b = ViewerMouseBinding.decode(modifier: 108)
		XCTAssertEqual(b.clickIndex, 1)
		XCTAssertFalse(b.shift); XCTAssertFalse(b.option); XCTAssertFalse(b.control)
	}

	func testHundredsStepThroughClickIndicesOneToNine() {
		XCTAssertEqual(ViewerMouseBinding.decode(modifier: 100).clickIndex, 1)
		XCTAssertEqual(ViewerMouseBinding.decode(modifier: 503).clickIndex, 5)
		XCTAssertEqual(ViewerMouseBinding.decode(modifier: 906).clickIndex, 9)
	}

	func testAtOrAboveOneThousandPinsToClickIndexTen() {
		XCTAssertEqual(ViewerMouseBinding.decode(modifier: 1000).clickIndex, 10)
		XCTAssertEqual(ViewerMouseBinding.decode(modifier: 1005).clickIndex, 10)
	}

	func testRemainderIsPreservedAcrossClickIndexBoundaries() {
		let b = ViewerMouseBinding.decode(modifier: 503)
		XCTAssertTrue(b.shift); XCTAssertTrue(b.option); XCTAssertFalse(b.control)
	}
}
