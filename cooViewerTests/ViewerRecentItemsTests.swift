//
//  ViewerRecentItemsTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerRecentItemsTests: XCTestCase {

	private func entry(_ path: String) -> NSDictionary {
		return ["temppath": path]
	}

	func testInsertsNewEntryAtFrontWhenNoExistingMatch() {
		let items = [entry("a"), entry("b")]
		let result = ViewerRecentItems.updated(items: items, removingIndex: nil, newEntry: entry("c"), cap: -1)
		XCTAssertEqual(result.map { $0["temppath"] as! String }, ["c", "a", "b"])
	}

	func testMovesAnExistingEntryToTheFront() {
		let items = [entry("a"), entry("b"), entry("c")]
		// Caller found "b" at index 1 and wants it moved to the front with fresh contents.
		let result = ViewerRecentItems.updated(items: items, removingIndex: 1, newEntry: entry("b"), cap: -1)
		XCTAssertEqual(result.map { $0["temppath"] as! String }, ["b", "a", "c"])
	}

	func testTrimsFromTheEndToStayUnderCapBeforeInserting() {
		let items = [entry("a"), entry("b"), entry("c")]
		let result = ViewerRecentItems.updated(items: items, removingIndex: nil, newEntry: entry("d"), cap: 3)
		XCTAssertEqual(result.map { $0["temppath"] as! String }, ["d", "a", "b"])
	}

	func testNegativeCapNeverTrims() {
		let items = [entry("a"), entry("b"), entry("c")]
		let result = ViewerRecentItems.updated(items: items, removingIndex: nil, newEntry: entry("d"), cap: -1)
		XCTAssertEqual(result.count, 4)
	}

	func testRemovingIndexOutOfRangeIsIgnoredRatherThanCrashing() {
		let items = [entry("a")]
		let result = ViewerRecentItems.updated(items: items, removingIndex: 5, newEntry: entry("b"), cap: -1)
		XCTAssertEqual(result.map { $0["temppath"] as! String }, ["b", "a"])
	}
}
