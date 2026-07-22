//
//  ViewerSortModeTransition.swift
//  cooViewer
//
//  Pure sort-mode cycling logic shared by the key and mouse changeSortMode
//  actions, kept free of any Controller state so it can be unit tested
//  directly.
//

import Foundation

@objc final class ViewerSortModeTransition: NSObject {

	/// The sort mode `-setSortMode:page:` should switch to when the user
	/// triggers changeSortMode from the current `sortMode`. Cycles through
	/// name(0)/shuffle(1)/creation-date(2)/modification-date(3) when the
	/// current loader supports date sorting, or just name(0)/shuffle(1)
	/// otherwise. An out-of-range `current` is left unchanged, matching the
	/// original switch statements' implicit no-op default case.
	@objc static func next(current: Int32, canSortByDate: Bool) -> Int32 {
		if canSortByDate {
			switch current {
			case 0: return 2
			case 1: return 0
			case 2: return 3
			case 3: return 1
			default: return current
			}
		} else {
			switch current {
			case 0: return 1
			case 1: return 0
			case 2: return 0
			case 3: return 0
			default: return current
			}
		}
	}
}
