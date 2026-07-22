//
//  ViewerActionResolver.swift
//  cooViewer
//
//  Pure lookup of which action code a key or mouse binding resolves to,
//  kept free of Controller state so it can be unit tested directly. See
//  -[Controller getKeyAction:mod:mode:slideshow:] and
//  -[Controller getMouseAction:mod:mode:left:], which select the binding
//  array for the current mode, call the matching resolver below, and then
//  run the (unchanged, still Objective-C) action-execution switch.
//

import Foundation

/// The outcome of a successful resolution: the (possibly mirrored) action
/// code to execute, plus the raw binding dictionary that matched - callers
/// still need the latter because some action bodies read extra per-binding
/// data out of it directly (e.g. skip/scroll/zoom amount under "value").
@objc final class ViewerActionResolution: NSObject {
	@objc let action: Int32
	@objc let binding: [String: Any]

	@objc init(action: Int32, binding: [String: Any]) {
		self.action = action
		self.binding = binding
	}
}

@objc final class ViewerActionResolver: NSObject {

	/// Key-side left/right mirror table: when a matched binding has
	/// `switchAction` set and the book reads left-to-right, its action swaps
	/// to the paired action so "next/previous"-style actions stay physically
	/// consistent regardless of reading direction. Verbatim copy of the
	/// switch previously inlined in `-getKeyAction:mod:mode:slideshow:`
	/// (covers actions up to 36).
	private static let keyMirrorPairs: [Int32: Int32] = [
		0: 1, 1: 0,
		2: 3, 3: 2,
		4: 5, 5: 4,
		6: 7, 7: 6,
		8: 9, 9: 8,
		13: 14, 14: 13,
		26: 27, 27: 26,
		35: 36, 36: 35,
	]

	/// Mouse-side mirror table. Verbatim copy of the switch previously
	/// inlined in `-getMouseAction:mod:mode:left:` (covers actions up to 45).
	/// Note this does not cover the same action range as `keyMirrorPairs` -
	/// the two tables were written independently and have historically
	/// drifted (see issue #9); preserved as-is rather than reconciled, since
	/// that would be a behavior change beyond this extraction's scope.
	private static let mouseMirrorPairs: [Int32: Int32] = [
		6: 7, 7: 6,
		8: 9, 9: 8,
		10: 11, 11: 10,
		12: 13, 13: 12,
		14: 15, 15: 14,
		19: 20, 20: 19,
		33: 34, 34: 33,
		44: 45, 45: 44,
	]

	/// `bindings` is the raw array of key-binding dictionaries (each with
	/// "key"/"modifier"/"action"/"switchAction" entries, as built in
	/// +[PreferenceController setDefaultKeyArray] and edited via the
	/// Preferences input table). Returns the first matching binding
	/// (with its action code already mirrored, if applicable), or nil.
	@objc static func resolveKeyAction(character: unichar, modifier: Int32, bindings: [[String: Any]], readFromLeft: Bool) -> ViewerActionResolution? {
		for binding in bindings {
			let bindingCharacter = (binding["key"] as? String)?.utf16.first ?? 0
			guard bindingCharacter == character else { continue }
			let bindingModifier = (binding["modifier"] as? NSNumber)?.int32Value ?? 0
			guard bindingModifier == modifier else { continue }

			var action = (binding["action"] as? NSNumber)?.int32Value ?? 0
			let switchAction = (binding["switchAction"] as? NSNumber)?.boolValue ?? false
			if switchAction && readFromLeft, let mirrored = keyMirrorPairs[action] {
				action = mirrored
			}
			return ViewerActionResolution(action: action, binding: binding)
		}
		return nil
	}

	/// Same as `resolveKeyAction`, for mouse-binding dictionaries (each with
	/// "button"/"modifier"/"action"/"switchAction" entries, as built in
	/// +[PreferenceController setDefaultMouseArray]).
	@objc static func resolveMouseAction(button: Int32, modifier: Int32, bindings: [[String: Any]], readFromLeft: Bool) -> ViewerActionResolution? {
		for binding in bindings {
			let bindingButton = (binding["button"] as? NSNumber)?.int32Value ?? 0
			guard bindingButton == button else { continue }
			let bindingModifier = (binding["modifier"] as? NSNumber)?.int32Value ?? 0
			guard bindingModifier == modifier else { continue }

			var action = (binding["action"] as? NSNumber)?.int32Value ?? 0
			let switchAction = (binding["switchAction"] as? NSNumber)?.boolValue ?? false
			if switchAction && readFromLeft, let mirrored = mouseMirrorPairs[action] {
				action = mirrored
			}
			return ViewerActionResolution(action: action, binding: binding)
		}
		return nil
	}
}
