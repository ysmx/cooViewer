//
//  ViewerMouseBinding.swift
//  cooViewer
//
//  Decodes the packed mouse-binding modifier value stored in the
//  MouseArray defaults: hundreds encode the click-type popup index
//  (100 per step, >=1000 pinned to index 10) and the remainder is a
//  modifier bitmask (1=shift, 2=option, 4=control). Extracted from the
//  if/else-if ladder + switch that -[PreferenceController
//  tableView:shouldEditTableColumn:row:]'s mouse branch inlined, so the
//  mapping is unit testable. A remainder outside 0-7 sets no modifiers,
//  matching the original switch's default case.
//

import Foundation

@objc final class ViewerMouseBinding: NSObject {

	@objc let clickIndex: Int32
	@objc let shift: Bool
	@objc let option: Bool
	@objc let control: Bool

	private init(clickIndex: Int32, shift: Bool, option: Bool, control: Bool) {
		self.clickIndex = clickIndex
		self.shift = shift
		self.option = option
		self.control = control
		super.init()
	}

	@objc(decodeModifier:)
	static func decode(modifier cMod: Int32) -> ViewerMouseBinding {
		let clickIndex: Int32
		let remainder: Int32
		if cMod >= 1000 {
			clickIndex = 10
			remainder = cMod - 1000
		} else if cMod >= 100 {
			clickIndex = cMod / 100
			remainder = cMod - clickIndex * 100
		} else {
			clickIndex = 0
			remainder = cMod
		}
		let recognized = (0...7).contains(remainder)
		return ViewerMouseBinding(clickIndex: clickIndex,
								  shift: recognized && (remainder & 1) != 0,
								  option: recognized && (remainder & 2) != 0,
								  control: recognized && (remainder & 4) != 0)
	}
}
