//
//  NSDictionary_Adding.swift
//  cooViewer
//
//  Canonical display-order comparators for the key/mouse binding rows shown
//  in the Preferences window's input tables - sorts by the fixed action
//  sequence documented below (matching the menu/UI grouping), not by raw
//  action number, with same-action ties broken by key/modifier.
//

import Foundation

extension NSDictionary {

	// 0:nextpage 1:prevpage 2:halfnext 3:halfprev 4:lastpage 5:toppage
	// 6:nextbookmark 7:prevbookmark 8:nextfolder 9:prevfolder 10:add/removebookmark
	// 11:switchSingle 12:shownumber 13:skip 14:backskip 15:origRight 16:origLeft
	// 17:slideshow 18:showThumbnail 19:changeReadMode 20:showPageBar 21:Go to Page
	// 22:show in FinderR 23:show in finderL
	// 24:PageUp 25:PageDown 26:PageUp+PrevPage 27:PageDown+NextPage
	// 28:ScrollToTop 29:ScrollToEnd 30:ScrollUp 31:ScrollDown
	// 32:scrollLeft 33:Scrollright
	// 34:loupe
	// 35:nextSubFolder 36:prevSubFolder
	// 37:loupeRatePlus 38:loupeRateMinus
	// 39:goto%
	// 40:rotateRight 41:rotateLeft
	// 42:changeViewMode
	// 51:enlargeViewMode
	// 52:reduceViewMode
	// 43:trashRight 44:trashLeft
	// 45:changeSortMode
	// 46:close
	// 47:random
	// 48:openTheLastPage
	// 49:switchFullScreen
	// 50:minimizeWindow
	private static let keyArrayOrder: [Int] = [
		0, 1, 2, 3, 4, 5, 13, 14, 21, 39, 48, 17,
		6, 7, 10, 8, 9, 35, 36,
		18, 40, 41, 42, 51, 52, 15, 16, 22,
		23, 43, 44, 11, 19, 45, 47, 12,
		20, 34, 37, 38, 24, 25, 26,
		27, 28, 29, 30, 31, 32, 33, 46, 49, 50,
	]

	// 0:next/prevpage 1:halfnext/prevpage 2:last/toppage 3:next/prevbookmark
	// 4:next/prevfolder 5:skip/backskip 6:nextpage 7:prevpage 8:halfnext
	// 9:halfprev 10:lastpage 11:toppage 12:nextbookmark
	// 13:prevbookmark 14:nextfolder 15:prevfolder 16:add/removebookmark
	// 17:switchSingle 18:shownumber 19:skip 20:backskip
	// 21:origRight 22:origLeft 23:slideshow 24:showThumbnail
	// 25:changeReadMode 26:showPageBar 27:ViewOriginal(L/R) 28:Show in Finder(right)
	// 29:Show in Finder(left) 30:Show in Finder(L/R)
	// 31:PageUp 32:PageDown 33:PageUp+PrevPage 34:PageDown+NextPage
	// 35:ScrollToTop 36:ScrollToEnd 37:ScrollUp 38:ScrollDown
	// 39:scrollLeft 40:Scrollright 41:DragScroll 42:PageUp/down+Prev/nextPage
	// 43:loupe
	// 44:nextSubFolder 45:prevSubFolder 46:nextprevSubFolder
	// 47:loupeRatePlus 48:loupeRateMinus
	// 49:rotateRight 50:rotateLeft
	// 51:changeViewMode
	// 63:enlargeViewMode
	// 64:reduceViewMode
	// 52:trashRight 53:trashLeft
	// 54:trash(L/R)
	// 55:rotate(L/R)
	// 56:changeSortMode
	// 57:close
	// 58:random
	// 59:ContextualMenu
	// 60:openTheLastPage
	// 61:switchFullScreen
	// 62:minimizeWindow
	private static let mouseArrayOrder: [Int] = [
		0, 1, 2, 3, 4, 46, 5, 27, 30, 54, 55, 42,
		6, 7, 8, 9, 10, 11, 19, 20, 60, 23, 12, 13, 16, 14, 15, 44, 45,
		24, 49, 50, 51, 63, 64, 21, 22, 28, 29, 52, 53, 17, 25, 56, 58, 18, 26, 43, 47, 48, 41, 31, 32, 33, 34,
		35, 36, 37, 38, 39, 40, 57, 61, 62, 59,
	]

	private func co_actionNumber() -> Int {
		(self["action"] as? NSNumber)?.intValue ?? 0
	}

	// The original Objective-C fell back to comparing two autoreleased
	// NSString instances with `<`/`==`/`>` (pointer comparison, not value
	// comparison) when an action wasn't found in the canonical order array -
	// effectively meaningless, and never actually exercised since the arrays
	// above already enumerate every valid action number. This numeric
	// fallback preserves the same "never actually reached" status without
	// replicating the pointer-comparison quirk.
	private static func co_compare(_ action: Int, _ otherAction: Int, order: [Int], tieBreaker: () -> ComparisonResult) -> ComparisonResult {
		if let index = order.firstIndex(of: action), let otherIndex = order.firstIndex(of: otherAction) {
			if index < otherIndex { return .orderedAscending }
			if index > otherIndex { return .orderedDescending }
			return tieBreaker()
		}
		if action < otherAction { return .orderedAscending }
		if action > otherAction { return .orderedDescending }
		return .orderedSame
	}

	@objc(keyArrayCompare:)
	func co_keyArrayCompare(_ otherDic: NSDictionary) -> ComparisonResult {
		NSDictionary.co_compare(co_actionNumber(), otherDic.co_actionNumber(), order: NSDictionary.keyArrayOrder) {
			let selfKey = self["key"] as? String ?? ""
			let otherKey = otherDic["key"] as? String ?? ""
			let keyResult = selfKey.compare(otherKey, options: .caseInsensitive)
			if keyResult != .orderedSame { return keyResult }
			let selfModifier = (self["modifier"] as? NSNumber) ?? 0
			let otherModifier = (otherDic["modifier"] as? NSNumber) ?? 0
			return selfModifier.compare(otherModifier)
		}
	}

	@objc(mouseArrayCompare:)
	func co_mouseArrayCompare(_ otherDic: NSDictionary) -> ComparisonResult {
		NSDictionary.co_compare(co_actionNumber(), otherDic.co_actionNumber(), order: NSDictionary.mouseArrayOrder) {
			let selfModifier = (self["modifier"] as? NSNumber) ?? 0
			let otherModifier = (otherDic["modifier"] as? NSNumber) ?? 0
			return selfModifier.compare(otherModifier)
		}
	}
}
