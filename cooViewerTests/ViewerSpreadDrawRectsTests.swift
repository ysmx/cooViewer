//
//  ViewerSpreadDrawRectsTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerSpreadDrawRectsTests: XCTestCase {

	// Distinct values so a mixed-up axis or operand shows up immediately.
	// widthValue1=10, heightValue1=20, widthValue2=30, heightValue2=40, center1=5, center2=6, x=7

	private func assign(rotateMode: Int32, readFromLeft: Bool) -> ViewerSpreadDrawRects {
		return ViewerSpreadDrawRects.assign(rotateMode: rotateMode, readFromLeft: readFromLeft,
											 widthValue1: 10, heightValue1: 20,
											 widthValue2: 30, heightValue2: 40,
											 center1: 5, center2: 6, x: 7)
	}

	func testRotateMode0ReadFromLeft() {
		let r = assign(rotateMode: 0, readFromLeft: true)
		XCTAssertEqual(r.fRect, NSRect(x: 7, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.sRect, NSRect(x: 17, y: 6, width: 30, height: 40))
		XCTAssertEqual(r.drawRect1, NSRect(x: 7, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.drawRect2, NSRect(x: 17, y: 6, width: 30, height: 40))
	}

	func testRotateMode0ReadFromRight() {
		let r = assign(rotateMode: 0, readFromLeft: false)
		XCTAssertEqual(r.fRect, NSRect(x: 7, y: 6, width: 30, height: 40))
		XCTAssertEqual(r.sRect, NSRect(x: 37, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.drawRect1, NSRect(x: 37, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.drawRect2, NSRect(x: 7, y: 6, width: 30, height: 40))
	}

	func testRotateMode1ReadFromLeftSwapsWidthAndHeight() {
		let r = assign(rotateMode: 1, readFromLeft: true)
		XCTAssertEqual(r.fRect, NSRect(x: 5, y: 7, width: 20, height: 10))
		XCTAssertEqual(r.sRect, NSRect(x: 6, y: 17, width: 40, height: 30))
		// drawRect1/drawRect2 don't depend on rotateMode, only readFromLeft.
		XCTAssertEqual(r.drawRect1, NSRect(x: 7, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.drawRect2, NSRect(x: 17, y: 6, width: 30, height: 40))
	}

	func testRotateMode1ReadFromRight() {
		let r = assign(rotateMode: 1, readFromLeft: false)
		XCTAssertEqual(r.fRect, NSRect(x: 6, y: 7, width: 40, height: 30))
		XCTAssertEqual(r.sRect, NSRect(x: 5, y: 37, width: 20, height: 10))
		XCTAssertEqual(r.drawRect1, NSRect(x: 37, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.drawRect2, NSRect(x: 7, y: 6, width: 30, height: 40))
	}

	func testRotateMode3ReadFromLeftSwapsFAndS() {
		let r = assign(rotateMode: 3, readFromLeft: true)
		XCTAssertEqual(r.sRect, NSRect(x: 6, y: 7, width: 40, height: 30))
		XCTAssertEqual(r.fRect, NSRect(x: 5, y: 37, width: 20, height: 10))
		XCTAssertEqual(r.drawRect1, NSRect(x: 7, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.drawRect2, NSRect(x: 17, y: 6, width: 30, height: 40))
	}

	func testRotateMode3ReadFromRight() {
		let r = assign(rotateMode: 3, readFromLeft: false)
		XCTAssertEqual(r.sRect, NSRect(x: 5, y: 7, width: 20, height: 10))
		XCTAssertEqual(r.fRect, NSRect(x: 6, y: 17, width: 40, height: 30))
		XCTAssertEqual(r.drawRect1, NSRect(x: 37, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.drawRect2, NSRect(x: 7, y: 6, width: 30, height: 40))
	}

	func testRotateMode2ReadFromLeft() {
		let r = assign(rotateMode: 2, readFromLeft: true)
		XCTAssertEqual(r.fRect, NSRect(x: 7, y: 6, width: 30, height: 40))
		XCTAssertEqual(r.sRect, NSRect(x: 37, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.drawRect1, NSRect(x: 7, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.drawRect2, NSRect(x: 17, y: 6, width: 30, height: 40))
	}

	func testRotateMode2ReadFromRight() {
		let r = assign(rotateMode: 2, readFromLeft: false)
		XCTAssertEqual(r.sRect, NSRect(x: 7, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.fRect, NSRect(x: 17, y: 6, width: 30, height: 40))
		XCTAssertEqual(r.drawRect1, NSRect(x: 37, y: 5, width: 10, height: 20))
		XCTAssertEqual(r.drawRect2, NSRect(x: 7, y: 6, width: 30, height: 40))
	}

	func testUnrecognizedRotateModeFallsBackToTheDefaultBranch() {
		let recognized = assign(rotateMode: 0, readFromLeft: true)
		let unrecognized = assign(rotateMode: 99, readFromLeft: true)
		XCTAssertEqual(recognized.fRect, unrecognized.fRect)
		XCTAssertEqual(recognized.sRect, unrecognized.sRect)
	}
}
