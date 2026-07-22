//
//  ViewerLoupeRate.swift
//  cooViewer
//
//  Pure loupe-magnification-rate arithmetic shared by loupeRatePlus/
//  loupeRateMinus in both the key and mouse action switches, kept free of
//  any Controller state so it can be unit tested directly.
//

import Foundation

@objc final class ViewerLoupeRate: NSObject {

	/// loupeRatePlus has no upper clamp - preserved as-is (not fixed here)
	/// since this is existing behavior, of unclear intent, being ported
	/// rather than a bug to silently correct.
	@objc static func increased(current: Float, by amount: Float) -> Float {
		current + amount
	}

	/// loupeRateMinus clamps to a 1.0 floor.
	@objc static func decreased(current: Float, by amount: Float) -> Float {
		let decreased = current - amount
		return decreased > 1.0 ? decreased : 1.0
	}
}
