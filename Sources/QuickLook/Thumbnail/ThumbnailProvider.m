#import <os/log.h>
#import <QuickLookThumbnailing/QuickLookThumbnailing.h>
#import "COComicArchive.h"

@interface COThumbnailProvider : QLThumbnailProvider
@end
@implementation COThumbnailProvider
- (void)provideThumbnailForFileRequest:(QLFileThumbnailRequest *)request
                    completionHandler:(void (^)(QLThumbnailReply *, NSError *))handler {
    os_log(OS_LOG_DEFAULT, "cooViewer Quick Look thumbnail request");
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @autoreleasepool {
            NSError *error = nil;
            COComicArchive *comic = [[COComicArchive alloc] initWithURL:request.fileURL error:&error];
            NSImage *image = [comic firstReadableImageWithMaxPixelSize:
                (NSUInteger)ceil(MAX(request.maximumSize.width, request.maximumSize.height) * request.scale)
                page:NULL error:&error];
            if (!image) { handler(nil, error); return; }
            CGFloat factor = MIN(request.maximumSize.width / image.size.width,
                                 request.maximumSize.height / image.size.height);
            NSSize size = NSMakeSize(MAX(1, image.size.width * factor), MAX(1, image.size.height * factor));
            QLThumbnailReply *reply = [QLThumbnailReply replyWithContextSize:size currentContextDrawingBlock:^BOOL {
                [image drawInRect:(NSRect){NSZeroPoint, size} fromRect:NSZeroRect
                        operation:NSCompositingOperationSourceOver fraction:1.0];
                return YES;
            }];
            os_log(OS_LOG_DEFAULT, "cooViewer Quick Look thumbnail reply ready");
            handler(reply, nil);
        }
    });
}
@end
