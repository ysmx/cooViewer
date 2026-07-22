//
//  ControllerMenuActionTests.m
//  cooViewerTests
//
//  Exercises Controller's co_performMenuActionInMenu:parentTitle:itemTitle:
//  against a standalone menu tree (not NSApp.mainMenu), so the enable-check
//  and lookup logic shared by the key/mouse action switches (#28) can be
//  verified without depending on real application menu state.
//

#import <XCTest/XCTest.h>
#import "Controller.h"

@interface ControllerMenuActionTracker : NSObject
@property (nonatomic) BOOL called;
- (void)trigger:(id)sender;
@end

@implementation ControllerMenuActionTracker
- (void)trigger:(id)sender { self.called = YES; }
@end

@interface ControllerMenuActionTests : XCTestCase
@end

@implementation ControllerMenuActionTests

- (NSMenu *)menuWithItemEnabled:(BOOL)enabled tracker:(ControllerMenuActionTracker **)outTracker
{
	ControllerMenuActionTracker *tracker = [[ControllerMenuActionTracker alloc] init];
	*outTracker = tracker;

	NSMenu *root = [[NSMenu alloc] init];
	NSMenuItem *parent = [[NSMenuItem alloc] initWithTitle:@"Parent" action:NULL keyEquivalent:@""];
	NSMenu *submenu = [[NSMenu alloc] init];
	[parent setSubmenu:submenu];
	[root addItem:parent];

	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Target" action:@selector(trigger:) keyEquivalent:@""];
	[item setTarget:tracker];
	[item setEnabled:enabled];
	[submenu addItem:item];

	return root;
}

- (void)testPerformsActionWhenItemIsEnabled
{
	ControllerMenuActionTracker *tracker;
	NSMenu *root = [self menuWithItemEnabled:YES tracker:&tracker];
	[Controller co_performMenuActionInMenu:root parentTitle:@"Parent" itemTitle:@"Target"];
	XCTAssertTrue(tracker.called);
}

- (void)testDoesNotPerformActionWhenItemIsDisabled
{
	ControllerMenuActionTracker *tracker;
	NSMenu *root = [self menuWithItemEnabled:NO tracker:&tracker];
	[Controller co_performMenuActionInMenu:root parentTitle:@"Parent" itemTitle:@"Target"];
	XCTAssertFalse(tracker.called);
}

- (void)testDoesNothingWhenParentTitleNotFound
{
	ControllerMenuActionTracker *tracker;
	NSMenu *root = [self menuWithItemEnabled:YES tracker:&tracker];
	[Controller co_performMenuActionInMenu:root parentTitle:@"NoSuchParent" itemTitle:@"Target"];
	XCTAssertFalse(tracker.called);
}

- (void)testDoesNothingWhenItemTitleNotFound
{
	ControllerMenuActionTracker *tracker;
	NSMenu *root = [self menuWithItemEnabled:YES tracker:&tracker];
	[Controller co_performMenuActionInMenu:root parentTitle:@"Parent" itemTitle:@"NoSuchItem"];
	XCTAssertFalse(tracker.called);
}

@end
