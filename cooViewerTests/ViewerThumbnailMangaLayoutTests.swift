//
//  ViewerThumbnailMangaLayoutTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerThumbnailMangaLayoutTests: XCTestCase {

	func testPairIndexGoesForwardOrBackward() {
		XCTAssertEqual(ViewerThumbnailMangaLayout.pairIndex(index: 5, back: false), 6)
		XCTAssertEqual(ViewerThumbnailMangaLayout.pairIndex(index: 5, back: true), 4)
	}

	func testSmallCheckPageMirrorsThePairingOffset() {
		XCTAssertEqual(ViewerThumbnailMangaLayout.smallCheckPage(index: 5, back: false), 7)
		XCTAssertEqual(ViewerThumbnailMangaLayout.smallCheckPage(index: 5, back: true), 5)
	}

	func testIsAtBoundaryForward() {
		XCTAssertTrue(ViewerThumbnailMangaLayout.isAtBoundary(index: 9, back: false, count: 10))
		XCTAssertFalse(ViewerThumbnailMangaLayout.isAtBoundary(index: 8, back: false, count: 10))
	}

	func testIsAtBoundaryBackward() {
		XCTAssertTrue(ViewerThumbnailMangaLayout.isAtBoundary(index: 0, back: true, count: 10))
		XCTAssertFalse(ViewerThumbnailMangaLayout.isAtBoundary(index: 1, back: true, count: 10))
	}

	// The four (back, readMode) combinations -loadMangaImage:back:'s two
	// original mirror-image branches covered.
	func testImageOnLeftForAllFourCombinations() {
		XCTAssertTrue(ViewerThumbnailMangaLayout.imageOnLeft(readMode: 1, back: false))
		XCTAssertFalse(ViewerThumbnailMangaLayout.imageOnLeft(readMode: 0, back: false))
		XCTAssertFalse(ViewerThumbnailMangaLayout.imageOnLeft(readMode: 1, back: true))
		XCTAssertTrue(ViewerThumbnailMangaLayout.imageOnLeft(readMode: 0, back: true))
	}
}
