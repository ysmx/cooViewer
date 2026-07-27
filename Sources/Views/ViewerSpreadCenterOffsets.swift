//
//  ViewerSpreadCenterOffsets.swift
//  cooViewer
//
//  Pure geometry helper extracted from CustomImageView's
//  -getDrawImagesInfo:and:. Given the fullscreen rect's size and the
//  already-scaled width/height of each page in a two-page spread,
//  computes the vertical centering offset for each page (clamped to 0
//  when the page is taller than the screen) and the horizontal offset
//  for the pair as a whole. Independent of fitScreenMode and rotateMode.
//  See #116.
//

import Foundation

@objc final class ViewerSpreadCenterOffsets: NSObject {

	@objc let center1: Int32
	@objc let center2: Int32
	@objc let x: Int32

	private init(center1: Int32, center2: Int32, x: Int32) {
		self.center1 = center1
		self.center2 = center2
		self.x = x
	}

	@objc(assignForFullscreenWidth:height:widthValue1:heightValue1:widthValue2:heightValue2:)
	static func assign(fullscreenWidth: Int32, fullscreenHeight: Int32, widthValue1: Int32, heightValue1: Int32, widthValue2: Int32, heightValue2: Int32) -> ViewerSpreadCenterOffsets {
		let rawCenter1 = fullscreenHeight - heightValue1
		let rawCenter2 = fullscreenHeight - heightValue2
		let center1 = rawCenter1 >= 0 ? rawCenter1 / 2 : 0
		let center2 = rawCenter2 >= 0 ? rawCenter2 / 2 : 0
		let x = (fullscreenWidth - widthValue1 - widthValue2) / 2
		return ViewerSpreadCenterOffsets(center1: center1, center2: center2, x: x)
	}
}
