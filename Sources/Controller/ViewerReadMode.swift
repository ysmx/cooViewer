//
//  ViewerReadMode.swift
//  cooViewer
//
//  Pure readMode cycling logic shared by the key and mouse changeReadMode
//  actions, kept free of any Controller state so it can be unit tested
//  directly.
//

import Foundation

@objc final class ViewerReadMode: NSObject {

	/// The readMode `-changeReadMode:` should switch to from `current`
	/// (0/1/2/3), cycling forward and wrapping back to 0. An out-of-range
	/// `current` is left unchanged, matching the original if-chain's
	/// implicit no-op when none of its conditions matched.
	@objc static func next(current: Int32) -> Int32 {
		switch current {
		case 0: return 1
		case 1: return 2
		case 2: return 3
		case 3: return 0
		default: return current
		}
	}
}
