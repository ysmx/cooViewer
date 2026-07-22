//
//  ViewerPageNavigationHost.swift
//  cooViewer
//
//  The slice of Controller's page-navigation state and side effects that
//  half-next/top-page/skip/backskip/goto% need, exposed as a protocol so
//  those transitions can be driven and unit tested (via
//  FakeViewerPageNavigationHost) without a real Controller/AppKit stack.
//  See -[Controller(ViewerPageNavigationHost) ...] in Controller_input.m
//  for Controller's conformance.
//

import AppKit

@objc protocol ViewerPageNavigationHost: AnyObject {
	var nowPage: Int32 { get set }
	var hasSecondImage: Bool { get }
	var pageCount: Int32 { get }
	var bufferedImageCount: Int32 { get }

	/// threadStop=YES; lock/unlock to let any in-flight background load
	/// finish; threadStop=NO; then discard the current image buffer.
	func cancelInFlightLoadAndClearBuffer()

	/// lock/unlock only, with no threadStop/buffer-clear - waits for an
	/// in-flight background load without cancelling it.
	func waitForInFlightLoad()

	func clearComposedImage()
	func lookahead()
	func imageDisplay()

	@objc(loadImage:)
	func loadImage(_ page: Int32) -> NSImage?

	@objc(bufferedImageAtIndex:)
	func bufferedImage(at index: Int32) -> NSImage?

	@objc(insertImageAtFrontOfBuffer:)
	func insertImageAtFrontOfBuffer(_ image: NSImage)

	func removeFirstImageFromBuffer()

	@objc(isSmallImage:page:)
	func isSmallImage(_ image: NSImage, page: Int32) -> Bool
}
