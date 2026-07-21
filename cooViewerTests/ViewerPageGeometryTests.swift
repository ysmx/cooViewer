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
}
