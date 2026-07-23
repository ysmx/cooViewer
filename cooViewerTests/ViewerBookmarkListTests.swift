//
//  ViewerBookmarkListTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerBookmarkListTests: XCTestCase {

	func testAppendingNamesTheNewEntryByOneBasedCount() {
		let existing: [NSDictionary] = [
			["name": "cover", "page": "1"],
			["name": "bookmark2", "page": "10"],
		]
		let result = ViewerBookmarkList.appending(bookmarks: existing, page: 42)
		XCTAssertEqual(result?.count, 3)
		XCTAssertEqual(result?[2]["name"] as? String, "bookmark3")
		XCTAssertEqual(result?[2]["page"] as? String, "42")
		// Existing entries are untouched.
		XCTAssertEqual(result?[0]["name"] as? String, "cover")
	}

	func testAppendingToAnEmptyListStartsAtBookmarkOne() {
		let result = ViewerBookmarkList.appending(bookmarks: [], page: 5)
		XCTAssertEqual(result?[0]["name"] as? String, "bookmark1")
	}

	func testAppendingReturnsNilForPageBelowOne() {
		XCTAssertNil(ViewerBookmarkList.appending(bookmarks: [], page: 0))
		XCTAssertNil(ViewerBookmarkList.appending(bookmarks: [], page: -3))
	}

	func testUpdatingNameLeavesThePageUnchanged() {
		let existing: [NSDictionary] = [["name": "old", "page": "7"]]
		let result = ViewerBookmarkList.updatingName(bookmarks: existing, atIndex: 0, updatedTo: "new")
		XCTAssertEqual(result[0]["name"] as? String, "new")
		XCTAssertEqual(result[0]["page"] as? String, "7")
	}

	func testUpdatingPageLeavesTheNameUnchanged() {
		let existing: [NSDictionary] = [["name": "cover", "page": "1"]]
		let result = ViewerBookmarkList.updatingPage(bookmarks: existing, atIndex: 0, updatedTo: "99")
		XCTAssertEqual(result[0]["name"] as? String, "cover")
		XCTAssertEqual(result[0]["page"] as? String, "99")
	}

	func testUpdatingOnlyTouchesTheTargetedIndex() {
		let existing: [NSDictionary] = [
			["name": "a", "page": "1"],
			["name": "b", "page": "2"],
			["name": "c", "page": "3"],
		]
		let result = ViewerBookmarkList.updatingName(bookmarks: existing, atIndex: 1, updatedTo: "renamed")
		XCTAssertEqual(result[0]["name"] as? String, "a")
		XCTAssertEqual(result[1]["name"] as? String, "renamed")
		XCTAssertEqual(result[2]["name"] as? String, "c")
	}

	func testUpdatingOutOfRangeIndexIsIgnoredRatherThanCrashing() {
		let existing: [NSDictionary] = [["name": "a", "page": "1"]]
		XCTAssertEqual(ViewerBookmarkList.updatingName(bookmarks: existing, atIndex: 5, updatedTo: "x"), existing)
		XCTAssertEqual(ViewerBookmarkList.updatingPage(bookmarks: existing, atIndex: -1, updatedTo: "9"), existing)
	}

	func testRemovingDropsOnlyTheTargetedIndex() {
		let existing: [NSDictionary] = [
			["name": "a", "page": "1"],
			["name": "b", "page": "2"],
			["name": "c", "page": "3"],
		]
		let result = ViewerBookmarkList.removing(bookmarks: existing, atIndex: 1)
		XCTAssertEqual(result.count, 2)
		XCTAssertEqual(result[0]["name"] as? String, "a")
		XCTAssertEqual(result[1]["name"] as? String, "c")
	}

	func testRemovingTheOnlyEntryLeavesAnEmptyList() {
		let existing: [NSDictionary] = [["name": "a", "page": "1"]]
		XCTAssertEqual(ViewerBookmarkList.removing(bookmarks: existing, atIndex: 0), [])
	}

	func testRemovingOutOfRangeIndexIsIgnoredRatherThanCrashing() {
		let existing: [NSDictionary] = [["name": "a", "page": "1"]]
		XCTAssertEqual(ViewerBookmarkList.removing(bookmarks: existing, atIndex: 5), existing)
		XCTAssertEqual(ViewerBookmarkList.removing(bookmarks: existing, atIndex: -1), existing)
	}
}
