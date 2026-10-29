#import <os/log.h>
#import <Quartz/Quartz.h>
#import "COComicArchive.h"

@interface COPreviewViewController : NSViewController <QLPreviewingController>
@property NSImageView *imageView;
@property COComicArchive *comic;
@property NSUInteger generation;
@property dispatch_queue_t readerQueue;
- (NSRect)displayedImageRect;
@end
@implementation COPreviewViewController
- (void)loadView {
    self.readerQueue = dispatch_queue_create("jp.coo.cooViewer.preview.reader", DISPATCH_QUEUE_SERIAL);
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 900, 750)];
    self.imageView = [[NSImageView alloc] initWithFrame:NSInsetRect(self.view.bounds, 8, 8)];
    self.imageView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    self.imageView.imageAlignment = NSImageAlignCenter;
    [self.view addSubview:self.imageView];
    self.preferredContentSize = NSMakeSize(900, 750);
}
- (void)viewDidLayout {
    [super viewDidLayout];
    NSRect viewport = NSInsetRect(self.view.bounds, 8, 8);
    if (!NSEqualRects(self.imageView.frame, viewport)) self.imageView.frame = viewport;
}
- (NSRect)displayedImageRect {
    NSSize size = self.imageView.image.size;
    NSRect bounds = self.imageView.frame;
    if (size.width <= 0 || size.height <= 0) return NSZeroRect;
    CGFloat scale = MIN(bounds.size.width / size.width, bounds.size.height / size.height);
    NSSize fitted = NSMakeSize(size.width * scale, size.height * scale);
    return NSMakeRect(NSMidX(bounds) - fitted.width / 2, NSMidY(bounds) - fitted.height / 2,
                      fitted.width, fitted.height);
}
- (void)preparePreviewOfFileAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))handler {
    os_log(OS_LOG_DEFAULT, "cooViewer Quick Look single-image preview request");
    (void)self.view;
    NSUInteger generation = ++self.generation;
    self.imageView.image = nil;
    self.comic = nil;
    dispatch_async(self.readerQueue, ^{
        @autoreleasepool {
            NSTimeInterval started = NSProcessInfo.processInfo.systemUptime;
            NSError *error = nil;
            COComicArchive *comic = [[COComicArchive alloc] initWithURL:url error:&error];
            NSUInteger firstPage = 0;
            // This stops immediately on the first readable candidate. No later page,
            // PDF conversion, JPEG re-encoding, page list or page-navigation work.
            NSImage *image = [comic firstReadableImageWithMaxPixelSize:3072 page:&firstPage error:&error];
            os_log(OS_LOG_DEFAULT, "cooViewer single-image prepared candidates=%lu reads=%lu decodeAttempts=%lu decoded=%lu enumerationMs=%.3f totalMs=%.3f",
                (unsigned long)comic.pageNames.count, (unsigned long)comic.imageReadAttempts,
                (unsigned long)comic.imageDecodeAttempts, (unsigned long)comic.decodedImageCount,
                comic.enumerationSeconds * 1000, (NSProcessInfo.processInfo.systemUptime - started) * 1000);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (generation == self.generation) {
                    self.comic = comic;
                    self.imageView.image = image;
                    [self viewDidLayout];
                }
                handler(image ? nil : error);
            });
        }
    });
}
@end
