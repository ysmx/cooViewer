#import <AppKit/AppKit.h>
#import <Quartz/Quartz.h>
#import <QuickLookThumbnailing/QuickLookThumbnailing.h>
#import "COComicArchive.h"

@interface COPreviewViewController : NSViewController <QLPreviewingController>
@property(readonly) NSImageView *imageView;
@property(readonly) COComicArchive *comic;
@property(readonly) NSArray<NSNumber *> *pageIndexes;
@property(readonly) NSArray<NSButton *> *pageButtons;
@property(readonly) NSScrollView *sidebar;
@property(readonly) NSView *pageList;
- (void)loadVisibleThumbnails;
@property(readonly) NSUInteger selectedPage;
@property(readonly) NSUInteger fullImageDecodeCount;
- (void)selectPageAtIndex:(NSUInteger)index;
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
        for (NSString *name in @[@"symlink.cbz", @"large-entry.cbz", @"many.cbz", @"encrypted.cbz", @"encrypted.zip", @"oversized-wrapper.tgz", @"cover.png"])
            check(![[COComicArchive alloc] initWithURL:url(name) error:&error], [name stringByAppendingString:@" rejected"]);
        for (NSString *name in @[@"normal.tar", @"normal.tgz", @"normal.tbz2", @"normal.txz", @"normal.7z", @"normal.jar", @"normal.pax", @"normal.cpio", @"page.png.gz", @"page.png.bz2", @"page.png.xz", @"over-256MiB.zip"]) {
            NSError *formatError = nil;
            COComicArchive *archive = [[COComicArchive alloc] initWithURL:url(name) error:&formatError];
            NSImage *cover = [archive firstReadableImageWithMaxPixelSize:128 page:NULL error:&formatError];
            check(cover && archive.decodedImageCount == 1, [name stringByAppendingString:@" first image without total-size cap"]);
        }
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
        for (NSString *name in @[@"normal.cbz", @"normal.cbr", @"normal.zip", @"normal.rar", @"normal.tar", @"normal.tgz", @"normal.tbz2", @"normal.txz", @"normal.7z", @"normal.jar", @"normal.cpio", @"normal.pax", @"page.png.gz", @"page.png.bz2", @"page.png.xz", @"over-256MiB.zip",
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
        for (NSString *name in @[@"normal.cbz", @"normal.cbr", @"normal.zip", @"normal.rar", @"quality.zip", @"many-pages.zip", @"fallback.zip", @"large-image.zip"]) {
            NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
            COPreviewViewController *controller = [[COPreviewViewController alloc] init];
            __block BOOL ready = NO;
            __block NSError *previewError = nil;
            [controller preparePreviewOfFileAtURL:url(name) completionHandler:^(NSError *error) { previewError=error;ready=YES; }];
            check(waitFor(^BOOL { return ready; }) && !previewError && controller.imageView.image,
                  [name stringByAppendingString:@" view preview ready"]);
            NSUInteger count = [name isEqual:@"many-pages.zip"] ? 25 : [name isEqual:@"fallback.zip"] ? 1 : 2;
            check(controller.pageIndexes.count==count && controller.pageButtons.count==count,
                  [name stringByAppendingString:@" at most twenty-five sidebar pages"]);
            check(controller.fullImageDecodeCount==1 && controller.comic.decodedImageCount==1,
                  [name stringByAppendingString:@" only one full image initially decoded"]);
            check(MAX(controller.imageView.image.size.width,controller.imageView.image.size.height)<=1600,
                  [name stringByAppendingString:@" full image bounded to 1600 pixels"]);
            check(controller.preferredContentSize.width==900 && controller.preferredContentSize.height==750 && controller.imageView.frame.size.height>700,
                  [name stringByAppendingString:@" original fixed layout and full-height image area"]);
            printf("Lazy view ready %s: %.3f ms fullDecoded=%lu\n",name.UTF8String,(NSProcessInfo.processInfo.systemUptime-start)*1000,(unsigned long)controller.fullImageDecodeCount);
            if(count==25) {
                check(waitFor(^BOOL { return controller.pageButtons[1].image.size.width > 1; }), @"visible sidebar thumbnails generated");
                check(controller.pageButtons[24].image.size.width <= 1, @"offscreen page 25 thumbnail is not generated initially");
                printf("Lazy visible sidebar ready %s: %.3f ms\n",name.UTF8String,(NSProcessInfo.processInfo.systemUptime-start)*1000);
            }
            if(count>1) {
                NSTimeInterval selected = NSProcessInfo.processInfo.systemUptime;
                [controller selectPageAtIndex:1];
                check(waitFor(^BOOL { return controller.selectedPage==1; }) && controller.fullImageDecodeCount==2,
                      [name stringByAppendingString:@" sidebar selection loads requested page"]);
                printf("Lazy page 2 %s: %.3f ms\n",name.UTF8String,(NSProcessInfo.processInfo.systemUptime-selected)*1000);
                selected = NSProcessInfo.processInfo.systemUptime;
                [controller selectPageAtIndex:0];
                check(controller.selectedPage==0 && controller.fullImageDecodeCount==2,
                      [name stringByAppendingString:@" cached page avoids redecoding"]);
                printf("Lazy cached page %s: %.3f ms\n",name.UTF8String,(NSProcessInfo.processInfo.systemUptime-selected)*1000);
            }
            if(count==25) {
                NSTimeInterval selected = NSProcessInfo.processInfo.systemUptime;
                [controller selectPageAtIndex:4];
                check(waitFor(^BOOL { return controller.selectedPage==4; }) && controller.fullImageDecodeCount==3,
                      @"fifth page loads without decoding intervening full images or last page");
                printf("Lazy page 5 %s: %.3f ms\n",name.UTF8String,(NSProcessInfo.processInfo.systemUptime-selected)*1000);
                check(controller.comic.imageReadAttempts==3,@"thumbnail work independent of full-image reads");
                NSClipView *clip = controller.sidebar.contentView;
                [clip scrollToPoint:NSMakePoint(0,MAX(0,controller.pageList.frame.size.height-clip.bounds.size.height))];
                [controller loadVisibleThumbnails];
                check(waitFor(^BOOL { return controller.pageButtons[24].image.size.width > 1; }),@"scrolling generates page 25 thumbnail on demand");
                [controller selectPageAtIndex:24];
                check(waitFor(^BOOL { return controller.selectedPage==24; }) && controller.fullImageDecodeCount==4,@"page 25 full image loads only when selected");
            }
            [controller selectPageAtIndex:99];
            check(controller.selectedPage<count,@"out-of-range sidebar selection ignored");
        }
        COPreviewViewController *compact = [[COPreviewViewController alloc] init];
        compact.view.frame = NSMakeRect(0,0,300,360);
        [compact viewDidLayout];
        __block BOOL compactReady=NO;
        [compact preparePreviewOfFileAtURL:url(@"many-pages.zip") completionHandler:^(NSError *error){compactReady=!error;}];
        check(waitFor(^BOOL{return compactReady;}) && compact.sidebar.hidden,@"compact Finder-style pane hides sidebar");
        check(compact.comic.imageReadAttempts==1 && compact.fullImageDecodeCount==1,@"compact pane reads only the first full image");
        BOOL noExtraThumbnails=YES;
        for(NSUInteger i=1;i<compact.pageButtons.count;i++) if(compact.pageButtons[i].image.size.width > 1) noExtraThumbnails=NO;
        check(noExtraThumbnails,@"compact pane does not generate sidebar thumbnails");
        for (NSString *name in @[@"empty.zip", @"broken.rar"]) {
            COPreviewViewController *controller = [[COPreviewViewController alloc] init];
            __block BOOL ready=NO; __block NSError *error=nil;
            [controller preparePreviewOfFileAtURL:url(name) completionHandler:^(NSError *e){error=e;ready=YES;}];
            check(waitFor(^BOOL{return ready;}) && error && !controller.imageView.image,
                  [name stringByAppendingString:@" view preview error callback"]);
        }

    }
    return 0;
}
