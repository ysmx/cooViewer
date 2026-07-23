//
//  ViewerLastPagesTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerLastPagesTests: XCTestCase {

	private func entry(_ path: String) -> NSDictionary {
		return ["temppath": path]
	}

	func testAppendsNewEntryAtEndWhenNoExistingMatch() {
		let items = [entry("a"), entry("b")]
		let result = ViewerLastPages.updated(items: items, removingIndex: nil, newEntry: entry("c"))
		XCTAssertEqual(result.map { $0["temppath"] as! String }, ["a", "b", "c"])
	}

	func testMovesAnExistingEntryToTheEndWithFreshContents() {
		let items = [entry("a"), entry("b"), entry("c")]
		// Caller found "b" at index 1 and wants it replaced with fresh contents at the end.
		let result = ViewerLastPages.updated(items: items, removingIndex: 1, newEntry: entry("b"))
		XCTAssertEqual(result.map { $0["temppath"] as! String }, ["a", "c", "b"])
	}

	func testNilNewEntryOnlyDropsTheStaleEntry() {
		let items = [entry("a"), entry("b"), entry("c")]
		let result = ViewerLastPages.updated(items: items, removingIndex: 1, newEntry: nil)
		XCTAssertEqual(result.map { $0["temppath"] as! String }, ["a", "c"])
	}

	func testNilRemovingIndexAndNilNewEntryLeavesItemsUnchanged() {
		let items = [entry("a"), entry("b")]
		let result = ViewerLastPages.updated(items: items, removingIndex: nil, newEntry: nil)
		XCTAssertEqual(result.map { $0["temppath"] as! String }, ["a", "b"])
	}

	func testRemovingIndexOutOfRangeIsIgnoredRatherThanCrashing() {
		let items = [entry("a")]
		let result = ViewerLastPages.updated(items: items, removingIndex: 5, newEntry: entry("b"))
		XCTAssertEqual(result.map { $0["temppath"] as! String }, ["a", "b"])
	}
}
