//
//  NSAttributedString_Adding.swift
//  cooViewer
//
//  Draws an attributed string with an optional pill-shaped background/border
//  behind it (used for the page-number/info-toast overlays), and computes
//  the total size including that padding.
//

import Cocoa

extension NSAttributedString {

	@objc(drawInRect:bg:border:)
	func co_draw(inRect rect: NSRect, bg: NSColor?, border: NSColor?) {
		guard bg != nil || border != nil else {
			draw(in: rect)
			return
		}
		var temp = rect.origin
		temp.x += 1
		temp.y += 1
		let rad = CGFloat(Int(size().height / 2))
		let tempRect = NSRect(x: temp.x, y: temp.y, width: rad + size().width + rad, height: size().height + 1)

		let bezier = NSBezierPath.co_bezierPathWithRectWithDoubleArc(tempRect)
		bezier.close()
		if let bg {
			bg.set()
			bezier.fill()
		}
		if let border {
			border.set()
			bezier.stroke()
		}
		let tempPt = NSPoint(x: temp.x + rad, y: temp.y + 1)
		draw(at: tempPt)
	}

	@objc(drawInRect:bg:)
	func co_draw(inRect rect: NSRect, bg: NSColor?) {
		co_draw(inRect: rect, bg: bg, border: nil)
	}

	@objc(drawAtPoint:bg:border:)
	func co_draw(atPoint pt: NSPoint, bg: NSColor?, border: NSColor?) {
		guard bg != nil || border != nil else {
			draw(at: pt)
			return
		}
		var temp = pt
		temp.x += 1
		temp.y += 1
		let rad = CGFloat(Int(size().height / 2))
		let tempRect = NSRect(x: temp.x, y: temp.y, width: rad + size().width + rad, height: size().height + 1)

		let bezier = NSBezierPath.co_bezierPathWithRectWithDoubleArc(tempRect)
		bezier.close()
		if let bg {
			bg.set()
			bezier.fill()
		}
		if let border {
			border.set()
			bezier.stroke()
		}
		let tempPt = NSPoint(x: temp.x + rad, y: temp.y + 1)
		draw(at: tempPt)
	}

	@objc(drawAtPoint:bg:)
	func co_draw(atPoint pt: NSPoint, bg: NSColor?) {
		co_draw(atPoint: pt, bg: bg, border: nil)
	}

	@objc(sizeWithBG)
	func co_sizeWithBG() -> NSSize {
		let rad = CGFloat(Int(size().height / 2))
		return NSSize(width: rad + size().width + rad + 2, height: size().height + 4)
	}
}
