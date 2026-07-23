//
//  ViewerMouseGesture.swift
//  cooViewer
//
//  Pure decision logic extracted from -[CustomImageView mouseUp:], kept
//  free of view/event state so it can be unit tested directly. The side
//  effects (gestureAction:/goToPar: dispatch) stay in the view.
//
//  Note on axes: CustomImageView's cursorMoved point is built as
//  NSMakePoint(deltaY, deltaX) - its x member holds the VERTICAL delta
//  and its y member the HORIZONTAL delta. The parameter names here
//  follow the stored members, not the screen axes, to keep the call
//  site a 1:1 replacement.
//

import Foundation

@objc final class ViewerMouseGesture: NSObject {

	/// Maps a drag delta to the gesture code -[Controller gestureAction:moved:]
	/// expects: 0=left, 1=right, 2=up, 3=down. Returns -1 when no component
	/// exceeds the 30pt threshold (i.e. this was a click, not a gesture).
	/// On a tie between the horizontal and vertical magnitudes, horizontal
	/// wins - matching the original `ud > lr` comparison.
	@objc static func gestureCode(movedX x: CGFloat, movedY y: CGFloat) -> Int32 {
		let horizontal = abs(y) > 30 ? abs(y) : 0
		let vertical = abs(x) > 30 ? abs(x) : 0
		if horizontal == 0 && vertical == 0 {
			return -1
		}
		if vertical > horizontal {
			return x > 30 ? 2 : 3
		} else {
			return y < -30 ? 0 : 1
		}
	}

	/// Maps a click at pointX inside the page bar to the 0-1 page fraction
	/// -[Controller goToPar:] expects. `barRect` is the raw page-bar rect;
	/// the 2pt frame inset and the right-to-left mirroring both happen here,
	/// matching the original inline math.
	@objc static func pageBarFraction(pointX: CGFloat, barRect: CGRect, readFromLeft: Bool) -> CGFloat {
		let inner = barRect.insetBy(dx: 2, dy: 2)
		var position = pointX - inner.origin.x
		if !readFromLeft {
			position = inner.size.width - position - 1
		}
		return position / inner.size.width
	}
}
