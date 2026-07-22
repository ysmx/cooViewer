//
//  ViewerPageNavigationTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerPageNavigationTests: XCTestCase {

	// MARK: - performHalfNext

	func testHalfNextLoadsAndPrependsThePreviousPageWhenSpreadHasRoom() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 5
		host.pageCount = 10
		host.hasSecondImage = true

		ViewerPageNavigation.performHalfNext(host: host)

		XCTAssertEqual(host.nowPage, 4)
		XCTAssertEqual(host.loadedPages, [4])
		XCTAssertEqual(host.buffer.count, 1)
		XCTAssertEqual(host.waitForInFlightLoadCallCount, 2)
		XCTAssertEqual(host.imageDisplayCallCount, 1)
	}

	func testHalfNextDoesNothingButRedrawWithoutASecondImage() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 5
		host.pageCount = 10
		host.hasSecondImage = false

		ViewerPageNavigation.performHalfNext(host: host)

		XCTAssertEqual(host.nowPage, 5)
		XCTAssertTrue(host.loadedPages.isEmpty)
		XCTAssertEqual(host.waitForInFlightLoadCallCount, 1)
		XCTAssertEqual(host.imageDisplayCallCount, 1)
	}

	func testHalfNextDoesNothingButRedrawAtTheEndOfTheBook() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 10
		host.pageCount = 10
		host.hasSecondImage = true

		ViewerPageNavigation.performHalfNext(host: host)

		XCTAssertEqual(host.nowPage, 10)
		XCTAssertTrue(host.loadedPages.isEmpty)
		XCTAssertEqual(host.imageDisplayCallCount, 1)
	}

	// MARK: - performTopPage

	func testTopPageJumpsToZeroWhenPastTheThreshold() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 5
		host.hasSecondImage = true

		ViewerPageNavigation.performTopPage(host: host)

		XCTAssertEqual(host.nowPage, 0)
		XCTAssertEqual(host.cancelInFlightLoadAndClearBufferCallCount, 1)
		XCTAssertEqual(host.lookaheadCallCount, 1)
		XCTAssertEqual(host.imageDisplayCallCount, 1)
	}

	func testTopPageDoesNothingAtAllWhenAlreadyAtOrBelowTheThreshold() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 2
		host.hasSecondImage = true

		ViewerPageNavigation.performTopPage(host: host)

		XCTAssertEqual(host.nowPage, 2)
		XCTAssertEqual(host.cancelInFlightLoadAndClearBufferCallCount, 0)
		XCTAssertEqual(host.lookaheadCallCount, 0)
		XCTAssertEqual(host.imageDisplayCallCount, 0)
	}

	// MARK: - performSkip

	func testSkipAdvancesAndRunsTheFullTransitionWhenBufferIsTooShortToAdjust() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 10
		host.pageCount = 100

		ViewerPageNavigation.performSkip(host: host, value: 5)

		XCTAssertEqual(host.nowPage, 13)
		XCTAssertEqual(host.cancelInFlightLoadAndClearBufferCallCount, 1)
		XCTAssertEqual(host.lookaheadCallCount, 1)
		XCTAssertEqual(host.imageDisplayCallCount, 1)
	}

	func testSkipDropsTheFirstBufferedPageWhenItIsNotSmall() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 10
		host.pageCount = 100
		host.lookaheadHandler = { [weak host] in
			host?.buffer = [NSImage(), NSImage()]
		}
		// page 13+1=14 is not small -> dropped, nowPage advances to 14.

		ViewerPageNavigation.performSkip(host: host, value: 5)

		XCTAssertEqual(host.nowPage, 14)
		XCTAssertEqual(host.buffer.count, 1)
	}

	func testSkipDropsTheFirstBufferedPageWhenTheSecondIsNotSmall() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 10
		host.pageCount = 100
		host.smallPages = [14]
		host.lookaheadHandler = { [weak host] in
			host?.buffer = [NSImage(), NSImage()]
		}
		// page 14 (first+1) is small, page 15 (first+2) is not -> still drops.

		ViewerPageNavigation.performSkip(host: host, value: 5)

		XCTAssertEqual(host.nowPage, 14)
		XCTAssertEqual(host.buffer.count, 1)
	}

	func testSkipLeavesTheBufferAloneWhenBothCandidatePagesAreSmall() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 10
		host.pageCount = 100
		host.smallPages = [14, 15]
		host.lookaheadHandler = { [weak host] in
			host?.buffer = [NSImage(), NSImage()]
		}

		ViewerPageNavigation.performSkip(host: host, value: 5)

		XCTAssertEqual(host.nowPage, 13)
		XCTAssertEqual(host.buffer.count, 2)
	}

	func testSkipClampsToNearTheEndOfTheBook() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 90
		host.pageCount = 100

		ViewerPageNavigation.performSkip(host: host, value: 20)

		XCTAssertEqual(host.nowPage, 98)
	}

	// MARK: - performBackskip

	func testBackskipRetreatsAndNeverAdjustsTheBuffer() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 10
		host.lookaheadHandler = { [weak host] in
			host?.buffer = [NSImage(), NSImage()]
		}

		ViewerPageNavigation.performBackskip(host: host, value: 5)

		XCTAssertEqual(host.nowPage, 3)
		XCTAssertEqual(host.buffer.count, 2)
		XCTAssertEqual(host.cancelInFlightLoadAndClearBufferCallCount, 1)
		XCTAssertEqual(host.lookaheadCallCount, 1)
		XCTAssertEqual(host.imageDisplayCallCount, 1)
	}

	func testBackskipFloorsAtZero() {
		let host = FakeViewerPageNavigationHost()
		host.nowPage = 3

		ViewerPageNavigation.performBackskip(host: host, value: 5)

		XCTAssertEqual(host.nowPage, 0)
	}

	// MARK: - performGotoPercent

	func testGotoPercentJumpsToTheProportionalPageAndClearsComposedImage() {
		let host = FakeViewerPageNavigationHost()
		host.pageCount = 200

		ViewerPageNavigation.performGotoPercent(host: host, percent: 0.5)

		XCTAssertEqual(host.nowPage, 100)
		XCTAssertEqual(host.cancelInFlightLoadAndClearBufferCallCount, 1)
		XCTAssertEqual(host.clearComposedImageCallCount, 1)
		XCTAssertEqual(host.lookaheadCallCount, 1)
		XCTAssertEqual(host.imageDisplayCallCount, 1)
	}
}
