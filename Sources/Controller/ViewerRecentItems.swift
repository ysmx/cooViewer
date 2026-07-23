//
//  ViewerRecentItems.swift
//  cooViewer
//
//  Pure array-splice logic shared by the two places
//  -[Controller openPageLoadDidFinish:] updates the "RecentItems" list
//  (once for the book being closed, once for the book being opened),
//  kept free of Controller/NSUserDefaults state so it can be unit tested
//  directly.
//

import Foundation

@objc final class ViewerRecentItems: NSObject {

	/// Splices `newEntry` into `items` at the front.
	///
	/// If `removeIndex` is given (the position of an existing entry for
	/// the same book, found by the caller via -searchFromRecentItems:),
	/// that entry is dropped first. If `cap` is >= 0, items are then
	/// trimmed from the end until there's room for the new entry without
	/// the result exceeding `cap` total - pass a negative cap to skip
	/// trimming entirely (the book-open call site never trimmed here,
	/// only the book-close one did; preserved as-is rather than changing
	/// behavior).
	@objc static func updated(items: [NSDictionary], removingIndex removeIndex: NSNumber?, newEntry: NSDictionary, cap: Int32) -> [NSDictionary] {
		var result = items
		if let idx = removeIndex?.intValue, idx >= 0, idx < result.count {
			result.remove(at: idx)
		}
		if cap >= 0 {
			while result.count >= Int(cap) {
				result.removeLast()
			}
		}
		result.insert(newEntry, at: 0)
		return result
	}
}
