#import <XCTest/XCTest.h>
#import "CustomWindow.h"

@interface CustomWindowFrameTests : XCTestCase
@end

@implementation CustomWindowFrameTests

- (void)testFrameSmallerThanVisibleFrameIsPreserved
{
	NSRect frame = NSMakeRect(100, 120, 800, 600);
	NSRect visibleFrame = NSMakeRect(0, 25, 1440, 875);

	XCTAssertTrue(NSEqualRects(COFitWindowFrameToVisibleFrame(frame, visibleFrame), frame));
}

- (void)testOversizedFrameIsReducedToVisibleFrame
{
	NSRect frame = NSMakeRect(-100, -100, 2000, 1200);
	NSRect visibleFrame = NSMakeRect(0, 25, 1440, 875);

	NSRect result = COFitWindowFrameToVisibleFrame(frame, visibleFrame);

	XCTAssertTrue(NSEqualRects(result, visibleFrame));
}

- (void)testOnlyOversizedDimensionIsReduced
{
	NSRect frame = NSMakeRect(100, 100, 1800, 600);
	NSRect visibleFrame = NSMakeRect(0, 25, 1440, 875);

	NSRect result = COFitWindowFrameToVisibleFrame(frame, visibleFrame);

	XCTAssertEqual(result.size.width, 1440);
	XCTAssertEqual(result.size.height, 600);
	XCTAssertEqual(result.origin.x, 0);
	XCTAssertEqual(result.origin.y, 100);
}

- (void)testFrameIsMovedInsideVisibleFrameAfterSizing
{
	NSRect frame = NSMakeRect(1200, 700, 800, 600);
	NSRect visibleFrame = NSMakeRect(0, 25, 1440, 875);

	NSRect result = COFitWindowFrameToVisibleFrame(frame, visibleFrame);

	XCTAssertEqual(NSMaxX(result), NSMaxX(visibleFrame));
	XCTAssertEqual(NSMaxY(result), NSMaxY(visibleFrame));
}

@end
