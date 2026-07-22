//
//  FakeViewerPageNavigationHost.swift
//  cooViewerTests
//
//  In-memory ViewerPageNavigationHost test double: records the state
//  ViewerPageNavigation's transitions leave behind, and how many times
//  (and in what order relative to state changes) each side-effecting
//  method was called - without touching a real Controller/AppKit stack.
//

import AppKit

final class FakeViewerPageNavigationHost: NSObject, ViewerPageNavigationHost {
	var nowPage: Int32 = 0
	var hasSecondImage: Bool = false
	var pageCount: Int32 = 0

	var buffer: [NSImage] = []
	var bufferedImageCount: Int32 { Int32(buffer.count) }

	/// Simulates what -lookahead would have loaded into the buffer, given
	/// the test's own model of what's on disk around nowPage. A no-op by
	/// default (buffer stays whatever cancelInFlightLoadAndClearBuffer left
	/// it as) - set this when a test needs the post-skip buffer-adjustment
	/// logic to see specific images.
	var lookaheadHandler: () -> Void = {}

	/// -isSmallImage:page: is keyed by page number here rather than image
	/// identity, since the fake's "images" carry no real pixel data.
	var smallPages: Set<Int32> = []

	private(set) var cancelInFlightLoadAndClearBufferCallCount = 0
	private(set) var waitForInFlightLoadCallCount = 0
	private(set) var clearComposedImageCallCount = 0
	private(set) var lookaheadCallCount = 0
	private(set) var imageDisplayCallCount = 0
	private(set) var loadedPages: [Int32] = []

	func cancelInFlightLoadAndClearBuffer() {
		cancelInFlightLoadAndClearBufferCallCount += 1
		buffer.removeAll()
	}

	func waitForInFlightLoad() {
		waitForInFlightLoadCallCount += 1
	}

	func clearComposedImage() {
		clearComposedImageCallCount += 1
	}

	func lookahead() {
		lookaheadCallCount += 1
		lookaheadHandler()
	}

	func imageDisplay() {
		imageDisplayCallCount += 1
	}

	func loadImage(_ page: Int32) -> NSImage? {
		loadedPages.append(page)
		return NSImage()
	}

	func bufferedImage(at index: Int32) -> NSImage? {
		guard index >= 0, Int(index) < buffer.count else {
			return nil
		}
		return buffer[Int(index)]
	}

	func insertImageAtFrontOfBuffer(_ image: NSImage) {
		buffer.insert(image, at: 0)
	}

	func removeFirstImageFromBuffer() {
		buffer.removeFirst()
	}

	func isSmallImage(_ image: NSImage, page: Int32) -> Bool {
		return smallPages.contains(page)
	}
}
