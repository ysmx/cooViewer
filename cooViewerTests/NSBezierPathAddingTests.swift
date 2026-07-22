//
//  NSBezierPathAddingTests.swift
//  cooViewerTests
//

import XCTest

final class NSBezierPathAddingTests: XCTestCase {

	func testDoubleArcPathBoundsStayWithinTheSourceRect() {
		let rect = NSRect(x: 10, y: 20, width: 100, height: 30)
		let path = NSBezierPath.co_bezierPathWithRectWithDoubleArc(rect)
		let bounds = path.bounds
		XCTAssertGreaterThanOrEqual(bounds.minX, rect.minX - 1)
		XCTAssertLessThanOrEqual(bounds.maxX, rect.maxX + 1)
		XCTAssertGreaterThanOrEqual(bounds.minY, rect.minY - 1)
		XCTAssertLessThanOrEqual(bounds.maxY, rect.maxY + 1)
	}

	func testDoubleArcPathHasTwoArcSegments() {
		let path = NSBezierPath.co_bezierPathWithRectWithDoubleArc(NSRect(x: 0, y: 0, width: 100, height: 30))
		// Each appendArc contributes at least one curve/line element - a
		// capsule made of 2 arcs should have at least 2 non-moveTo elements.
		XCTAssertGreaterThanOrEqual(path.elementCount, 2)
	}

	func testRectWithArcAllFourOpenValuesProduceTheSameElementCount() {
		let rect = NSRect(x: 0, y: 0, width: 50, height: 50)
		let counts = (0...3).map { open in
			NSBezierPath.co_bezierPathWithRectWithArc(rect, rad: 5, open: Int32(open)).elementCount
		}
		// Only the drawing order (which corner is visited first) differs
		// between open=0..3, not how many arcs are appended.
		XCTAssertEqual(Set(counts).count, 1, "all four `open` variants should append the same number of arcs, just in different order")
	}

	func testRectWithArcOutOfRangeOpenProducesAnEmptyPath() {
		let path = NSBezierPath.co_bezierPathWithRectWithArc(NSRect(x: 0, y: 0, width: 50, height: 50), rad: 5, open: 99)
		XCTAssertEqual(path.elementCount, 0)
	}
}
