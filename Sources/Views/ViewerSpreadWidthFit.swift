//
//  ViewerSpreadWidthFit.swift
//  cooViewer
//
//  Pure geometry helper extracted from CustomImageView's
//  -getDrawImagesInfo:and:. Applies the fitScreenMode==1 ("fit to screen
//  width") and fitScreenMode==3 ("fit to screen width, divided") final
//  scaling pass for the 0/180-rotation case. Those two branches were
//  nearly byte-identical -- the only differences were the rate's extra
//  "/2" divisor and the frameSize width's "*2" multiplier for divide
//  mode -- so both are now driven by one isDivideMode flag instead of
//  being two separate copies. See #121.
//

import AppKit

@objc final class ViewerSpreadWidthFit: NSObject {

	@objc let widthValue1: Int32
	@objc let heightValue1: Int32
	@objc let widthValue2: Int32
	@objc let heightValue2: Int32
	@objc let frameSize: NSSize

	private init(widthValue1: Int32, heightValue1: Int32, widthValue2: Int32, heightValue2: Int32, frameSize: NSSize) {
		self.widthValue1 = widthValue1
		self.heightValue1 = heightValue1
		self.widthValue2 = widthValue2
		self.heightValue2 = heightValue2
		self.frameSize = frameSize
	}

	@objc(assignForWidthValue01:heightValue01:widthValue02:heightValue02:currentWidthValue1:currentHeightValue1:currentWidthValue2:currentHeightValue2:fullscreenWidth:fullscreenHeight:screenHeight:maxEnlargement:isDivideMode:)
	static func assign(widthValue01: Int32, heightValue01: Int32, widthValue02: Int32, heightValue02: Int32,
						currentWidthValue1: Int32, currentHeightValue1: Int32, currentWidthValue2: Int32, currentHeightValue2: Int32,
						fullscreenWidth: Float, fullscreenHeight: Float, screenHeight: Float, maxEnlargement: Float, isDivideMode: Bool) -> ViewerSpreadWidthFit {
		let widthSum = currentWidthValue1 + currentWidthValue2
		// isDivideMode truncates the sum to an int *before* dividing into
		// fullscreenWidth, same as the original's integer "/2".
		let denominator: Float = isDivideMode ? Float(widthSum / 2) : Float(widthSum)
		let rates = fullscreenWidth / denominator

		var widthValue1 = Int32(Float(currentWidthValue1) * rates)
		var heightValue1 = Int32(Float(currentHeightValue1) * rates)
		var widthValue2 = Int32(Float(currentWidthValue2) * rates)
		var heightValue2 = Int32(Float(currentHeightValue2) * rates)

		if maxEnlargement != 0 {
			if Float(widthValue1) > Float(widthValue01) * maxEnlargement {
				widthValue1 = widthValue01
				heightValue1 = heightValue01
			}
			if Float(heightValue1) > Float(heightValue01) * maxEnlargement {
				widthValue1 = widthValue01
				heightValue1 = heightValue01
			}
			if Float(widthValue2) > Float(widthValue02) * maxEnlargement {
				widthValue2 = widthValue02
				heightValue2 = heightValue02
			}
			if Float(heightValue2) > Float(heightValue02) * maxEnlargement {
				widthValue2 = widthValue02
				heightValue2 = heightValue02
			}
		}

		let highest = max(heightValue1, heightValue2)
		let truncatedWidth = Int32(fullscreenWidth)
		let frameWidth = isDivideMode ? truncatedWidth * 2 : truncatedWidth
		let frameSize: NSSize
		if Float(highest) < screenHeight {
			frameSize = NSSize(width: CGFloat(frameWidth), height: CGFloat(Int32(fullscreenHeight)))
		} else {
			frameSize = NSSize(width: CGFloat(frameWidth), height: CGFloat(highest))
		}

		return ViewerSpreadWidthFit(widthValue1: widthValue1, heightValue1: heightValue1, widthValue2: widthValue2, heightValue2: heightValue2, frameSize: frameSize)
	}
}
