//
//  ViewerPageGeometryTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerPageGeometryTests: XCTestCase {

	// Single-page mode: first == second, so left/right and reading
	// direction shouldn't matter at all.
	func testSinglePageModeAlwaysReturnsTheSamePage() {
		let index = ViewerPageGeometry.trashIndex(
			isLeft: true, readFromLeft: true,
			firstImagePageIndex: 4, secondImagePageIndex: 4)
		XCTAssertEqual(index, 4)
	}

	// Spread mode, reading left-to-right (Western): the earlier page
	// (first) is physically on the left, the later page (second) on the
	// right.
	func testSpreadReadingLeftToRightPutsFirstPageOnTheLeft() {
		XCTAssertEqual(
			ViewerPageGeometry.trashIndex(isLeft: true, readFromLeft: true, firstImagePageIndex: 10, secondImagePageIndex: 11),
			10)
		XCTAssertEqual(
			ViewerPageGeometry.trashIndex(isLeft: false, readFromLeft: true, firstImagePageIndex: 10, secondImagePageIndex: 11),
			11)
	}

	// Spread mode, reading right-to-left (manga): the pages are mirrored -
	// the earlier page (first) renders on the physical right.
	func testSpreadReadingRightToLeftPutsFirstPageOnTheRight() {
		XCTAssertEqual(
			ViewerPageGeometry.trashIndex(isLeft: true, readFromLeft: false, firstImagePageIndex: 10, secondImagePageIndex: 11),
			11)
		XCTAssertEqual(
			ViewerPageGeometry.trashIndex(isLeft: false, readFromLeft: false, firstImagePageIndex: 10, secondImagePageIndex: 11),
			10)
	}

	// MARK: - skipTarget

	func testSkipTargetAdvancesByValueMinusTwo() {
		XCTAssertEqual(ViewerPageGeometry.skipTarget(current: 10, count: 100, skipValue: 5), 13)
	}

	func testSkipTargetClampsToCountMinusTwoWhenPastTheEnd() {
		XCTAssertEqual(ViewerPageGeometry.skipTarget(current: 90, count: 100, skipValue: 20), 98)
	}

	// MARK: - backskipTarget

	func testBackskipTargetRetreatsByValuePlusTwo() {
		XCTAssertEqual(ViewerPageGeometry.backskipTarget(current: 10, skipValue: 5), 3)
	}

	func testBackskipTargetFloorsAtZero() {
		XCTAssertEqual(ViewerPageGeometry.backskipTarget(current: 3, skipValue: 5), 0)
	}

	// MARK: - gotoPercentTarget

	func testGotoPercentTargetComputesProportionalPage() {
		XCTAssertEqual(ViewerPageGeometry.gotoPercentTarget(count: 200, percent: 0.5), 100)
	}

	func testGotoPercentTargetFloorsAtZeroForNegativePercent() {
		XCTAssertEqual(ViewerPageGeometry.gotoPercentTarget(count: 200, percent: -0.1), 0)
	}

	// MARK: - shouldJumpToTopPage

	func testShouldJumpToTopPageUsesThresholdTwoWithSecondImage() {
		XCTAssertFalse(ViewerPageGeometry.shouldJumpToTopPage(current: 2, hasSecondImage: true))
		XCTAssertTrue(ViewerPageGeometry.shouldJumpToTopPage(current: 3, hasSecondImage: true))
	}

	func testShouldJumpToTopPageUsesThresholdOneWithoutSecondImage() {
		XCTAssertFalse(ViewerPageGeometry.shouldJumpToTopPage(current: 1, hasSecondImage: false))
		XCTAssertTrue(ViewerPageGeometry.shouldJumpToTopPage(current: 2, hasSecondImage: false))
	}

	// MARK: - shouldLoadHalfNextPage

	func testShouldLoadHalfNextPageRequiresSecondImageAndRoomToAdvance() {
		XCTAssertTrue(ViewerPageGeometry.shouldLoadHalfNextPage(current: 5, count: 10, hasSecondImage: true))
		XCTAssertFalse(ViewerPageGeometry.shouldLoadHalfNextPage(current: 5, count: 10, hasSecondImage: false))
		XCTAssertFalse(ViewerPageGeometry.shouldLoadHalfNextPage(current: 10, count: 10, hasSecondImage: true))
	}
}
