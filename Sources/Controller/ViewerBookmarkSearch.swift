//
//  ViewerBookmarkSearch.swift
//  cooViewer
//
//  Pure bookmark-page search logic shared by -nextBookmark/-backBookmark,
//  kept free of any Controller state so it can be unit tested directly.
//

import Foundation

@objc final class ViewerBookmarkSearch: NSObject {

	/// The smallest bookmark page strictly greater than currentEffectivePage,
	/// or nil if there isn't one.
	@objc static func nextBookmarkPage(bookmarkPages: [NSNumber], currentEffectivePage: Int32) -> NSNumber? {
		let sorted = bookmarkPages.map { $0.int32Value }.sorted()
		for page in sorted where page > currentEffectivePage {
			return NSNumber(value: page)
		}
		return nil
	}

	/// The largest bookmark page strictly less than currentEffectivePage,
	/// or nil if there isn't one.
	@objc static func previousBookmarkPage(bookmarkPages: [NSNumber], currentEffectivePage: Int32) -> NSNumber? {
		let sorted = bookmarkPages.map { $0.int32Value }.sorted(by: >)
		for page in sorted where page < currentEffectivePage {
			return NSNumber(value: page)
		}
		return nil
	}
}
