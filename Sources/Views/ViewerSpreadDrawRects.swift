//
//  ViewerSpreadDrawRects.swift
//  cooViewer
//
//  Pure geometry helper extracted from CustomImageView's
//  -getDrawImagesInfo:and:. Given the already-scaled width/height/center
//  values for a two-page spread plus the rotation mode and reading
//  direction, decides where the "first"/"second" page rects (fRect/sRect,
//  used for URL-rect hit testing) and the actual draw rects (drawRect1/
//  drawRect2) go. Swift port of the tail of that method; see #93.
//

import AppKit

@objc final class ViewerSpreadDrawRects: NSObject {

	@objc let fRect: NSRect
	@objc let sRect: NSRect
	@objc let drawRect1: NSRect
	@objc let drawRect2: NSRect

	private init(fRect: NSRect, sRect: NSRect, drawRect1: NSRect, drawRect2: NSRect) {
		self.fRect = fRect
		self.sRect = sRect
		self.drawRect1 = drawRect1
		self.drawRect2 = drawRect2
	}

	@objc(assignForRotateMode:readFromLeft:widthValue1:heightValue1:widthValue2:heightValue2:center1:center2:x:)
	static func assign(rotateMode: Int32, readFromLeft: Bool, widthValue1: Int32, heightValue1: Int32, widthValue2: Int32, heightValue2: Int32, center1: Int32, center2: Int32, x: Int32) -> ViewerSpreadDrawRects {
		let w1 = CGFloat(widthValue1)
		let h1 = CGFloat(heightValue1)
		let w2 = CGFloat(widthValue2)
		let h2 = CGFloat(heightValue2)
		let c1 = CGFloat(center1)
		let c2 = CGFloat(center2)
		let xf = CGFloat(x)

		let fRect: NSRect
		let sRect: NSRect

		switch rotateMode {
		case 1:
			if readFromLeft {
				fRect = NSRect(x: c1, y: xf, width: h1, height: w1)
				sRect = NSRect(x: c2, y: xf + w1, width: h2, height: w2)
			} else {
				fRect = NSRect(x: c2, y: xf, width: h2, height: w2)
				sRect = NSRect(x: c1, y: xf + w2, width: h1, height: w1)
			}
		case 3:
			if readFromLeft {
				sRect = NSRect(x: c2, y: xf, width: h2, height: w2)
				fRect = NSRect(x: c1, y: xf + w2, width: h1, height: w1)
			} else {
				sRect = NSRect(x: c1, y: xf, width: h1, height: w1)
				fRect = NSRect(x: c2, y: xf + w1, width: h2, height: w2)
			}
		case 2:
			if readFromLeft {
				fRect = NSRect(x: xf, y: c2, width: w2, height: h2)
				sRect = NSRect(x: xf + w2, y: c1, width: w1, height: h1)
			} else {
				sRect = NSRect(x: xf, y: c1, width: w1, height: h1)
				fRect = NSRect(x: xf + w1, y: c2, width: w2, height: h2)
			}
		default:
			if readFromLeft {
				fRect = NSRect(x: xf, y: c1, width: w1, height: h1)
				sRect = NSRect(x: xf + w1, y: c2, width: w2, height: h2)
			} else {
				fRect = NSRect(x: xf, y: c2, width: w2, height: h2)
				sRect = NSRect(x: xf + w2, y: c1, width: w1, height: h1)
			}
		}

		let drawRect1: NSRect
		let drawRect2: NSRect
		if readFromLeft {
			drawRect1 = NSRect(x: xf, y: c1, width: w1, height: h1)
			drawRect2 = NSRect(x: xf + w1, y: c2, width: w2, height: h2)
		} else {
			drawRect1 = NSRect(x: xf + w2, y: c1, width: w1, height: h1)
			drawRect2 = NSRect(x: xf, y: c2, width: w2, height: h2)
		}

		return ViewerSpreadDrawRects(fRect: fRect, sRect: sRect, drawRect1: drawRect1, drawRect2: drawRect2)
	}
}
