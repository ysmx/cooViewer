//
//  ViewerThumbnailMangaLayout.swift
//  cooViewer
//
//  Pure index/layout arithmetic for -[ThumbnailController loadMangaImage:back:],
//  kept free of any state so the forward/backward parameterization (unified
//  from two mirror-image branches - see that method) can be unit tested
//  directly.
//

import Foundation

@objc final class ViewerThumbnailMangaLayout: NSObject {

	/// The index of the other page to pair with `index` for a spread
	/// preview: the next page going forward, the previous page going back.
	@objc static func pairIndex(index: Int32, back: Bool) -> Int32 {
		return back ? index - 1 : index + 1
	}

	/// The page number -isSmallImage:page: should check the paired image
	/// against, mirroring the same forward/backward offset the real page
	/// viewer uses for spread pairing.
	@objc static func smallCheckPage(index: Int32, back: Bool) -> Int32 {
		return back ? index : index + 2
	}

	/// Whether `index` is already at the end of the book in the direction
	/// of travel, so there's no page left to pair with.
	@objc static func isAtBoundary(index: Int32, back: Bool, count: Int32) -> Bool {
		return back ? (index == 0) : (index == count - 1)
	}

	/// Whether `index`'s own image (as opposed to its paired image) should
	/// render on the left of the composed spread thumbnail.
	@objc static func imageOnLeft(readMode: Int32, back: Bool) -> Bool {
		return (readMode == 1) != back
	}
}
