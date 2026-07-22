//
//  ViewerPageNavigation.swift
//  cooViewer
//
//  Drives the half-next/top-page/skip/backskip/goto% page transitions
//  (previously duplicated across the key and mouse action switches) through
//  ViewerPageNavigationHost, so the full transition - including buffer
//  adjustment and call ordering - is exercised by ViewerPageNavigationTests
//  via FakeViewerPageNavigationHost, not just the pure arithmetic in
//  ViewerPageGeometry.
//

import Foundation

@objc final class ViewerPageNavigation: NSObject {

	@objc static func performHalfNext(host: ViewerPageNavigationHost) {
		host.waitForInFlightLoad()
		if ViewerPageGeometry.shouldLoadHalfNextPage(current: host.nowPage, count: host.pageCount, hasSecondImage: host.hasSecondImage) {
			host.nowPage -= 1
			host.waitForInFlightLoad()
			if let image = host.loadImage(host.nowPage) {
				host.insertImageAtFrontOfBuffer(image)
			}
		}
		host.imageDisplay()
	}

	@objc static func performTopPage(host: ViewerPageNavigationHost) {
		guard ViewerPageGeometry.shouldJumpToTopPage(current: host.nowPage, hasSecondImage: host.hasSecondImage) else {
			return
		}
		host.cancelInFlightLoadAndClearBuffer()
		host.nowPage = 0
		host.lookahead()
		host.imageDisplay()
	}

	@objc static func performSkip(host: ViewerPageNavigationHost, value: Int32) {
		host.cancelInFlightLoadAndClearBuffer()
		host.nowPage = ViewerPageGeometry.skipTarget(current: host.nowPage, count: host.pageCount, skipValue: value)
		host.lookahead()
		adjustBufferAfterSkip(host: host)
		host.imageDisplay()
	}

	@objc static func performBackskip(host: ViewerPageNavigationHost, value: Int32) {
		host.cancelInFlightLoadAndClearBuffer()
		host.nowPage = ViewerPageGeometry.backskipTarget(current: host.nowPage, skipValue: value)
		host.lookahead()
		host.imageDisplay()
	}

	@objc static func performGotoPercent(host: ViewerPageNavigationHost, percent: Float) {
		host.cancelInFlightLoadAndClearBuffer()
		host.nowPage = ViewerPageGeometry.gotoPercentTarget(count: host.pageCount, percent: percent)
		host.clearComposedImage()
		host.lookahead()
		host.imageDisplay()
	}

	// -nextBookmark/-backBookmark already wait on the lock themselves before
	// calling this (see their [lock lock]/[lock unlock] in the key/mouse
	// switches), so unlike the transitions above, this never cancels an
	// in-flight load - it only clears the buffer.
	@objc static func performBookmarkJump(host: ViewerPageNavigationHost, page: Int32, title: String?) {
		host.nowPage = page - 1
		host.clearBuffer()
		host.lookahead()
		host.imageDisplay()
		host.setInfoString(title)
	}

	// After a skip lands, -lookahead may have buffered a page that's too
	// small to stand alone in spread mode; if so, drop it and advance by
	// one so the spread re-pairs correctly. Only skip does this (not
	// backskip) - matches the original's asymmetry.
	private static func adjustBufferAfterSkip(host: ViewerPageNavigationHost) {
		guard host.bufferedImageCount > 1, let first = host.bufferedImage(at: 0) else {
			return
		}
		if !host.isSmallImage(first, page: host.nowPage + 1) {
			host.removeFirstImageFromBuffer()
			host.nowPage += 1
		} else if let second = host.bufferedImage(at: 1), !host.isSmallImage(second, page: host.nowPage + 2) {
			host.removeFirstImageFromBuffer()
			host.nowPage += 1
		}
	}
}
