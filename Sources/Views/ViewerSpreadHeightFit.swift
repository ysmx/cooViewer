//
//  ViewerSpreadHeightFit.swift
//  cooViewer
//
//  Pure geometry helper extracted from CustomImageView's
//  -getDrawImagesInfo:and:. Re-fits each page to exactly the screen's
//  height (only if it doesn't already match), then, if the pages'
//  combined width still overflows the fullscreen rect, shrinks both
//  proportionally so they fit. This exact block used to be duplicated
//  verbatim between the 90/270-rotation fitScreenMode==0 branch and the
//  0/180-rotation base case; both now share this one implementation.
//  See #121.
//

import Foundation

@objc final class ViewerSpreadHeightFit: NSObject {

	@objc let widthValue1: Int32
	@objc let heightValue1: Int32
	@objc let widthValue2: Int32
	@objc let heightValue2: Int32

	private init(widthValue1: Int32, heightValue1: Int32, widthValue2: Int32, heightValue2: Int32) {
		self.widthValue1 = widthValue1
		self.heightValue1 = heightValue1
		self.widthValue2 = widthValue2
		self.heightValue2 = heightValue2
	}

	@objc(assignForWidthValue01:heightValue01:widthValue02:heightValue02:currentWidthValue1:currentHeightValue1:currentWidthValue2:currentHeightValue2:screenHeight:maxEnlargement:fullscreenWidth:)
	static func assign(widthValue01: Int32, heightValue01: Int32, widthValue02: Int32, heightValue02: Int32,
						currentWidthValue1: Int32, currentHeightValue1: Int32, currentWidthValue2: Int32, currentHeightValue2: Int32,
						screenHeight: Float, maxEnlargement: Float, fullscreenWidth: Float) -> ViewerSpreadHeightFit {
		var widthValue1 = currentWidthValue1
		var heightValue1 = currentHeightValue1
		var widthValue2 = currentWidthValue2
		var heightValue2 = currentHeightValue2

		if Float(heightValue1) != screenHeight {
			var rate1 = screenHeight / Float(heightValue01)
			if maxEnlargement != 0 && rate1 > maxEnlargement { rate1 = maxEnlargement }
			widthValue1 = Int32(Float(widthValue01) * rate1)
			heightValue1 = Int32(Float(heightValue01) * rate1)
		}
		if Float(heightValue2) != screenHeight {
			var rate2 = screenHeight / Float(heightValue02)
			if maxEnlargement != 0 && rate2 > maxEnlargement { rate2 = maxEnlargement }
			widthValue2 = Int32(Float(widthValue02) * rate2)
			heightValue2 = Int32(Float(heightValue02) * rate2)
		}
		if Float(widthValue1 + widthValue2) > fullscreenWidth {
			let rates = fullscreenWidth / Float(widthValue1 + widthValue2)
			widthValue1 = Int32(Float(widthValue1) * rates)
			heightValue1 = Int32(Float(heightValue1) * rates)
			widthValue2 = Int32(Float(widthValue2) * rates)
			heightValue2 = Int32(Float(heightValue2) * rates)
		}

		return ViewerSpreadHeightFit(widthValue1: widthValue1, heightValue1: heightValue1, widthValue2: widthValue2, heightValue2: heightValue2)
	}
}
