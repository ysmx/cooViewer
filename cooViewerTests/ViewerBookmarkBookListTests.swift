//
//  ViewerBookmarkBookListTests.swift
//  cooViewerTests
//

import XCTest

final class ViewerBookmarkBookListTests: XCTestCase {

	// MARK: renaming

	func testRenamingUpdatesTheNameAtItsPositionAndTheDictionaryKey() {
		let names = ["bookA", "bookB"]
		let books: NSDictionary = [
			"bookA": ["alias": "aliasA", "bookmarks": []],
			"bookB": ["alias": "aliasB", "bookmarks": []],
		]
		let result = ViewerBookmarkBookList.renaming(names: names, books: books, atIndex: 0, to: "renamed")
		XCTAssertEqual(result?.names, ["renamed", "bookB"])
		XCTAssertNil(result?.books["bookA"])
		XCTAssertEqual((result?.books["renamed"] as? NSDictionary)?["alias"] as? String, "aliasA")
		// The other book is untouched.
		XCTAssertEqual((result?.books["bookB"] as? NSDictionary)?["alias"] as? String, "aliasB")
	}

	func testRenamingToItsOwnCurrentNameIsANoOpNotACollision() {
		let names = ["bookA"]
		let books: NSDictionary = ["bookA": ["alias": "aliasA"]]
		let result = ViewerBookmarkBookList.renaming(names: names, books: books, atIndex: 0, to: "bookA")
		XCTAssertNotNil(result)
		XCTAssertEqual(result?.names, names)
		XCTAssertEqual(result?.books, books)
	}

	func testRenamingToADifferentExistingBookNameReturnsNilForCollision() {
		let names = ["bookA", "bookB"]
		let books: NSDictionary = ["bookA": ["alias": "aliasA"], "bookB": ["alias": "aliasB"]]
		let result = ViewerBookmarkBookList.renaming(names: names, books: books, atIndex: 0, to: "bookB")
		XCTAssertNil(result)
	}

	func testRenamingOutOfRangeIndexIsIgnoredRatherThanCrashing() {
		let names = ["bookA"]
		let books: NSDictionary = ["bookA": ["alias": "aliasA"]]
		let result = ViewerBookmarkBookList.renaming(names: names, books: books, atIndex: 5, to: "x")
		XCTAssertEqual(result?.names, names)
		XCTAssertEqual(result?.books, books)
	}

	// MARK: removingBook

	func testRemovingBookDropsTheEntryAndItsNameWhenOnlyAliasAndTemppathRemain() {
		// alias + temppath are stamped onto every per-book dict regardless
		// of user settings (see -windowWillClose:) -- a "plain, bookmarks
		// only" book always carries both, not just alias.
		let names = ["bookA", "bookB"]
		let books: NSDictionary = [
			"bookA": ["alias": "aliasA", "temppath": "/tmp/a", "bookmarks": [["name": "x", "page": "1"]]],
			"bookB": ["alias": "aliasB", "temppath": "/tmp/b"],
		]
		let result = ViewerBookmarkBookList.removingBook(names: names, books: books, atIndex: 0)
		XCTAssertEqual(result.names, ["bookB"])
		XCTAssertNil(result.books["bookA"])
		// The other book is untouched.
		XCTAssertNotNil(result.books["bookB"])
	}

	func testRemovingBookKeepsTheEntryAndItsNameWhenOtherSettingsExist() {
		// Reproduces the real shape reported by a user: a book with a
		// remembered read mode (in addition to the always-present alias/
		// temppath) disappeared from the list entirely after its last
		// bookmark was removed, because the name was dropped from the list
		// unconditionally instead of only when the book entry itself was
		// dropped.
		let names = ["bookA"]
		let books: NSDictionary = [
			"bookA": ["alias": "aliasA", "temppath": "/tmp/a", "bookmarks": [["name": "x", "page": "1"]], "readMode": 2],
		]
		let result = ViewerBookmarkBookList.removingBook(names: names, books: books, atIndex: 0)
		XCTAssertEqual(result.names, ["bookA"], "the book entry survives, so its name must stay listed")
		let remaining = result.books["bookA"] as? NSDictionary
		XCTAssertNotNil(remaining, "book with settings beyond alias/temppath should survive")
		XCTAssertNil(remaining?["bookmarks"])
		XCTAssertEqual(remaining?["alias"] as? String, "aliasA")
		XCTAssertEqual(remaining?["readMode"] as? Int, 2)
	}

	func testRemovingBookOutOfRangeIndexIsIgnoredRatherThanCrashing() {
		let names = ["bookA"]
		let books: NSDictionary = ["bookA": ["alias": "aliasA"]]
		let result = ViewerBookmarkBookList.removingBook(names: names, books: books, atIndex: 5)
		XCTAssertEqual(result.names, names)
		XCTAssertEqual(result.books, books)
	}
}
