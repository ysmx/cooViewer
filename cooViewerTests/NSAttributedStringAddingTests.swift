//
//  NSAttributedStringAddingTests.swift
//  cooViewerTests
//

import XCTest

final class NSAttributedStringAddingTests: XCTestCase {

	private func makeString(_ text: String = "1 / 10") -> NSAttributedString {
		NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 12)])
	}

	func testSizeWithBGIsLargerThanPlainSize() {
		let string = makeString()
		let plain = string.size()
		let withBG = string.co_sizeWithBG()
		XCTAssertGreaterThan(withBG.width, plain.width)
		XCTAssertGreaterThan(withBG.height, plain.height)
	}

	func testSizeWithBGMatchesKnownPadding() {
		// sizeWithBG pads width by (rad*2 + 2) and height by 4, where
		// rad = Int(plain.height / 2).
		let string = makeString()
		let plain = string.size()
		let rad = CGFloat(Int(plain.height / 2))
		let withBG = string.co_sizeWithBG()
		XCTAssertEqual(withBG.width, plain.width + rad * 2 + 2, accuracy: 0.001)
		XCTAssertEqual(withBG.height, plain.height + 4, accuracy: 0.001)
	}

	func testEmptyStringStillProducesANonNegativeSize() {
		let string = makeString("")
		let size = string.co_sizeWithBG()
		XCTAssertGreaterThanOrEqual(size.width, 0)
		XCTAssertGreaterThanOrEqual(size.height, 0)
	}
}
