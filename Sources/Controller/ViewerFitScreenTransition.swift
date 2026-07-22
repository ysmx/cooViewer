//
//  ViewerFitScreenTransition.swift
//  cooViewer
//
//  Pure fitScreenMode transition logic shared by changeViewMode/
//  enlargeViewMode/reduceViewMode in both the key and mouse action
//  switches, kept free of any Controller state so it can be unit tested
//  directly.
//

import Foundation

@objc enum ViewerFitScreenDirection: Int32 {
	case cycle
	case enlarge
	case reduce
}

@objc final class ViewerFitScreenTransition: NSObject {

	// fitScreenMode's raw values (0=fitToScreen, 1=fitToScreenWidth,
	// 2=noScale, 3=fitToScreenWidthDivide) ordered from the most
	// "zoomed out" to the most "zoomed in" - this is the order
	// enlarge/reduce/cycle actually move through, which does not match
	// the raw numeric values.
	private static let sizeOrder: [Int32] = [0, 1, 3, 2]

	/// The fitScreenMode `-changeViewMode:`/`-enlargeViewMode:`/
	/// `-reduceViewMode:` should switch to from `current`, or `nil` if
	/// there's nothing to do (enlarge already at the largest mode, or
	/// reduce already at the smallest mode - `.cycle` always wraps and so
	/// never returns nil for a known mode). An unrecognized `current`
	/// also returns nil, matching the original switch statements'
	/// implicit no-op default case.
	@objc static func target(current: Int32, direction: ViewerFitScreenDirection) -> NSNumber? {
		guard let index = sizeOrder.firstIndex(of: current) else { return nil }
		switch direction {
		case .cycle:
			return NSNumber(value: sizeOrder[(index + 1) % sizeOrder.count])
		case .enlarge:
			guard index + 1 < sizeOrder.count else { return nil }
			return NSNumber(value: sizeOrder[index + 1])
		case .reduce:
			guard index - 1 >= 0 else { return nil }
			return NSNumber(value: sizeOrder[index - 1])
		}
	}
}
