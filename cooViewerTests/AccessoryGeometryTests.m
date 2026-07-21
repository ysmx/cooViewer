//
//  AccessoryGeometryTests.m
//  cooViewerTests
//

#import <XCTest/XCTest.h>
#import "AccessoryGeometry.h"

@interface AccessoryGeometryTests : XCTestCase
@end

@implementation AccessoryGeometryTests

- (void)testPageBarLayoutRectTopCenterIsHorizontallyCentered
{
	NSRect contentFrame = NSMakeRect(0, 0, 400, 300);
	NSRect rect = COPageBarLayoutRect(contentFrame, NSMakePoint(0, 0), 100, 20, COAccessoryPlacementTopCenter);
	XCTAssertEqualWithAccuracy(NSMidX(rect), NSMidX(contentFrame), 1.0);
	XCTAssertTrue(COAccessoryPlacementIsTop(COAccessoryPlacementTopCenter));
	XCTAssertTrue(COAccessoryPlacementIsCenter(COAccessoryPlacementTopCenter));
	XCTAssertFalse(COAccessoryPlacementIsRight(COAccessoryPlacementTopCenter));
}

- (void)testPageBarLayoutRectAllSixPlacementsStayWithinContentFrame
{
	NSRect contentFrame = NSMakeRect(0, 0, 400, 300);
	int placements[] = {
		COAccessoryPlacementTopLeft, COAccessoryPlacementTopRight,
		COAccessoryPlacementBottomLeft, COAccessoryPlacementBottomRight,
		COAccessoryPlacementTopCenter, COAccessoryPlacementBottomCenter,
	};
	for (int i = 0; i < 6; i++) {
		NSRect rect = COPageBarLayoutRect(contentFrame, NSMakePoint(5, 5), 100, 20, placements[i]);
		XCTAssertTrue(NSMinX(rect) >= 0, @"placement %d: minX %f should be >= 0", placements[i], NSMinX(rect));
		XCTAssertTrue(NSMaxX(rect) <= contentFrame.size.width, @"placement %d: maxX %f should be <= %f", placements[i], NSMaxX(rect), contentFrame.size.width);
	}
}

- (void)testPageBarLayoutRectLeftAndRightPlacementsDifferHorizontally
{
	NSRect contentFrame = NSMakeRect(0, 0, 400, 300);
	NSRect leftRect = COPageBarLayoutRect(contentFrame, NSMakePoint(0, 0), 100, 20, COAccessoryPlacementTopLeft);
	NSRect rightRect = COPageBarLayoutRect(contentFrame, NSMakePoint(0, 0), 100, 20, COAccessoryPlacementTopRight);
	XCTAssertTrue(NSMinX(leftRect) < NSMinX(rightRect));
}

- (void)testPageStringLayoutRectTopCenterIsHorizontallyCentered
{
	NSRect contentFrame = NSMakeRect(0, 0, 400, 300);
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"1 / 10"];
	NSRect rect = COPageStringLayoutRect(contentFrame, string, NSMakePoint(0, 0), COAccessoryPlacementTopCenter);
	XCTAssertEqualWithAccuracy(NSMidX(rect), NSMidX(contentFrame), 1.0);
}

- (void)testCOIntRectRoundsToNearestInteger
{
	NSRect rect = NSMakeRect(1.2, 2.6, 3.4, 4.5);
	NSRect rounded = COIntRect(rect);
	XCTAssertEqual(rounded.origin.x, 1.0);
	XCTAssertEqual(rounded.origin.y, 3.0);
	XCTAssertEqual(rounded.size.width, 3.0);
	XCTAssertEqual(rounded.size.height, 5.0);
}

@end
