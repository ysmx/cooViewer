//
//  NSBezierPath_Adding.swift
//  cooViewer
//
//  Rounded-rect bezier path builders used for the page bar pill background,
//  thumbnail selection highlight, and loupe/page-mover outlines.
//

import Cocoa

extension NSBezierPath {

	/// A capsule (fully-rounded on both short ends) path for `rect`.
	@objc(bezierPathWithRectWithDoubleArc:)
	static func co_bezierPathWithRectWithDoubleArc(_ rect: NSRect) -> NSBezierPath {
		let rad = CGFloat(Int(rect.size.height / 2 + 0.5))
		let bezier = NSBezierPath()

		bezier.appendArc(withCenter: NSPoint(x: rect.origin.x + rad, y: rect.origin.y + rad),
						  radius: rad, startAngle: 90, endAngle: 270)
		bezier.appendArc(withCenter: NSPoint(x: rect.origin.x + rect.size.width - rad, y: rect.origin.y + rad),
						  radius: rad, startAngle: 270, endAngle: 90)
		bezier.lineWidth = 1.5
		return bezier
	}

	/// A rounded-rect path for `rect` with radius `rad`, rounding only 3 of
	/// the 4 corners depending on `open` (0-3 select which corner is left
	/// square) - used to blend a highlight into an adjacent, unrounded edge.
	@objc(bezierPathWithRectWithArc:rad:open:)
	static func co_bezierPathWithRectWithArc(_ rect: NSRect, rad: Int32, open: Int32) -> NSBezierPath {
		let bezier = NSBezierPath()
		let r = CGFloat(rad)

		let ld = rect.origin
		let lu = NSPoint(x: ld.x, y: ld.y + rect.size.height)
		let ru = NSPoint(x: lu.x + rect.size.width, y: lu.y)
		let rd = NSPoint(x: ru.x, y: ru.y - rect.size.height)

		func arcTopRight() { bezier.appendArc(withCenter: NSPoint(x: ru.x - r, y: ru.y - r), radius: r, startAngle: 0, endAngle: 90) }
		func arcTopLeft() { bezier.appendArc(withCenter: NSPoint(x: lu.x + r, y: lu.y - r), radius: r, startAngle: 90, endAngle: 180) }
		func arcBottomLeft() { bezier.appendArc(withCenter: NSPoint(x: ld.x + r, y: ld.y + r), radius: r, startAngle: 180, endAngle: 270) }
		func arcBottomRight() { bezier.appendArc(withCenter: NSPoint(x: rd.x - r, y: rd.y + r), radius: r, startAngle: 270, endAngle: 0) }

		switch open {
		case 0:
			arcTopRight(); arcTopLeft(); arcBottomLeft(); arcBottomRight()
		case 1:
			arcTopLeft(); arcBottomLeft(); arcBottomRight(); arcTopRight()
		case 2:
			arcBottomLeft(); arcBottomRight(); arcTopRight(); arcTopLeft()
		case 3:
			arcBottomRight(); arcTopRight(); arcTopLeft(); arcBottomLeft()
		default:
			break
		}
		bezier.lineWidth = 1.5
		return bezier
	}
}
