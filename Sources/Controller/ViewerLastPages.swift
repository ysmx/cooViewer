//
//  ViewerLastPages.swift
//  cooViewer
//
//  Pure array-splice logic shared by the two branches in
//  -[Controller openPageLoadDidFinish:] that update the "LastPages"
//  list for the book being closed (one branch appends a fresh entry,
//  the other only drops the stale one), kept free of Controller/
//  NSUserDefaults state so it can be unit tested directly.
//

import Foundation

@objc final class ViewerLastPages: NSObject {

	/// Removes the entry at `removeIndex` (the position of an existing
	/// entry for the same book, found by the caller via
	/// -searchFromLastPages:), then appends `newEntry` at the end if
	/// given. Pass nil for `newEntry` to just drop the stale entry
	/// without adding a new one.
	@objc static func updated(items: [NSDictionary], removingIndex removeIndex: NSNumber?, newEntry: NSDictionary?) -> [NSDictionary] {
		var result = items
		if let idx = removeIndex?.intValue, idx >= 0, idx < result.count {
			result.remove(at: idx)
		}
		if let newEntry = newEntry {
			result.append(newEntry)
		}
		return result
	}
}
