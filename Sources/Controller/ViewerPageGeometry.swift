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

	/// The page to land on after a forward "skip" by `skipValue` pages,
	/// clamped so the resulting spread never runs past the end of the book.
	/// Mirrors -nextBookmark/-backBookmark's sibling duplicated skip case:
	/// current + (skipValue - 2), pulled back to count - 2 if that would
	/// overrun.
	@objc static func skipTarget(current: Int32, count: Int32, skipValue: Int32) -> Int32 {
		var target = current + (skipValue - 2)
		if target >= count {
			target = count - 2
		}
		return target
	}

	/// The page to land on after a backward "skip" by skipValue pages,
	/// floored at 0.
	@objc static func backskipTarget(current: Int32, skipValue: Int32) -> Int32 {
		let target = current - (skipValue + 2)
		return max(target, 0)
	}

	/// The page corresponding to jumping to a given percentage through the
	/// book, floored at 0.
	@objc static func gotoPercentTarget(count: Int32, percent: Float) -> Int32 {
		let target = Int32(Float(count) * percent)
		return max(target, 0)
	}

	/// Whether the current page is far enough past the start of the book
	/// that "top page" should actually jump (as opposed to already being
	/// there). The threshold is 2 when a second (spread) image is showing,
	/// 1 otherwise - the destination is always page 0.
	@objc static func shouldJumpToTopPage(current: Int32, hasSecondImage: Bool) -> Bool {
		return current > (hasSecondImage ? 2 : 1)
	}

	/// Whether "half next page" should load and prepend one more page to
	/// the buffer (true only in spread mode, and only if there's a next
	/// page left to show).
	@objc static func shouldLoadHalfNextPage(current: Int32, count: Int32, hasSecondImage: Bool) -> Bool {
		return hasSecondImage && current < count
	}
}
