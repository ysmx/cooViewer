//
//  ViewerSpreadInitialFit.swift
//  cooViewer
//
//  Pure geometry helper extracted from CustomImageView's
//  -getDrawImagesInfo:and:. First-pass scaling of each page in a two-page
//  spread to fit inside its screen half: whichever of width-limited or
//  height-limited rate is smaller wins, then maxEnlargement (0 = no cap)
//  clamps it. See #121.
//

import Foundation

@objc final class ViewerSpreadInitialFit: NSObject {

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

	@objc(assignForWidthValue01:heightValue01:widthValue02:heightValue02:screenWidth:screenHeight:maxEnlargement:)
	static func assign(widthValue01: Int32, heightValue01: Int32, widthValue02: Int32, heightValue02: Int32, screenWidth: Float, screenHeight: Float, maxEnlargement: Float) -> ViewerSpreadInitialFit {
		var rate1 = screenWidth / Float(widthValue01)
		var rate2 = screenWidth / Float(widthValue02)
		let sRate1 = screenHeight / Float(heightValue01)
		let sRate2 = screenHeight / Float(heightValue02)

		if rate1 > sRate1 { rate1 = sRate1 }
		if rate2 > sRate2 { rate2 = sRate2 }
		if maxEnlargement != 0 && rate1 > maxEnlargement { rate1 = maxEnlargement }
		if maxEnlargement != 0 && rate2 > maxEnlargement { rate2 = maxEnlargement }

		let widthValue1 = Int32(Float(widthValue01) * rate1)
		let heightValue1 = Int32(Float(heightValue01) * rate1)
		let widthValue2 = Int32(Float(widthValue02) * rate2)
		let heightValue2 = Int32(Float(heightValue02) * rate2)

		return ViewerSpreadInitialFit(widthValue1: widthValue1, heightValue1: heightValue1, widthValue2: widthValue2, heightValue2: heightValue2)
	}
}
