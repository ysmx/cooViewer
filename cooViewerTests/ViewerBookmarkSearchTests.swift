//
//  ViewerBookmarkSearchTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerBookmarkSearchTests: XCTestCase {

	private let pages: [NSNumber] = [30, 10, 50, 20, 40] // deliberately unsorted

	func testNextBookmarkPageFindsTheSmallestPageGreaterThanCurrent() {
		XCTAssertEqual(ViewerBookmarkSearch.nextBookmarkPage(bookmarkPages: pages, currentEffectivePage: 25), 30)
		XCTAssertEqual(ViewerBookmarkSearch.nextBookmarkPage(bookmarkPages: pages, currentEffectivePage: 10), 20)
	}

	func testNextBookmarkPageReturnsNilWhenAlreadyAtOrPastTheLastBookmark() {
		XCTAssertNil(ViewerBookmarkSearch.nextBookmarkPage(bookmarkPages: pages, currentEffectivePage: 50))
		XCTAssertNil(ViewerBookmarkSearch.nextBookmarkPage(bookmarkPages: pages, currentEffectivePage: 60))
	}

	func testPreviousBookmarkPageFindsTheLargestPageLessThanCurrent() {
		XCTAssertEqual(ViewerBookmarkSearch.previousBookmarkPage(bookmarkPages: pages, currentEffectivePage: 35), 30)
		XCTAssertEqual(ViewerBookmarkSearch.previousBookmarkPage(bookmarkPages: pages, currentEffectivePage: 50), 40)
	}

	func testPreviousBookmarkPageReturnsNilWhenAlreadyAtOrBeforeTheFirstBookmark() {
		XCTAssertNil(ViewerBookmarkSearch.previousBookmarkPage(bookmarkPages: pages, currentEffectivePage: 10))
		XCTAssertNil(ViewerBookmarkSearch.previousBookmarkPage(bookmarkPages: pages, currentEffectivePage: 5))
	}

	func testEmptyBookmarkListReturnsNilForBothDirections() {
		XCTAssertNil(ViewerBookmarkSearch.nextBookmarkPage(bookmarkPages: [], currentEffectivePage: 0))
		XCTAssertNil(ViewerBookmarkSearch.previousBookmarkPage(bookmarkPages: [], currentEffectivePage: 0))
	}
}
