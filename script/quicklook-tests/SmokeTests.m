#import <AppKit/AppKit.h>
#import <Quartz/Quartz.h>
#import <QuickLookThumbnailing/QuickLookThumbnailing.h>
#import "COComicArchive.h"

@interface COPreviewViewController : NSViewController <QLPreviewingController>
@property(readonly) NSImageView *imageView;
@property(readonly) COComicArchive *comic;
- (NSRect)displayedImageRect;
@end
@interface COThumbnailProvider : QLThumbnailProvider
@end
@interface COTestThumbnailRequest : NSObject
@property NSURL *fileURL;
@property CGSize maximumSize;
@property CGFloat scale;
@end
@implementation COTestThumbnailRequest
@end
static void check(BOOL ok, NSString *message) {
    if (!ok) { NSLog(@"FAIL: %@", message); exit(1); }
    printf("PASS: %s\n", message.UTF8String);
}
static BOOL waitFor(BOOL (^condition)(void)) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:15];
    while (!condition() && deadline.timeIntervalSinceNow > 0)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    return condition();
}
int main(int argc, const char **argv) {
    @autoreleasepool {
        setbuf(stdout, NULL);
        NSString *directory = @(argv[1]);
        NSURL *(^url)(NSString *) = ^NSURL *(NSString *name) {
            return [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:name]];
        };
        for (NSString *name in @[@"normal.cbz", @"normal.cbr", @"normal.zip", @"normal.rar", @"mixed.cbz", @"mixed.cbr", @"mixed.zip", @"mixed.rar"]) {
            NSError *error = nil;
            COComicArchive *comic = [[COComicArchive alloc] initWithURL:url(name) error:&error];
            check(comic.pageNames.count == 2 && [comic.pageNames[0] isEqual:@"page2.png"],
                  [name stringByAppendingString:@" natural order"]);
            NSImage *image = [comic imageAtPage:0 maxPixelSize:32 error:&error];
            check(image && MAX(image.size.width, image.size.height) <= 32, [name stringByAppendingString:@" bounded decode"]);
            check([comic imageAtPage:2 maxPixelSize:32 error:&error] == nil, @"out-of-range rejected");
        }
        NSError *error = nil;
        for (NSString *ext in @[@"cbz", @"cbr", @"zip", @"rar"]) {
            NSString *name = [@"fallback." stringByAppendingString:ext];
            COComicArchive *comic = [[COComicArchive alloc] initWithURL:url(name) error:&error];
            NSUInteger page = 0;
            check([comic firstReadableImageWithMaxPixelSize:128 page:&page error:&error] && page == 1,
                  [name stringByAppendingString:@" unreadable first image fallback"]);
            for (NSString *prefix in @[@"empty.", @"broken."]) {
                NSString *badName = [prefix stringByAppendingString:ext];
                error = nil;
                check(![[COComicArchive alloc] initWithURL:url(badName) error:&error] && error,
                      [badName stringByAppendingString:@" rejected with error"]);
            }
        }
        for (NSString *name in @[@"symlink.cbz", @"large-entry.cbz", @"many.cbz", @"large-archive.cbz", @"encrypted.cbz", @"encrypted.zip", @"cover.png"])
            check(![[COComicArchive alloc] initWithURL:url(name) error:&error], [name stringByAppendingString:@" rejected"]);
        COComicArchive *changed = [[COComicArchive alloc] initWithURL:url(@"changed.cbz") error:&error];
        NSMutableData *changedData = [NSMutableData dataWithContentsOfURL:url(@"changed.cbz")];
        [changedData appendBytes:"x" length:1];
        [changedData writeToURL:url(@"changed.cbz") atomically:YES];
        check(changed && ![changed imageAtPage:0 maxPixelSize:32 error:&error], @"file changed after enumeration rejected");
        COComicArchive *unsafe = [[COComicArchive alloc] initWithURL:url(@"unsafe.cbz") error:&error];
        BOOL safeNames = YES;
        for (NSString *name in unsafe.pageNames)
            if ([name hasPrefix:@"/"] || [name.pathComponents containsObject:@".."] || [name hasPrefix:@"."]) safeNames = NO;
        check(safeNames, @"unsafe archive paths rejected or sanitized by XAD (no disk extraction)");
        COThumbnailProvider *provider = [[COThumbnailProvider alloc] init];
        COTestThumbnailRequest *request = [[COTestThumbnailRequest alloc] init];
        request.maximumSize = CGSizeMake(256, 256);
        request.scale = 2;
        for (NSString *name in @[@"normal.cbz", @"normal.cbr", @"normal.zip", @"normal.rar",
                                  @"mixed.zip", @"mixed.rar", @"empty.zip", @"empty.rar", @"broken.cbz", @"broken.zip", @"broken.rar"]) {
            request.fileURL = url(name);
            __block BOOL thumbnailReady = NO;
            __block BOOL thumbnailOK = NO;
            [provider provideThumbnailForFileRequest:(QLFileThumbnailRequest *)request completionHandler:^(QLThumbnailReply *reply, NSError *err) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL expectError = [name hasPrefix:@"broken."] || [name hasPrefix:@"empty."];
                    thumbnailOK = expectError ? (!reply && err) : (reply && !err);
                    thumbnailReady = YES;
                });
            }];
            check(waitFor(^BOOL { return thumbnailReady; }) && thumbnailOK, [name stringByAppendingString:@" thumbnail provider callback"]);
        }
        // Single-image preview. Never decode a later readable image after success.
        for (NSString *name in @[@"normal.cbz", @"normal.cbr", @"normal.zip", @"normal.rar", @"mixed.zip", @"mixed.rar", @"quality.zip", @"many-pages.zip", @"large-image.zip", @"fallback.zip", @"fallback-many.zip"]) {
            COPreviewViewController *controller = [[COPreviewViewController alloc] init];
            __block BOOL ready = NO;
            __block NSError *previewError = nil;
            [controller preparePreviewOfFileAtURL:url(name) completionHandler:^(NSError *err) {
                previewError = err; ready = YES;
            }];
            check(waitFor(^BOOL { return ready; }) && !previewError && controller.imageView.image,
                  [name stringByAppendingString:@" single-image preview"]);
            NSUInteger expectedAttempts = [name hasPrefix:@"fallback"] ? 2 : 1;
            check(controller.comic.imageReadAttempts == expectedAttempts &&
                  controller.comic.imageDecodeAttempts == expectedAttempts && controller.comic.decodedImageCount == 1,
                  [name stringByAppendingString:@" stop after first successful decode"]);
            [controller viewDidLayout];
            NSRect displayed = controller.displayedImageRect;
            NSSize viewport = controller.view.bounds.size;
            check(displayed.size.height <= viewport.height && displayed.size.width <= viewport.width &&
                  displayed.size.height > viewport.height * .85, [name stringByAppendingString:@" large full-page fit"]);
            double ratio = controller.imageView.image.size.width / controller.imageView.image.size.height;
            check(fabs(displayed.size.width / displayed.size.height - ratio) < .002,
                  [name stringByAppendingString:@" aspect ratio preserved"]);
            check(controller.view.subviews.count == 1 && [controller.view.subviews.firstObject isKindOfClass:NSImageView.class],
                  [name stringByAppendingString:@" no PDF, page list or navigation controls"]);
            if ([name isEqual:@"quality.zip"]) {
                check(MAX(controller.imageView.image.size.width, controller.imageView.image.size.height) == 2400,
                      @"1600x2400 source retained instead of Finder thumbnail");

            }
            if ([name isEqual:@"large-image.zip"])
                check(MAX(controller.imageView.image.size.width, controller.imageView.image.size.height) <= 3072,
                      @"large source decode bounded to longest edge 3072");
        }
        for (NSString *name in @[@"empty.zip", @"empty.rar", @"broken.cbz", @"broken.zip", @"broken.rar"]) {
            COPreviewViewController *controller = [[COPreviewViewController alloc] init];
            __block BOOL ready = NO;
            __block NSError *previewError = nil;
            [controller preparePreviewOfFileAtURL:url(name) completionHandler:^(NSError *err) {
                previewError = err; ready = YES;
            }];
            check(waitFor(^BOOL { return ready; }) && previewError && !controller.imageView.image,
                  [name stringByAppendingString:@" preview completes with error"]);
        }
    }
    return 0;
}
