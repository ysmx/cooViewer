//
//  NSString_Compare.swift
//  cooViewer
//

import Foundation
import CoreServices

extension NSString {

	private static let finderCompareOptions: UCCollateOptions = UCCollateOptions(
		kUCCollateComposeInsensitiveMask
		| kUCCollateWidthInsensitiveMask
		| kUCCollateCaseInsensitiveMask
		| kUCCollateDigitsOverrideMask
		| kUCCollateDigitsAsNumberMask
		| kUCCollatePunctuationSignificantMask
	)

	@objc(finderCompareS:)
	func co_finderCompareS(_ aString: NSString) -> ComparisonResult {
		let length1 = self.length
		let length2 = aString.length
		var buffer1 = [unichar](repeating: 0, count: length1)
		var buffer2 = [unichar](repeating: 0, count: length2)
		self.getCharacters(&buffer1)
		aString.getCharacters(&buffer2)

		var order: Int32 = 0
		UCCompareTextDefault(NSString.finderCompareOptions, &buffer1, length1, &buffer2, length2, nil, &order)
		return ComparisonResult(rawValue: Int(order)) ?? .orderedSame
	}

	// The original compared NSDate?s returned by -attributesOfItemAtPath: via
	// plain `[date compare:otherDate]`, relying on Objective-C's nil-messaging
	// behavior when either date was missing. Swift has no equivalent, so a
	// missing date is treated as ordered before any real date here (both
	// missing compares as same) - this path isn't reachable in practice since
	// every item on disk has creation/modification dates.
	private static func co_compare(_ lhs: Date?, _ rhs: Date?) -> ComparisonResult {
		switch (lhs, rhs) {
		case (nil, nil): return .orderedSame
		case (nil, _): return .orderedAscending
		case (_, nil): return .orderedDescending
		case let (l?, r?): return l.compare(r)
		}
	}

	@objc(fileCreationDateCompare:)
	func co_fileCreationDateCompare(_ otherString: NSString) -> ComparisonResult {
		let sourceDate = (try? FileManager.default.attributesOfItem(atPath: self.resolvingSymlinksInPath))?[.creationDate] as? Date
		let otherDate = (try? FileManager.default.attributesOfItem(atPath: otherString.resolvingSymlinksInPath))?[.creationDate] as? Date
		let result = NSString.co_compare(sourceDate, otherDate)
		if result == .orderedSame {
			return self.co_finderCompareS(otherString)
		}
		return result
	}

	@objc(fileModificationDateCompare:)
	func co_fileModificationDateCompare(_ otherString: NSString) -> ComparisonResult {
		let sourceDate = (try? FileManager.default.attributesOfItem(atPath: self.resolvingSymlinksInPath))?[.modificationDate] as? Date
		let otherDate = (try? FileManager.default.attributesOfItem(atPath: otherString.resolvingSymlinksInPath))?[.modificationDate] as? Date
		let result = NSString.co_compare(sourceDate, otherDate)
		if result == .orderedSame {
			return self.co_finderCompareS(otherString)
		}
		return result
	}

	@objc(versionCompare:)
	func co_versionCompare(_ otherString: NSString) -> ComparisonResult {
		let selfParts = (self as String).components(separatedBy: "b")
		let otherParts = (otherString as String).components(separatedBy: "b")
		let ver = selfParts[0]
		let otherVer = otherParts[0]
		let beta = selfParts.count == 2 ? selfParts[1] : nil
		let otherBeta = otherParts.count == 2 ? otherParts[1] : nil

		let result = ver.compare(otherVer)
		if result != .orderedSame {
			return result
		}
		if beta == nil { return .orderedDescending }
		if otherBeta == nil { return .orderedAscending }
		return beta!.compare(otherBeta!)
	}
}
