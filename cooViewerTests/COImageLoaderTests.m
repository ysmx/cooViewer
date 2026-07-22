//
//  COImageLoaderTests.m
//  cooViewerTests
//
//  Integration tests exercising COImageLoader's real directory/archive/PDF
//  decode paths against fixture files in cooViewerTests/Fixtures/. The
//  Xcode file-system-synchronized test target flattens resource folders, so
//  fixtures are located by filename via -pathForResource:ofType: rather than
//  by their source subfolder.
//

#import <XCTest/XCTest.h>
#import "COImageLoader.h"

@interface COImageLoaderTests : XCTestCase
@property (nonatomic, copy) NSString *tempDirectoryPath;
@end

@implementation COImageLoaderTests

- (void)tearDown
{
	if (self.tempDirectoryPath) {
		[[NSFileManager defaultManager] removeItemAtPath:self.tempDirectoryPath error:nil];
		self.tempDirectoryPath = nil;
	}
	[super tearDown];
}

- (NSString *)fixturePathForResource:(NSString *)name ofType:(NSString *)type
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:name ofType:type];
	XCTAssertNotNil(path, @"missing fixture %@.%@ in test bundle resources", name, type);
	return path;
}

// Directory mode needs a real folder on disk (the test bundle flattens all
// fixtures into one Resources folder), so copy the three sample images into
// a fresh temporary directory to get an isolated, well-defined listing.
- (NSString *)makeTempDirectoryWithSampleImages
{
	NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
	for (NSString *name in @[@"01", @"02", @"03"]) {
		NSString *source = [self fixturePathForResource:name ofType:@"png"];
		NSString *destination = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]];
		[[NSFileManager defaultManager] copyItemAtPath:source toPath:destination error:nil];
	}
	self.tempDirectoryPath = tempDir;
	return tempDir;
}

#pragma mark - Directory mode

- (void)testDirectoryModeListsAllThreeImagesInSortedOrder
{
	NSString *directory = [self makeTempDirectoryWithSampleImages];
	COImageLoader *loader = [[COImageLoader alloc] initWithPath:directory readSubFolder:NO controller:nil];

	XCTAssertEqual([loader mode], COImageLoaderModeDirectory);
	XCTAssertEqual([loader itemCount], 3);
	XCTAssertEqualObjects([[loader itemPathAtIndex:0] lastPathComponent], @"01.png");
	XCTAssertEqualObjects([[loader itemPathAtIndex:1] lastPathComponent], @"02.png");
	XCTAssertEqualObjects([[loader itemPathAtIndex:2] lastPathComponent], @"03.png");
}

#pragma mark - Archive mode

- (void)testArchiveModeListsAllThreeImages
{
	NSString *archivePath = [self fixturePathForResource:@"sample" ofType:@"zip"];
	COImageLoader *loader = [[COImageLoader alloc] initWithPath:archivePath readSubFolder:NO controller:nil];

	XCTAssertEqual([loader mode], COImageLoaderModeArchive, @"archive extension was not recognized - see #38's note on CFBundleDocumentTypes/mainBundle in Logic Test Bundles");
	XCTAssertEqual([loader itemCount], 3);
	XCTAssertFalse([loader crypted]);
}

- (void)testEncryptedArchiveRequiresCorrectPassword
{
	NSString *archivePath = [self fixturePathForResource:@"sample_encrypted" ofType:@"zip"];
	COImageLoader *loader = [[COImageLoader alloc] initWithPath:archivePath readSubFolder:NO controller:nil];

	XCTAssertEqual([loader mode], COImageLoaderModeArchive);
	XCTAssertTrue([loader crypted]);
	XCTAssertFalse([loader checkPassword], @"no password set yet");

	XCTAssertFalse([loader checkAndSetPassword:@"wrong-password"]);
	XCTAssertTrue([loader checkAndSetPassword:@"testpassword123"]);
	XCTAssertTrue([loader checkPassword]);
}

#pragma mark - PDF mode

- (void)testPDFModeListsOnePagePerPage
{
	NSString *pdfPath = [self fixturePathForResource:@"sample" ofType:@"pdf"];
	COImageLoader *loader = [[COImageLoader alloc] initWithPath:pdfPath readSubFolder:NO controller:nil];

	XCTAssertEqual([loader mode], COImageLoaderModePDF);
	XCTAssertEqual([loader itemCount], 3);
}

#pragma mark - savedSearch mode

// A .savedSearch file's scope only makes sense as an absolute path fixed at
// test-run time, so it's synthesized here rather than checked in as a static
// fixture - the loader reads RawQuery/SearchCriteria.FXScopeArrayOfPaths
// straight out of the plist and hands them to MDQueryCreate/
// MDQuerySetSearchScope (see -[COImageLoader content:]'s savedSearch branch).
- (NSString *)makeSavedSearchFileScopedToDirectory:(NSString *)directory
{
	NSDictionary *doc = @{
		@"RawQuery": @"kMDItemFSName = '*.png'",
		@"SearchCriteria": @{@"FXScopeArrayOfPaths": @[directory]},
	};
	NSString *path = [directory stringByAppendingPathComponent:@"query.savedSearch"];
	XCTAssertTrue([doc writeToFile:path atomically:YES], @"failed to write .savedSearch fixture");
	return path;
}

// MDQueryExecute(kMDQuerySynchronous) only searches whatever mdworker has
// already indexed - it does not wait for indexing to catch up, and a
// directory created moments ago by this same test may not be searchable yet
// (more so on a fresh CI checkout, where Spotlight indexing can even be
// disabled entirely). Poll briefly for the index to catch up; skip (rather
// than fail) if it never does, since that reflects the test environment, not
// -[COImageLoader content:]'s own correctness.
- (void)testSavedSearchModeFindsScopedResults
{
	NSString *directory = [self makeTempDirectoryWithSampleImages];
	NSString *savedSearchPath = [self makeSavedSearchFileScopedToDirectory:directory];

	COImageLoader *loader = nil;
	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:3.0];
	do {
		loader = [[COImageLoader alloc] initWithPath:savedSearchPath readSubFolder:NO controller:nil];
		if ([loader itemCount] == 3) break;
		[NSThread sleepForTimeInterval:0.5];
	} while ([[NSDate date] compare:deadline] == NSOrderedAscending);

	if ([loader itemCount] != 3) {
		XCTSkip(@"Spotlight/mdworker hadn't indexed the fixture directory within 3s - inconclusive in this environment, not a loader failure");
	}
	XCTAssertEqual([loader mode], COImageLoaderModeSavedSearch);
}

@end
