//
//  NSStringCompareTests.swift
//  cooViewerTests
//

import XCTest

final class NSStringCompareTests: XCTestCase {

	// MARK: - finderCompareS:

	func testFinderCompareSOrdersDigitsAsNumbersNotLexicographically() {
		// kUCCollateDigitsAsNumberMask means "img2" < "img10" (2 < 10), unlike a
		// plain lexicographic compare where "img10" < "img2" ('1' < '2').
		//
		// UCCompareTextDefault's `order` output is a raw magnitude, not
		// necessarily exactly -1/0/1 (matching the original Objective-C, which
		// also just cast the raw SInt32 straight to NSComparisonResult) - only
		// its sign is a meaningful/guaranteed contract, which is all
		// sortUsingSelector: relies on.
		let img2: NSString = "img2.png"
		let img10: NSString = "img10.png"
		XCTAssertLessThan(img2.co_finderCompareS(img10).rawValue, 0)
		XCTAssertGreaterThan(img10.co_finderCompareS(img2).rawValue, 0)
	}

	func testFinderCompareSIsCaseInsensitive() {
		// kUCCollateCaseInsensitiveMask lets case act only as a low-priority
		// tie-breaker (a pure case difference doesn't come back as an exact
		// .orderedSame), so what actually matters for sorting is that a real
		// letter difference always dominates a mere case difference.
		let upperA: NSString = "ABC"
		let lowerD: NSString = "abd"
		XCTAssertLessThan(upperA.co_finderCompareS(lowerD).rawValue, 0)
	}

	func testFinderCompareSOrdersPlainStringsAlphabetically() {
		let apple: NSString = "apple"
		let banana: NSString = "banana"
		XCTAssertLessThan(apple.co_finderCompareS(banana).rawValue, 0)
	}

	func testFinderCompareSSameStringIsOrderedSame() {
		let a: NSString = "same.txt"
		let b: NSString = "same.txt"
		XCTAssertEqual(a.co_finderCompareS(b), .orderedSame)
	}

	// MARK: - versionCompare:

	func testVersionCompareFinalReleaseIsAfterItsOwnBeta() {
		let final: NSString = "1.2"
		let beta: NSString = "1.2b17"
		XCTAssertEqual(final.co_versionCompare(beta), .orderedDescending)
		XCTAssertEqual(beta.co_versionCompare(final), .orderedAscending)
	}

	func testVersionCompareOrdersBetasByBetaNumber() {
		let beta14: NSString = "1.2b14"
		let beta17: NSString = "1.2b17"
		XCTAssertEqual(beta14.co_versionCompare(beta17), .orderedAscending)
		XCTAssertEqual(beta17.co_versionCompare(beta14), .orderedDescending)
	}

	func testVersionCompareOrdersDifferentMainVersions() {
		let v11: NSString = "1.1"
		let v12: NSString = "1.2"
		XCTAssertEqual(v11.co_versionCompare(v12), .orderedAscending)
	}

	func testVersionCompareSameVersionIsOrderedSame() {
		let a: NSString = "1.2b17"
		let b: NSString = "1.2b17"
		XCTAssertEqual(a.co_versionCompare(b), .orderedSame)
	}
}
