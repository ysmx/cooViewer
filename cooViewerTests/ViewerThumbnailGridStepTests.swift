//
//  ViewerThumbnailGridStepTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerThumbnailGridStepTests: XCTestCase {

	// 3 columns x 2 rows throughout.

	func testForwardLeftToRightWalksRightThenWrapsDown() {
		let mid = ViewerThumbnailGridStep.step(afterColumn: 0, row: 0, columns: 3, rows: 2, back: false, readFromLeft: true)
		XCTAssertEqual(mid.column, 1); XCTAssertEqual(mid.row, 0); XCTAssertFalse(mid.done)

		let wrap = ViewerThumbnailGridStep.step(afterColumn: 2, row: 0, columns: 3, rows: 2, back: false, readFromLeft: true)
		XCTAssertEqual(wrap.column, 0); XCTAssertEqual(wrap.row, 1); XCTAssertFalse(wrap.done)

		let end = ViewerThumbnailGridStep.step(afterColumn: 2, row: 1, columns: 3, rows: 2, back: false, readFromLeft: true)
		XCTAssertTrue(end.done)
	}

	func testForwardRightToLeftWalksLeftThenWrapsDown() {
		let mid = ViewerThumbnailGridStep.step(afterColumn: 2, row: 0, columns: 3, rows: 2, back: false, readFromLeft: false)
		XCTAssertEqual(mid.column, 1); XCTAssertEqual(mid.row, 0); XCTAssertFalse(mid.done)

		let wrap = ViewerThumbnailGridStep.step(afterColumn: 0, row: 0, columns: 3, rows: 2, back: false, readFromLeft: false)
		XCTAssertEqual(wrap.column, 2); XCTAssertEqual(wrap.row, 1); XCTAssertFalse(wrap.done)

		let end = ViewerThumbnailGridStep.step(afterColumn: 0, row: 1, columns: 3, rows: 2, back: false, readFromLeft: false)
		XCTAssertTrue(end.done)
	}

	func testBackwardLeftToRightWalksLeftThenWrapsUp() {
		let mid = ViewerThumbnailGridStep.step(afterColumn: 2, row: 1, columns: 3, rows: 2, back: true, readFromLeft: true)
		XCTAssertEqual(mid.column, 1); XCTAssertEqual(mid.row, 1); XCTAssertFalse(mid.done)

		let wrap = ViewerThumbnailGridStep.step(afterColumn: 0, row: 1, columns: 3, rows: 2, back: true, readFromLeft: true)
		XCTAssertEqual(wrap.column, 2); XCTAssertEqual(wrap.row, 0); XCTAssertFalse(wrap.done)

		let end = ViewerThumbnailGridStep.step(afterColumn: 0, row: 0, columns: 3, rows: 2, back: true, readFromLeft: true)
		XCTAssertTrue(end.done)
	}

	func testBackwardRightToLeftWalksRightThenWrapsUp() {
		let mid = ViewerThumbnailGridStep.step(afterColumn: 0, row: 1, columns: 3, rows: 2, back: true, readFromLeft: false)
		XCTAssertEqual(mid.column, 1); XCTAssertEqual(mid.row, 1); XCTAssertFalse(mid.done)

		let wrap = ViewerThumbnailGridStep.step(afterColumn: 2, row: 1, columns: 3, rows: 2, back: true, readFromLeft: false)
		XCTAssertEqual(wrap.column, 0); XCTAssertEqual(wrap.row, 0); XCTAssertFalse(wrap.done)

		let end = ViewerThumbnailGridStep.step(afterColumn: 2, row: 0, columns: 3, rows: 2, back: true, readFromLeft: false)
		XCTAssertTrue(end.done)
	}

	func testSingleColumnGridWrapsOnEveryStep() {
		let wrap = ViewerThumbnailGridStep.step(afterColumn: 0, row: 0, columns: 1, rows: 3, back: false, readFromLeft: true)
		XCTAssertEqual(wrap.column, 0); XCTAssertEqual(wrap.row, 1); XCTAssertFalse(wrap.done)

		let end = ViewerThumbnailGridStep.step(afterColumn: 0, row: 2, columns: 1, rows: 3, back: false, readFromLeft: true)
		XCTAssertTrue(end.done)
	}
}
