#import <XCTest/XCTest.h>

@interface MenuLocalizationTests : XCTestCase
@end

@implementation MenuLocalizationTests

- (NSDictionary *)stringsNamed:(NSString *)name localization:(NSString *)localization
{
	NSString *path = [[NSBundle mainBundle] pathForResource:name
										 ofType:@"strings"
									inDirectory:nil
							 forLocalization:localization];
	XCTAssertNotNil(path);
	return [NSDictionary dictionaryWithContentsOfFile:path];
}

- (void)testViewLookupMatchesLocalizedMainMenuTitle
{
	NSDictionary *expectedTitles = @{@"ja": @"表示", @"en": @"View"};
	for (NSString *localization in expectedTitles) {
		NSDictionary *localizable = [self stringsNamed:@"Localizable" localization:localization];

		XCTAssertEqualObjects([localizable objectForKey:@"View"],
						  [expectedTitles objectForKey:localization],
						  @"%@ localization must let runtime menu lookup find the View menu", localization);
	}
}

- (void)testFullscreenLookupMatchesLocalizedMainMenuItemTitle
{
	NSDictionary *expectedTitles = @{
		@"ja": @"フルスクリーン／ウィンドウ切替",
		@"en": @"Toggle Fullscreen / Window"
	};
	for (NSString *localization in expectedTitles) {
		NSDictionary *localizable = [self stringsNamed:@"Localizable" localization:localization];

		XCTAssertEqualObjects([localizable objectForKey:@"Fullscreen"],
						  [expectedTitles objectForKey:localization],
						  @"%@ localization must let runtime menu lookup find the fullscreen item", localization);
	}
}

@end
