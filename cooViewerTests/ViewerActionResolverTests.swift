//
//  ViewerActionResolverTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerActionResolverTests: XCTestCase {

	private func keyBinding(key: String, modifier: Int32 = 0, action: Int32, switchAction: Bool = false, value: Int32? = nil) -> [String: Any] {
		var binding: [String: Any] = ["key": key, "modifier": NSNumber(value: modifier), "action": NSNumber(value: action), "switchAction": NSNumber(value: switchAction)]
		if let value {
			binding["value"] = NSNumber(value: value)
		}
		return binding
	}

	private func mouseBinding(button: Int32, modifier: Int32 = 0, action: Int32, switchAction: Bool = false) -> [String: Any] {
		["button": NSNumber(value: button), "modifier": NSNumber(value: modifier), "action": NSNumber(value: action), "switchAction": NSNumber(value: switchAction)]
	}

	// MARK: - Key resolution

	func testNoBindingsReturnsNil() {
		let resolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("z").value), modifier: 0, bindings: [], readFromLeft: false)
		XCTAssertNil(resolution)
	}

	func testMatchingKeyAndModifierReturnsBoundAction() {
		let bindings = [keyBinding(key: "n", action: 39)]
		let resolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("n").value), modifier: 0, bindings: bindings, readFromLeft: false)
		XCTAssertEqual(resolution?.action, 39)
	}

	func testResolutionCarriesTheMatchedBindingForExtraFieldsLikeValue() {
		// Some action bodies (skip/backskip/scroll/loupe-zoom) read a "value"
		// amount out of the matched binding directly, not just the action code.
		let bindings = [keyBinding(key: "n", action: 39, value: 10)]
		let resolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("n").value), modifier: 0, bindings: bindings, readFromLeft: false)
		XCTAssertEqual((resolution?.binding["value"] as? NSNumber)?.int32Value, 10)
	}

	func testMismatchedCharacterFallsThroughToNil() {
		let bindings = [keyBinding(key: "n", action: 39)]
		let resolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("x").value), modifier: 0, bindings: bindings, readFromLeft: false)
		XCTAssertNil(resolution)
	}

	func testMismatchedModifierFallsThroughToNil() {
		let bindings = [keyBinding(key: "n", modifier: 0, action: 39)]
		let resolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("n").value), modifier: 1, bindings: bindings, readFromLeft: false)
		XCTAssertNil(resolution)
	}

	func testFirstMatchingBindingWinsOverLaterOnes() {
		let bindings = [keyBinding(key: "n", action: 1), keyBinding(key: "n", action: 2)]
		let resolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("n").value), modifier: 0, bindings: bindings, readFromLeft: false)
		XCTAssertEqual(resolution?.action, 1)
	}

	func testSwitchActionMirrorsWhenReadingFromLeft() {
		let bindings = [keyBinding(key: "n", action: 0, switchAction: true)]
		let resolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("n").value), modifier: 0, bindings: bindings, readFromLeft: true)
		XCTAssertEqual(resolution?.action, 1)
	}

	func testSwitchActionDoesNotMirrorWhenNotReadingFromLeft() {
		let bindings = [keyBinding(key: "n", action: 0, switchAction: true)]
		let resolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("n").value), modifier: 0, bindings: bindings, readFromLeft: false)
		XCTAssertEqual(resolution?.action, 0)
	}

	func testReadingFromLeftDoesNotMirrorWithoutSwitchAction() {
		let bindings = [keyBinding(key: "n", action: 0, switchAction: false)]
		let resolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("n").value), modifier: 0, bindings: bindings, readFromLeft: true)
		XCTAssertEqual(resolution?.action, 0)
	}

	func testActionOutsideMirrorTableIsUnchangedEvenWithSwitchAction() {
		// Key mirror table only covers actions up to 36; an out-of-range action passes through untouched.
		let bindings = [keyBinding(key: "n", action: 999, switchAction: true)]
		let resolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("n").value), modifier: 0, bindings: bindings, readFromLeft: true)
		XCTAssertEqual(resolution?.action, 999)
	}

	// MARK: - Mouse resolution

	func testMatchingButtonAndModifierReturnsBoundAction() {
		let bindings = [mouseBinding(button: 1, action: 5)]
		let resolution = ViewerActionResolver.resolveMouseAction(button: 1, modifier: 0, bindings: bindings, readFromLeft: false)
		XCTAssertEqual(resolution?.action, 5)
	}

	func testMouseNoMatchReturnsNil() {
		let bindings = [mouseBinding(button: 1, action: 5)]
		let resolution = ViewerActionResolver.resolveMouseAction(button: 2, modifier: 0, bindings: bindings, readFromLeft: false)
		XCTAssertNil(resolution)
	}

	func testMouseSwitchActionMirrorsWhenReadingFromLeft() {
		let bindings = [mouseBinding(button: 1, action: 6, switchAction: true)]
		let resolution = ViewerActionResolver.resolveMouseAction(button: 1, modifier: 0, bindings: bindings, readFromLeft: true)
		XCTAssertEqual(resolution?.action, 7)
	}

	// The key-side and mouse-side mirror tables cover different action ranges
	// (key: up to 36, mouse: up to 45) - this test pins that documented
	// discrepancy so it isn't accidentally "fixed" by a future edit without
	// noticing it changes behavior.
	func testKeyAndMouseMirrorTablesCoverDifferentRanges() {
		let keyBindings = [keyBinding(key: "n", action: 44, switchAction: true)]
		let keyResolution = ViewerActionResolver.resolveKeyAction(character: unichar(UnicodeScalar("n").value), modifier: 0, bindings: keyBindings, readFromLeft: true)
		XCTAssertEqual(keyResolution?.action, 44, "key mirror table does not cover action 44")

		let mouseBindings = [mouseBinding(button: 1, action: 44, switchAction: true)]
		let mouseResolution = ViewerActionResolver.resolveMouseAction(button: 1, modifier: 0, bindings: mouseBindings, readFromLeft: true)
		XCTAssertEqual(mouseResolution?.action, 45, "mouse mirror table does cover action 44")
	}
}
