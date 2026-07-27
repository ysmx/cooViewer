//
//  ViewerSpreadScreenSplit.swift
//  cooViewer
//
//  Pure geometry helper extracted from CustomImageView's
//  -getDrawImagesInfo:and:. Given the window content view's frame and the
//  rotation mode, computes the (possibly axis-swapped, even-sized)
//  fullscreen rect used as the spread's drawing bounds, plus its left/right
//  halves. Independent of fitScreenMode and image sizes. See #116.
//

import AppKit

@objc final class ViewerSpreadScreenSplit: NSObject {

	@objc let fullscreenRect: NSRect
	@objc let leftRect: NSRect
	@objc let rightRect: NSRect

	private init(fullscreenRect: NSRect, leftRect: NSRect, rightRect: NSRect) {
		self.fullscreenRect = fullscreenRect
		self.leftRect = leftRect
		self.rightRect = rightRect
	}

	@objc(assignForContentViewFrame:rotateMode:)
	static func assign(contentViewFrame: NSRect, rotateMode: Int32) -> ViewerSpreadScreenSplit {
		var rect = contentViewFrame
		// 90/270-degree rotation swaps which screen axis is "width" for
		// layout purposes.
		if rotateMode == 1 || rotateMode == 3 {
			rect = NSRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.height, height: rect.size.width)
		}
		// Trim to even width/height so the later left/right bisection and
		// centering math divide evenly, matching the original's int-cast
		// truncation.
		if Int(rect.size.width) % 2 != 0 {
			rect.size.width -= 1
		}
		if Int(rect.size.height) % 2 != 0 {
			rect.size.height -= 1
		}

		// Equivalent to NSDivideRect(rect, &leftRect, &rightRect, rect.size.width / 2, .minXEdge).
		let halfWidth = rect.size.width / 2
		let leftRect = NSRect(x: rect.minX, y: rect.minY, width: halfWidth, height: rect.height)
		let rightRect = NSRect(x: rect.minX + halfWidth, y: rect.minY, width: rect.width - halfWidth, height: rect.height)

		return ViewerSpreadScreenSplit(fullscreenRect: rect, leftRect: leftRect, rightRect: rightRect)
	}
}
