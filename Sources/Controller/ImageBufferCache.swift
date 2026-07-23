//
//  ImageBufferCache.swift
//  cooViewer
//
//  A small ordered key->image store shared by -[Controller loadImage:]'s
//  per-page image cache and the composed-spread cache used by
//  -composeImage/-lookaheadAndCompose/-imageDisplayIfHasScreenCache.
//  Replaces the two NSMutableArray-of-NSDictionary caches Controller used
//  to maintain by hand, kept free of Controller state so it can be unit
//  tested directly.
//
//  Lookup is a linear scan, matching the original arrays' behavior: a hit
//  is moved to the end (LRU), and duplicate keys (never intentionally
//  created, but never guarded against either) are tolerated exactly as
//  they were when this was plain array manipulation.
//

import AppKit

@objc final class ImageBufferCache: NSObject {

	private var entries: [(key: String, image: NSImage)] = []

	@objc func image(forKey key: String) -> NSImage? {
		guard let index = entries.firstIndex(where: { $0.key == key }) else { return nil }
		let entry = entries.remove(at: index)
		entries.append(entry)
		return entry.image
	}

	@objc func insert(_ image: NSImage, forKey key: String) {
		entries.append((key: key, image: image))
	}

	@objc func trim(toCapacity capacity: Int) {
		while entries.count > capacity {
			entries.removeFirst()
		}
	}

	@objc func removeAll() {
		entries.removeAll()
	}
}
