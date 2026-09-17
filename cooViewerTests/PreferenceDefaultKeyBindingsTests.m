#import <XCTest/XCTest.h>
#import "PreferenceController.h"

@interface PreferenceDefaultKeyBindingsTests : XCTestCase
@end

@implementation PreferenceDefaultKeyBindingsTests

- (void)testDefaultBindingsContainFullscreenToggleOnF
{
	NSArray *bindings = [PreferenceController defaultKeyArray];
	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *binding, NSDictionary *bindingsByVariable) {
		return [[binding objectForKey:@"action"] intValue] == 49 &&
			[[binding objectForKey:@"key"] isEqualToString:@"f"] &&
			[[binding objectForKey:@"modifier"] intValue] == 0;
	}];

	XCTAssertEqual([[bindings filteredArrayUsingPredicate:predicate] count], 1U);
}

- (void)testMigrationAddsFullscreenBindingWhenFIsAvailable
{
	NSMutableArray *bindings = [NSMutableArray array];

	XCTAssertTrue([PreferenceController addDefaultFullscreenKeyBindingIfPossibleToArray:bindings]);
	XCTAssertEqualObjects([[bindings objectAtIndex:0] objectForKey:@"key"], @"f");
	XCTAssertEqual([[[bindings objectAtIndex:0] objectForKey:@"action"] intValue], 49);
}

- (void)testMigrationPreservesAnExistingFullscreenBinding
{
	NSMutableArray *bindings = [NSMutableArray arrayWithObject:
		@{@"action": @49, @"keyname": @"g", @"key": @"g", @"modifier": @0}];

	XCTAssertFalse([PreferenceController addDefaultFullscreenKeyBindingIfPossibleToArray:bindings]);
	XCTAssertEqual([bindings count], 1U);
	XCTAssertEqualObjects([[bindings objectAtIndex:0] objectForKey:@"key"], @"g");
}

- (void)testMigrationDoesNotOverrideAnotherActionAlreadyUsingF
{
	NSMutableArray *bindings = [NSMutableArray arrayWithObject:
		@{@"action": @12, @"keyname": @"f", @"key": @"f", @"modifier": @0}];

	XCTAssertFalse([PreferenceController addDefaultFullscreenKeyBindingIfPossibleToArray:bindings]);
	XCTAssertEqual([bindings count], 1U);
	XCTAssertEqual([[[bindings objectAtIndex:0] objectForKey:@"action"] intValue], 12);
}

@end
