//
//  NSDictionaryAddingTests.swift
//  cooViewerTests
//

import XCTest

final class NSDictionaryAddingTests: XCTestCase {

	private func binding(action: Int, key: String = "a", modifier: Int = 0) -> NSDictionary {
		["action": action, "key": key, "modifier": modifier]
	}

	private func mouseBinding(action: Int, modifier: Int = 0) -> NSDictionary {
		["action": action, "modifier": modifier]
	}

	// MARK: - keyArrayCompare:

	func testKeyArrayCompareOrdersByCanonicalSequenceNotNumericValue() {
		// nextpage (0) precedes goto% (39) in the canonical order, even though
		// numerically 39 > 0 - this is exactly the point of the custom comparator.
		let nextpage = binding(action: 0)
		let gotoPercent = binding(action: 39)
		XCTAssertEqual(nextpage.co_keyArrayCompare(gotoPercent), .orderedAscending)
		XCTAssertEqual(gotoPercent.co_keyArrayCompare(nextpage), .orderedDescending)
	}

	func testKeyArrayCompareBreaksTiesByKeyThenModifier() {
		let a = binding(action: 0, key: "a", modifier: 0)
		let b = binding(action: 0, key: "b", modifier: 0)
		XCTAssertEqual(a.co_keyArrayCompare(b), .orderedAscending)

		let modifierLow = binding(action: 0, key: "a", modifier: 0)
		let modifierHigh = binding(action: 0, key: "a", modifier: 1)
		XCTAssertEqual(modifierLow.co_keyArrayCompare(modifierHigh), .orderedAscending)
	}

	func testKeyArrayCompareSameActionAndKeyAndModifierIsOrderedSame() {
		let x = binding(action: 5, key: "z", modifier: 2)
		let y = binding(action: 5, key: "z", modifier: 2)
		XCTAssertEqual(x.co_keyArrayCompare(y), .orderedSame)
	}

	// MARK: - mouseArrayCompare:

	func testMouseArrayCompareOrdersByCanonicalSequenceNotNumericValue() {
		// nextprevpage-combined (0) precedes ContextualMenu (59) in the canonical order.
		let combined = mouseBinding(action: 0)
		let contextualMenu = mouseBinding(action: 59)
		XCTAssertEqual(combined.co_mouseArrayCompare(contextualMenu), .orderedAscending)
		XCTAssertEqual(contextualMenu.co_mouseArrayCompare(combined), .orderedDescending)
	}

	func testMouseArrayCompareBreaksTiesByModifier() {
		let modifierLow = mouseBinding(action: 6, modifier: 0)
		let modifierHigh = mouseBinding(action: 6, modifier: 1)
		XCTAssertEqual(modifierLow.co_mouseArrayCompare(modifierHigh), .orderedAscending)
	}

	// MARK: - Fallback for action numbers outside the canonical order (not
	// expected in practice - every real action appears in the order arrays -
	// but should still behave sanely rather than crash).

	func testKeyArrayCompareFallsBackToNumericOrderForUnknownActions() {
		let low = binding(action: 9001)
		let high = binding(action: 9002)
		XCTAssertEqual(low.co_keyArrayCompare(high), .orderedAscending)
	}
}
