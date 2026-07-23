//
//  ViewerBookSettingsKeyTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerBookSettingsKeyTests: XCTestCase {

	func testReturnsExistingKeyWhenTheBookAlreadyHasAnEntry() {
		let key = ViewerBookSettingsKey.resolvedKey(existingKeys: ["Book A", "Book A#2"], existingKey: "Book A#2", baseName: "Book A")
		XCTAssertEqual(key, "Book A#2")
	}

	func testUsesBaseNameWhenNoExistingKeyAndNoCollision() {
		let key = ViewerBookSettingsKey.resolvedKey(existingKeys: ["Other Book"], existingKey: nil, baseName: "Book A")
		XCTAssertEqual(key, "Book A")
	}

	func testAppendsHashTwoWhenBaseNameCollidesWithADifferentBook() {
		let key = ViewerBookSettingsKey.resolvedKey(existingKeys: ["Book A"], existingKey: nil, baseName: "Book A")
		XCTAssertEqual(key, "Book A#2")
	}

	func testKeepsIncrementingUntilAnUnusedSuffixIsFound() {
		let key = ViewerBookSettingsKey.resolvedKey(existingKeys: ["Book A", "Book A#2", "Book A#3"], existingKey: nil, baseName: "Book A")
		XCTAssertEqual(key, "Book A#4")
	}

	func testEmptyExistingKeysUsesBaseNameDirectly() {
		let key = ViewerBookSettingsKey.resolvedKey(existingKeys: [], existingKey: nil, baseName: "Book A")
		XCTAssertEqual(key, "Book A")
	}
}
