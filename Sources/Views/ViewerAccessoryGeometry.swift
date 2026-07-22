//
//  ViewerAccessoryGeometry.swift
//  cooViewer
//
//  Pure layout/geometry helpers used by AccessoryView/AccessorySettingView,
//  kept free of any view-hierarchy state so they can be unit tested
//  directly. Swift port of the former AccessoryGeometry.h/.m.
//
//  Placement is passed around as a plain Int32 (matching the original's
//  raw int, and AccessoryView/AccessorySettingView's own pageBarPosition/
//  pageStringPosition ivars) rather than a Swift enum, since some call
//  sites switch on it with plain integer case labels.
//

import AppKit

@objc final class ViewerAccessoryGeometry: NSObject {

	@objc static let placementTopLeft: Int32 = 0
	@objc static let placementTopRight: Int32 = 1
	@objc static let placementBottomLeft: Int32 = 2
	@objc static let placementBottomRight: Int32 = 3
	@objc static let placementTopCenter: Int32 = 4
	@objc static let placementBottomCenter: Int32 = 5

	@objc static func intRect(_ aRect: NSRect) -> NSRect {
		var rect = aRect
		rect.origin.x = CGFloat(Int32(rect.origin.x + 0.5))
		rect.origin.y = CGFloat(Int32(rect.origin.y + 0.5))
		rect.size.width = CGFloat(Int32(rect.size.width + 0.5))
		rect.size.height = CGFloat(Int32(rect.size.height + 0.5))
		return rect
	}

	@objc static func placementIsTop(_ placement: Int32) -> Bool {
		return placement == placementTopLeft || placement == placementTopRight || placement == placementTopCenter
	}

	@objc static func placementIsRight(_ placement: Int32) -> Bool {
		return placement == placementTopRight || placement == placementBottomRight
	}

	@objc static func placementIsCenter(_ placement: Int32) -> Bool {
		return placement == placementTopCenter || placement == placementBottomCenter
	}

	@objc static func pageBarLayoutRect(contentFrame: NSRect, margin: NSPoint, widthValue: CGFloat, heightValue: CGFloat, position: Int32) -> NSRect {
		let width = widthValue + 1
		let height = heightValue + 1
		var rect: NSRect
		switch position {
		case placementTopLeft:
			rect = NSRect(x: contentFrame.origin.x + margin.x + 2,
						  y: contentFrame.size.height - height - margin.y - 3,
						  width: width, height: height)
		case placementTopRight:
			rect = NSRect(x: contentFrame.origin.x + contentFrame.size.width - width - margin.x - 3,
						  y: contentFrame.origin.y - height + contentFrame.size.height - margin.y - 3,
						  width: width, height: height)
		case placementBottomLeft:
			rect = NSRect(x: contentFrame.origin.x + margin.x + 2,
						  y: contentFrame.origin.y + margin.y + 2,
						  width: width, height: height)
		case placementBottomRight:
			rect = NSRect(x: contentFrame.origin.x + contentFrame.size.width - width - margin.x - 3,
						  y: contentFrame.origin.y + margin.y + 2,
						  width: width, height: height)
		case placementTopCenter:
			rect = NSRect(x: contentFrame.origin.x + (contentFrame.size.width - width) / 2,
						  y: contentFrame.size.height - height - margin.y - 3,
						  width: width, height: height)
		case placementBottomCenter:
			rect = NSRect(x: contentFrame.origin.x + (contentFrame.size.width - width) / 2,
						  y: contentFrame.origin.y + margin.y + 2,
						  width: width, height: height)
		default:
			rect = NSRect(x: 0, y: 0, width: width, height: height)
		}
		return intRect(rect)
	}

	@objc static func pageStringLayoutRect(contentFrame: NSRect, string: NSAttributedString?, margin: NSPoint, position: Int32) -> NSRect {
		let pageStringSize = pageStringSizeWithBG(string)
		var rect = NSRect(x: 0, y: 0, width: pageStringSize.width + 1, height: pageStringSize.height + 1)
		switch position {
		case placementTopLeft:
			rect.origin.x = margin.x + 2
			rect.origin.y = contentFrame.size.height - rect.size.height - margin.y
		case placementTopRight:
			rect.origin.x = contentFrame.size.width - rect.size.width - margin.x - 2
			rect.origin.y = contentFrame.size.height - rect.size.height - margin.y
		case placementBottomLeft:
			rect.origin.x = margin.x + 2
			rect.origin.y = 17 + margin.y + 2
		case placementBottomRight:
			rect.origin.x = contentFrame.size.width - rect.size.width - margin.x - 2
			rect.origin.y = 17 + margin.y + 2
		case placementTopCenter:
			rect.origin.x = (contentFrame.size.width - rect.size.width) / 2
			rect.origin.y = contentFrame.size.height - rect.size.height - margin.y
		case placementBottomCenter:
			rect.origin.x = (contentFrame.size.width - rect.size.width) / 2
			rect.origin.y = 17 + margin.y + 2
		default:
			break
		}
		return intRect(rect)
	}

	@objc static let pageStringTextLeftOffset: CGFloat = 9.0

	@objc static func drawPageString(_ string: NSAttributedString?, atPoint point: NSPoint, background: NSColor?, border: NSColor?) {
		guard let string = string else {
			return
		}
		let totalSize = pageStringSizeWithBG(string)
		let backgroundRect = NSRect(x: point.x + 1, y: point.y + 1, width: totalSize.width - 2, height: totalSize.height - 2)
		let stringRect = backgroundRect.insetBy(dx: pageStringTextLeftOffset - 1.0, dy: 4)
		let drawBG = colorShouldDraw(background)
		let drawBorder = colorShouldDraw(border)

		if drawBG || drawBorder {
			let bezier = NSBezierPath(roundedRect: backgroundRect, xRadius: 6.0, yRadius: 6.0)
			if drawBG {
				background?.set()
				bezier.fill()
			}
			if drawBorder {
				border?.set()
				bezier.stroke()
			}
		}
		string.draw(in: stringRect)
	}

	private static func pageStringDrawingSize(_ string: NSAttributedString?) -> NSSize {
		guard let string = string else {
			return .zero
		}
		let rect = string.boundingRect(with: NSSize(width: 100000.0, height: 100000.0),
										options: [.usesLineFragmentOrigin, .usesFontLeading])
		return NSSize(width: ceil(rect.size.width), height: ceil(rect.size.height))
	}

	private static func pageStringSizeWithBG(_ string: NSAttributedString?) -> NSSize {
		let drawingSize = pageStringDrawingSize(string)
		return NSSize(width: drawingSize.width + 18, height: drawingSize.height + 10)
	}

	private static func colorShouldDraw(_ color: NSColor?) -> Bool {
		guard let color = color, !color.isEqual(NSColor.clear) else {
			return false
		}
		return color.alphaComponent > 0.0
	}
}
