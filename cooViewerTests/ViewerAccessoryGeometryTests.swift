//
//  ViewerAccessoryGeometryTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerAccessoryGeometryTests: XCTestCase {

	func testPageBarLayoutRectTopCenterIsHorizontallyCentered() {
		let contentFrame = NSRect(x: 0, y: 0, width: 400, height: 300)
		let rect = ViewerAccessoryGeometry.pageBarLayoutRect(
			contentFrame: contentFrame, margin: NSPoint(x: 0, y: 0),
			widthValue: 100, heightValue: 20, position: ViewerAccessoryGeometry.placementTopCenter)
		XCTAssertEqual(rect.midX, contentFrame.midX, accuracy: 1.0)
		XCTAssertTrue(ViewerAccessoryGeometry.placementIsTop(ViewerAccessoryGeometry.placementTopCenter))
		XCTAssertTrue(ViewerAccessoryGeometry.placementIsCenter(ViewerAccessoryGeometry.placementTopCenter))
		XCTAssertFalse(ViewerAccessoryGeometry.placementIsRight(ViewerAccessoryGeometry.placementTopCenter))
	}

	func testPageBarLayoutRectAllSixPlacementsStayWithinContentFrame() {
		let contentFrame = NSRect(x: 0, y: 0, width: 400, height: 300)
		let placements: [Int32] = [
			ViewerAccessoryGeometry.placementTopLeft, ViewerAccessoryGeometry.placementTopRight,
			ViewerAccessoryGeometry.placementBottomLeft, ViewerAccessoryGeometry.placementBottomRight,
			ViewerAccessoryGeometry.placementTopCenter, ViewerAccessoryGeometry.placementBottomCenter,
		]
		for placement in placements {
			let rect = ViewerAccessoryGeometry.pageBarLayoutRect(
				contentFrame: contentFrame, margin: NSPoint(x: 5, y: 5),
				widthValue: 100, heightValue: 20, position: placement)
			XCTAssertTrue(rect.minX >= 0, "placement \(placement): minX \(rect.minX) should be >= 0")
			XCTAssertTrue(rect.maxX <= contentFrame.width, "placement \(placement): maxX \(rect.maxX) should be <= \(contentFrame.width)")
		}
	}

	func testPageBarLayoutRectLeftAndRightPlacementsDifferHorizontally() {
		let contentFrame = NSRect(x: 0, y: 0, width: 400, height: 300)
		let leftRect = ViewerAccessoryGeometry.pageBarLayoutRect(
			contentFrame: contentFrame, margin: .zero, widthValue: 100, heightValue: 20,
			position: ViewerAccessoryGeometry.placementTopLeft)
		let rightRect = ViewerAccessoryGeometry.pageBarLayoutRect(
			contentFrame: contentFrame, margin: .zero, widthValue: 100, heightValue: 20,
			position: ViewerAccessoryGeometry.placementTopRight)
		XCTAssertLessThan(leftRect.minX, rightRect.minX)
	}

	func testPageStringLayoutRectTopCenterIsHorizontallyCentered() {
		let contentFrame = NSRect(x: 0, y: 0, width: 400, height: 300)
		let string = NSAttributedString(string: "1 / 10")
		let rect = ViewerAccessoryGeometry.pageStringLayoutRect(
			contentFrame: contentFrame, string: string, margin: .zero,
			position: ViewerAccessoryGeometry.placementTopCenter)
		XCTAssertEqual(rect.midX, contentFrame.midX, accuracy: 1.0)
	}

	func testIntRectRoundsToNearestInteger() {
		let rect = NSRect(x: 1.2, y: 2.6, width: 3.4, height: 4.5)
		let rounded = ViewerAccessoryGeometry.intRect(rect)
		XCTAssertEqual(rounded.origin.x, 1.0)
		XCTAssertEqual(rounded.origin.y, 3.0)
		XCTAssertEqual(rounded.size.width, 3.0)
		XCTAssertEqual(rounded.size.height, 5.0)
	}
}
