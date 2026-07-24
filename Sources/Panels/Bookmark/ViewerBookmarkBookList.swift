//
//  ViewerBookmarkBookList.swift
//  cooViewer
//
//  Pure operations on the book-level structure the "all bookmarks" screen
//  edits: the ordered list of book names (bookNameArray) paired with the
//  BookSettings-shaped dictionary (allBookmark, name -> per-book dict with
//  "bookmarks"/"alias"/other persisted settings). Continues #57 phase 1's
//  BookmarkStore model layer one level up from ViewerBookmarkList, which
//  operates on a single book's bookmarks array.
//

import Foundation

@objc final class ViewerBookmarkBookListResult: NSObject {
	@objc let names: [String]
	@objc let books: NSDictionary

	init(names: [String], books: NSDictionary) {
		self.names = names
		self.books = books
	}
}

@objc final class ViewerBookmarkBookList: NSObject {

	/// Renames the book at `index` to `newName`, keeping its position in
	/// `names`. Renaming to the book's own current name, or an out-of-range
	/// index, is a no-op (unchanged result, not a failure). Returns nil if
	/// `newName` already names a *different* existing book, so the caller
	/// can beep -- matching the original's collision guard.
	@objc(renamingBookNames:books:atIndex:to:)
	static func renaming(names: [String], books: NSDictionary, atIndex index: Int32, to newName: NSString) -> ViewerBookmarkBookListResult? {
		let i = Int(index)
		guard names.indices.contains(i) else {
			return ViewerBookmarkBookListResult(names: names, books: books)
		}
		let oldName = names[i]
		let newNameString = newName as String
		if oldName == newNameString {
			return ViewerBookmarkBookListResult(names: names, books: books)
		}
		if books[newName] != nil {
			return nil
		}
		guard let bookDic = books[oldName] else {
			return ViewerBookmarkBookListResult(names: names, books: books)
		}

		var newNames = names
		newNames[i] = newNameString
		let newBooks = NSMutableDictionary(dictionary: books)
		newBooks.removeObject(forKey: oldName)
		newBooks[newName] = bookDic
		return ViewerBookmarkBookListResult(names: newNames, books: newBooks)
	}

	/// Keys every per-book dict carries regardless of whether the user has
	/// ever changed a per-book setting -- see -windowWillClose: and
	/// -openPageLoadDidFinish:, which always stamp both onto currentBookSetting.
	private static let alwaysPresentBookKeys: Set<String> = ["alias", "temppath"]

	/// Removes the book at `index` from the list -- always, regardless of
	/// whether its underlying dict carries any settings beyond alias/
	/// temppath. Explicitly deleting a book here is a deliberate, direct
	/// action ("I don't want this book in my bookmark list"); whether it
	/// happens to also host unrelated per-book settings (read mode, sort
	/// mode, marks, ...) is an implementation detail this screen has no
	/// business surfacing, so the visible result is always the same:
	/// the row disappears. (This is different from clearing a book's
	/// bookmarks one at a time via ViewerBookmarkList.removing, which never
	/// touches this list -- only an explicit "delete this book" does.)
	///
	/// Underneath, if nothing but alias/temppath is left (the book only
	/// ever existed to hold bookmarks), the dict entry is dropped entirely;
	/// otherwise it's kept with bookmarks cleared, so those unrelated
	/// settings survive in storage -- just not in this list.
	/// Out-of-range indexes are a no-op.
	@objc(removingBookNames:books:atIndex:)
	static func removingBook(names: [String], books: NSDictionary, atIndex index: Int32) -> ViewerBookmarkBookListResult {
		let i = Int(index)
		guard names.indices.contains(i) else {
			return ViewerBookmarkBookListResult(names: names, books: books)
		}
		let name = names[i]

		let newBooks = NSMutableDictionary(dictionary: books)
		if let bookDic = books[name] as? NSDictionary {
			let remaining = NSMutableDictionary(dictionary: bookDic)
			remaining.removeObject(forKey: "bookmarks")
			let remainingKeys = Set(remaining.allKeys.compactMap { $0 as? String })
			if remainingKeys.isSubset(of: alwaysPresentBookKeys) {
				newBooks.removeObject(forKey: name)
			} else {
				newBooks[name] = remaining
			}
		}

		var newNames = names
		newNames.remove(at: i)
		return ViewerBookmarkBookListResult(names: newNames, books: newBooks)
	}
}
