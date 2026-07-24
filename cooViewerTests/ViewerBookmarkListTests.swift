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

	// MARK: removing (multi-index)

	func testRemovingAtIndicesDropsAllSelectedRowsInOnePass() {
		let existing: [NSDictionary] = [
			["name": "a", "page": "1"],
			["name": "b", "page": "2"],
			["name": "c", "page": "3"],
			["name": "d", "page": "4"],
		]
		// Regression test: removing indices one at a time with the single-index
		// -removing(bookmarks:atIndex:) shifts later indices after each
		// removal, so a naive loop over [1, 2] would actually delete "b" and
		// "d" instead of "b" and "c".
		let result = ViewerBookmarkList.removing(bookmarks: existing, atIndices: [1, 2])
		XCTAssertEqual(names(result), ["a", "d"])
	}

	func testRemovingAtIndicesOrderDoesNotMatter() {
		let existing: [NSDictionary] = [
			["name": "a", "page": "1"],
			["name": "b", "page": "2"],
			["name": "c", "page": "3"],
		]
		let result = ViewerBookmarkList.removing(bookmarks: existing, atIndices: [2, 0])
		XCTAssertEqual(names(result), ["b"])
	}

	func testRemovingAtIndicesIgnoresOutOfRangeAndDuplicateIndices() {
		let existing: [NSDictionary] = [["name": "a", "page": "1"], ["name": "b", "page": "2"]]
		let result = ViewerBookmarkList.removing(bookmarks: existing, atIndices: [0, 0, 99])
		XCTAssertEqual(names(result), ["b"])
	}

	func testRemovingAtIndicesWithNoValidIndicesIsANoOp() {
		let existing: [NSDictionary] = [["name": "a", "page": "1"]]
		XCTAssertEqual(ViewerBookmarkList.removing(bookmarks: existing, atIndices: []), existing)
		XCTAssertEqual(ViewerBookmarkList.removing(bookmarks: existing, atIndices: [42]), existing)
	}

	// MARK: moving

	private func names(_ list: [NSDictionary]) -> [String] {
		return list.map { $0["name"] as! String }
	}

	private let abcde: [NSDictionary] = ["a", "b", "c", "d", "e"].map { ["name": $0, "page": "1"] }

	func testMovingASingleEntryDownPastLaterRows() {
		let result = ViewerBookmarkList.moving(bookmarks: abcde, atIndices: [0], toRow: 3)
		XCTAssertEqual(names(result.bookmarks), ["b", "c", "a", "d", "e"])
		XCTAssertEqual(result.selectedRange, NSRange(location: 2, length: 1))
	}

	func testMovingASingleEntryUpBeforeEarlierRows() {
		let result = ViewerBookmarkList.moving(bookmarks: abcde, atIndices: [4], toRow: 1)
		XCTAssertEqual(names(result.bookmarks), ["a", "e", "b", "c", "d"])
		XCTAssertEqual(result.selectedRange, NSRange(location: 1, length: 1))
	}

	func testMovingMultipleEntriesPreservesTheirAscendingOrder() {
		let result = ViewerBookmarkList.moving(bookmarks: abcde, atIndices: [1, 3], toRow: 0)
		XCTAssertEqual(names(result.bookmarks), ["b", "d", "a", "c", "e"])
		XCTAssertEqual(result.selectedRange, NSRange(location: 0, length: 2))
	}

	func testMovingToItsOwnOriginalPositionIsANoOp() {
		let result = ViewerBookmarkList.moving(bookmarks: abcde, atIndices: [2], toRow: 2)
		XCTAssertEqual(names(result.bookmarks), ["a", "b", "c", "d", "e"])
	}

	func testMovingToTheEndRowAppendsAtTheEnd() {
		let result = ViewerBookmarkList.moving(bookmarks: abcde, atIndices: [0], toRow: 5)
		XCTAssertEqual(names(result.bookmarks), ["b", "c", "d", "e", "a"])
		XCTAssertEqual(result.selectedRange, NSRange(location: 4, length: 1))
	}

	func testMovingWithNoValidIndicesIsANoOp() {
		let result = ViewerBookmarkList.moving(bookmarks: abcde, atIndices: [99], toRow: 0)
		XCTAssertEqual(names(result.bookmarks), ["a", "b", "c", "d", "e"])
		XCTAssertEqual(result.selectedRange, NSRange(location: 0, length: 0))
	}
}
