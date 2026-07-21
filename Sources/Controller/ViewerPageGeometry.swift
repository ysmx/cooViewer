//
//  ViewerPageGeometry.swift
//  cooViewer
//
//  Pure page-index arithmetic for the two-page spread view, kept free of
//  any AppKit/Controller state so it can be unit tested directly.
//

import Foundation

@objc final class ViewerPageGeometry: NSObject {

	/// Which on-disk page index is currently shown at a given physical
	/// screen side (left/right), given the current reading direction.
	///
	/// `firstImagePageIndex`/`secondImagePageIndex` are the page indices of
	/// the two halves of a spread (or the same single index in single-page
	/// mode) - see `-[Controller co_firstImagePageIndex]` and
	/// `-[Controller co_secondImagePageIndex]`, which mirror the exact
	/// arithmetic `-imageDisplay`/`-returnComposeImage:and:` use to lay the
	/// two images out on screen.
	///
	/// When `readFromLeft` is true, the first image renders on the physical
	/// left and the second on the physical right; when false (right-to-left
	/// / manga reading order), they're swapped - see
	/// `-[Controller returnComposeImage:and:]`.
	@objc static func trashIndex(
		isLeft: Bool,
		readFromLeft: Bool,
		firstImagePageIndex: Int32,
		secondImagePageIndex: Int32
	) -> Int32 {
		let leftIndex = readFromLeft ? firstImagePageIndex : secondImagePageIndex
		let rightIndex = readFromLeft ? secondImagePageIndex : firstImagePageIndex
		return isLeft ? leftIndex : rightIndex
	}
}
