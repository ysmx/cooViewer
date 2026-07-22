//
//  ViewerScrollDelta.swift
//  cooViewer
//
//  Pure scroll-amount-to-point arithmetic shared by the key and mouse
//  ScrollUp/ScrollDown/ScrollLeft/ScrollRight actions, kept free of any
//  Controller/AppKit state so it can be unit tested directly.
//

import Foundation

@objc final class ViewerScrollDelta: NSObject {

	/// Builds the point passed to `-[CustomImageView scrollTo:]` for a given
	/// scroll amount, where `dx`/`dy` are direction multipliers (-1/0/1) -
	/// e.g. ScrollUp passes dx:0 dy:-1, ScrollRight passes dx:-1 dy:0.
	@objc static func point(value: Int32, dx: Int32, dy: Int32) -> NSPoint {
		NSPoint(x: CGFloat(dx * value), y: CGFloat(dy * value))
	}
}
