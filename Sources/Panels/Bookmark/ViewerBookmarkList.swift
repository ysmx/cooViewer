//
//  ViewerBookmarkList.swift
//  cooViewer
//
//  Pure operations on a single book's bookmarks list, i.e. the array of
//  {name, page} dictionaries stored either as BookmarkController's
//  bookmarkArray (the currently-open book) or as a per-book "bookmarks"
//  entry inside the BookSettings-backed allBookmark dictionary (the "all
//  bookmarks" panel). Both call sites duplicated the same append/rename
//  logic; this is the first slice of #57's planned BookmarkStore model
//  layer, kept free of any table/UI state so it can be unit tested
//  directly.
//

import Foundation

@objc final class ViewerBookmarkMoveResult: NSObject {
	@objc let bookmarks: [NSDictionary]
	@objc let selectedRange: NSRange

	init(bookmarks: [NSDictionary], selectedRange: NSRange) {
		self.bookmarks = bookmarks
		self.selectedRange = selectedRange
	}
}

@objc final class ViewerBookmarkList: NSObject {

	/// Appends a new "bookmarkN" entry (N = current count + 1) for the given
	/// page, matching -addNewBookmark:'s naming (no collision avoidance
	/// beyond that, same as the original). Returns nil if page < 1, mirroring
	/// the original's NSBeep-and-return guard.
	@objc(appendingBookmarks:page:)
	static func appending(bookmarks: [NSDictionary], page: Int32) -> [NSDictionary]? {
		guard page >= 1 else {
			return nil
		}
		let entry: [String: String] = ["name": "bookmark\(bookmarks.count + 1)", "page": "\(page)"]
		return bookmarks + [entry as NSDictionary]
	}

	/// Replaces the name at `index`, leaving that entry's page untouched.
	/// Out-of-range indexes are a no-op rather than a crash.
	@objc(bookmarksWithNameBookmarks:atIndex:updatedTo:)
	static func updatingName(bookmarks: [NSDictionary], atIndex index: Int32, updatedTo name: NSString) -> [NSDictionary] {
		return replacing(bookmarks: bookmarks, atIndex: index) { entry in
			["name": name, "page": entry["page"] as Any]
		}
	}

	/// Replaces the page at `index`, leaving that entry's name untouched.
	/// Out-of-range indexes are a no-op rather than a crash.
	@objc(bookmarksWithPageBookmarks:atIndex:updatedTo:)
	static func updatingPage(bookmarks: [NSDictionary], atIndex index: Int32, updatedTo page: NSString) -> [NSDictionary] {
		return replacing(bookmarks: bookmarks, atIndex: index) { entry in
			["name": entry["name"] as Any, "page": page]
		}
	}

	/// Removes the entry at `index`. Out-of-range indexes are a no-op rather
	/// than a crash.
	@objc(bookmarksByRemovingBookmarks:atIndex:)
	static func removing(bookmarks: [NSDictionary], atIndex index: Int32) -> [NSDictionary] {
		let i = Int(index)
		guard bookmarks.indices.contains(i) else {
			return bookmarks
		}
		var result = bookmarks
		result.remove(at: i)
		return result
	}

	/// Moves the entries at `indices` (given in ascending order, matching how
	/// -tableView:writeRowsWithIndexes:toPasteboard: enumerates a drag
	/// selection) to just before `row`, preserving their relative order and
	/// leaving every other entry's relative order untouched. `row` counts
	/// positions in the original array. Equivalent to
	/// -co_reorderArray:...'s splice-by-value, but by index -- immune to
	/// that approach silently moving the wrong entry when two bookmarks
	/// happen to have the same name/page. Indices outside the array's
	/// bounds are ignored. The result's selectedRange is where the moved
	/// entries landed, for the caller to reselect after reloading.
	@objc(bookmarksByMovingBookmarks:atIndices:toRow:)
	static func moving(bookmarks: [NSDictionary], atIndices indices: [Int32], toRow row: Int32) -> ViewerBookmarkMoveResult {
		let validIndices = indices.map { Int($0) }.filter { bookmarks.indices.contains($0) }
		guard !validIndices.isEmpty else {
			return ViewerBookmarkMoveResult(bookmarks: bookmarks, selectedRange: NSRange(location: 0, length: 0))
		}
		let indexSet = Set(validIndices)

		let moving = validIndices.map { bookmarks[$0] }
		let remaining = bookmarks.enumerated().filter { !indexSet.contains($0.offset) }.map { $0.element }

		let movedFromAboveRow = validIndices.filter { $0 < Int(row) }.count
		let insertAt = min(max(Int(row) - movedFromAboveRow, 0), remaining.count)

		var result = remaining
		result.insert(contentsOf: moving, at: insertAt)
		return ViewerBookmarkMoveResult(bookmarks: result, selectedRange: NSRange(location: insertAt, length: moving.count))
	}

	private static func replacing(bookmarks: [NSDictionary], atIndex index: Int32, with transform: (NSDictionary) -> [String: Any]) -> [NSDictionary] {
		let i = Int(index)
		guard bookmarks.indices.contains(i) else {
			return bookmarks
		}
		var result = bookmarks
		result[i] = transform(bookmarks[i]) as NSDictionary
		return result
	}
}
