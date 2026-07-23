//
//  ViewerBookSettingsKey.swift
//  cooViewer
//
//  Pure key-resolution logic used by -[Controller openPageLoadDidFinish:]
//  when persisting a book's settings (bookmarks, read mode, etc.) into
//  the "BookSettings" dictionary, kept free of Controller/NSUserDefaults
//  state so it can be unit tested directly.
//

import Foundation

@objc final class ViewerBookSettingsKey: NSObject {

	/// Returns `existingKey` if the book already has an entry. Otherwise
	/// finds a key not already present in `existingKeys`, starting with
	/// `baseName` and falling back to "baseName#2", "baseName#3", ...
	/// to avoid colliding with a different book that happens to share
	/// the same display name.
	@objc static func resolvedKey(existingKeys: [String], existingKey: String?, baseName: String) -> String {
		if let existingKey = existingKey {
			return existingKey
		}
		var key = baseName
		var i = 2
		while existingKeys.contains(key) {
			key = "\(baseName)#\(i)"
			i += 1
		}
		return key
	}
}
