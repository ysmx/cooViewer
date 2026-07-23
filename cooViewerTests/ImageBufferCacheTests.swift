//
//  ImageBufferCacheTests.swift
//  cooViewerTests
//

import XCTest

final class ImageBufferCacheTests: XCTestCase {

	private func image() -> NSImage {
		return NSImage(size: NSSize(width: 1, height: 1))
	}

	func testReturnsNilForAMissingKey() {
		let cache = ImageBufferCache()
		XCTAssertNil(cache.image(forKey: "a"))
	}

	func testReturnsTheStoredImageForAnExactKeyMatch() {
		let cache = ImageBufferCache()
		let img = image()
		cache.insert(img, forKey: "a")
		XCTAssertIdentical(cache.image(forKey: "a"), img)
	}

	func testTrimRemovesTheOldestEntriesFirst() {
		let cache = ImageBufferCache()
		let a = image(), b = image(), c = image()
		cache.insert(a, forKey: "a")
		cache.insert(b, forKey: "b")
		cache.insert(c, forKey: "c")
		cache.trim(toCapacity: 2)
		XCTAssertNil(cache.image(forKey: "a"))
		XCTAssertIdentical(cache.image(forKey: "b"), b)
		XCTAssertIdentical(cache.image(forKey: "c"), c)
	}

	func testHitTouchesTheEntryToTheEndSoItSurvivesATrim() {
		let cache = ImageBufferCache()
		let a = image(), b = image()
		cache.insert(a, forKey: "a")
		cache.insert(b, forKey: "b")
		_ = cache.image(forKey: "a")
		cache.trim(toCapacity: 1)
		XCTAssertIdentical(cache.image(forKey: "a"), a)
		XCTAssertNil(cache.image(forKey: "b"))
	}

	func testRemoveAllClearsEveryEntry() {
		let cache = ImageBufferCache()
		cache.insert(image(), forKey: "a")
		cache.removeAll()
		XCTAssertNil(cache.image(forKey: "a"))
	}

	func testTrimToACapacityAtOrAboveCountIsANoOp() {
		let cache = ImageBufferCache()
		let a = image()
		cache.insert(a, forKey: "a")
		cache.trim(toCapacity: 5)
		XCTAssertIdentical(cache.image(forKey: "a"), a)
	}
}
