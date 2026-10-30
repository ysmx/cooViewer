#import <os/log.h>
#import <Quartz/Quartz.h>
#import "COComicArchive.h"

@interface COThumbnailListView : NSView
@end
@implementation COThumbnailListView
- (BOOL)isFlipped { return YES; }
@end

@interface COPreviewViewController : NSViewController <QLPreviewingController>
@property NSImageView *imageView;
@property NSScrollView *sidebar;
@property COThumbnailListView *pageList;
@property NSMutableIndexSet *pendingThumbnails;
@property NSMutableIndexSet *completedThumbnails;
@property NSURL *previewURL;
@property BOOL previewReady;
@property BOOL thumbnailsVisible;
@property COComicArchive *comic;
@property NSArray<NSNumber *> *pageIndexes;
@property NSMutableArray<NSButton *> *pageButtons;
@property NSCache<NSNumber *, NSImage *> *imageCache;
@property dispatch_queue_t readerQueue;
@property dispatch_queue_t thumbnailQueue;
@property NSUInteger generation;
@property NSUInteger selectionGeneration;
@property NSUInteger selectedPage;
@property NSUInteger fullImageDecodeCount;
- (void)selectPageAtIndex:(NSUInteger)index;
- (void)loadVisibleThumbnails;
@end
@implementation COPreviewViewController
- (void)loadView {
    self.readerQueue = dispatch_queue_create("jp.coo.cooViewer.preview.pages", DISPATCH_QUEUE_SERIAL);
    self.thumbnailQueue = dispatch_queue_create("jp.coo.cooViewer.preview.thumbnails", DISPATCH_QUEUE_SERIAL);
    self.imageCache = [[NSCache alloc] init];
    self.imageCache.countLimit = 3;
    self.imageCache.totalCostLimit = 32 * 1024 * 1024;
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 900, 750)];
    self.imageView = [[NSImageView alloc] init];
    self.imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    self.imageView.imageAlignment = NSImageAlignCenter;
    [self.view addSubview:self.imageView];
    self.sidebar = [[NSScrollView alloc] init];
    self.sidebar.drawsBackground = NO;
    self.sidebar.contentView.drawsBackground = NO;
    self.sidebar.borderType = NSNoBorder;
    self.sidebar.hasVerticalScroller = YES;
    self.sidebar.autohidesScrollers = YES;
    self.pageList = [[COThumbnailListView alloc] init];
    self.sidebar.contentView.postsBoundsChangedNotifications = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarScrolled:)
        name:NSViewBoundsDidChangeNotification object:self.sidebar.contentView];
    self.sidebar.documentView = self.pageList;
    [self.view addSubview:self.sidebar];
    self.preferredContentSize = NSMakeSize(900, 750);
    [self viewDidLayout];
}
- (void)viewDidLayout {
    [super viewDidLayout];
    NSRect bounds = self.view.bounds;
    // Public QL APIs do not identify Finder's preview pane. Use compact layout
    // when there is insufficient room for both a readable image and a sidebar.
    BOOL showSidebar = bounds.size.width >= 600 && bounds.size.height >= 480 && self.pageButtons.count > 1;
    self.thumbnailsVisible = showSidebar;
    self.sidebar.hidden = !showSidebar;
    CGFloat width = showSidebar ? 124 : 0;
    self.imageView.frame = NSMakeRect(8, 8, MAX(0, bounds.size.width-width-(showSidebar ? 24 : 16)), MAX(0, bounds.size.height-16));
    self.sidebar.frame = NSMakeRect(bounds.size.width-width-8, 8, width, MAX(0,bounds.size.height-16));
    self.pageList.frame = NSMakeRect(0,0,width,MAX(self.sidebar.contentSize.height,self.pageButtons.count*142));
    for (NSUInteger i=0;i<self.pageButtons.count;i++) self.pageButtons[i].frame = NSMakeRect(12,i*142,100,136);
    [self loadVisibleThumbnails];
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)sidebarScrolled:(NSNotification *)notification { [self loadVisibleThumbnails]; }
- (void)loadVisibleThumbnails {
    if (!self.previewReady || !self.thumbnailsVisible) return;
    NSMutableArray<NSNumber *> *visible = [NSMutableArray array];
    NSRect rect = self.sidebar.documentVisibleRect;
    NSUInteger firstVisible = (NSUInteger)MAX(0, floor(NSMinY(rect) / 142.0));
    NSUInteger endVisible = MIN(self.pageButtons.count, (NSUInteger)ceil(NSMaxY(rect) / 142.0));
    for (NSUInteger i=firstVisible;i<endVisible;i++) {
        if (![self.completedThumbnails containsIndex:i] && ![self.pendingThumbnails containsIndex:i]) {
            [visible addObject:@(i)];
            [self.pendingThumbnails addIndex:i];
        }
    }
    if (!visible.count) return;
    NSUInteger generation = self.generation;
    NSArray<NSNumber *> *pages = self.pageIndexes;
    NSURL *url = self.previewURL;
    dispatch_async(self.thumbnailQueue, ^{
        @autoreleasepool {
            if (self.generation != generation) return;
            COComicArchive *reader = self.thumbnailsVisible ? [[COComicArchive alloc] initWithURL:url error:NULL] : nil;
            for (NSNumber *number in visible) {
                @autoreleasepool {
                    NSUInteger index = number.unsignedIntegerValue;
                    NSImage *thumbnail = nil;
                    if (self.generation == generation && self.thumbnailsVisible)
                        thumbnail = [reader imageAtPage:pages[index].unsignedIntegerValue maxPixelSize:160 error:NULL];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.generation != generation) return;
                        [self.pendingThumbnails removeIndex:index];
                        if (thumbnail) { self.pageButtons[index].image = thumbnail; [self.completedThumbnails addIndex:index]; }
                    });
                }
            }
        }
    });
}
- (void)pageClicked:(NSButton *)sender { [self selectPageAtIndex:(NSUInteger)sender.tag]; }
- (void)updateSelection:(NSUInteger)index image:(NSImage *)image {
    self.selectedPage = index;
    self.imageView.image = image;
    for (NSUInteger i=0;i<self.pageButtons.count;i++) self.pageButtons[i].state = i==index ? NSControlStateValueOn : NSControlStateValueOff;
}
- (void)selectPageAtIndex:(NSUInteger)index {
    if (index >= self.pageIndexes.count) return;
    NSUInteger selection = ++self.selectionGeneration;
    NSNumber *page = self.pageIndexes[index];
    NSImage *cached = [self.imageCache objectForKey:page];
    if (cached) { [self updateSelection:index image:cached]; return; }
    NSTimeInterval requested = NSProcessInfo.processInfo.systemUptime;
    NSUInteger generation = self.generation;
    COComicArchive *comic = self.comic;
    dispatch_async(self.readerQueue, ^{
        @autoreleasepool {
            NSError *error = nil;
            NSImage *image = [comic imageAtPage:page.unsignedIntegerValue maxPixelSize:1600 error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (generation != self.generation) return;
                if (image) {
                    self.fullImageDecodeCount++;
                    [self.imageCache setObject:image forKey:page cost:(NSUInteger)(image.size.width*image.size.height*4)];
                    if (selection == self.selectionGeneration) [self updateSelection:index image:image];
                } else {
                    self.pageButtons[index].enabled = NO;
                    self.pageButtons[index].toolTip = error.localizedDescription;
                }
                os_log(OS_LOG_DEFAULT,"cooViewer lazy page selected=%lu fullDecoded=%lu displayMs=%.3f",(unsigned long)index+1,(unsigned long)self.fullImageDecodeCount,(NSProcessInfo.processInfo.systemUptime-requested)*1000);
            });
        }
    });
}
- (void)preparePreviewOfFileAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))handler {
    (void)self.view;
    NSUInteger generation = ++self.generation;
    ++self.selectionGeneration;
    [self.imageCache removeAllObjects];
    self.previewReady = NO;
    self.previewURL = url;
    self.pendingThumbnails = [NSMutableIndexSet indexSet];
    self.completedThumbnails = [NSMutableIndexSet indexSet];
    self.imageView.image = nil;
    self.comic = nil;
    self.pageIndexes = @[];
    self.fullImageDecodeCount = 0;
    for (NSView *view in self.pageList.subviews.copy) { [view removeFromSuperview]; }
    self.pageButtons = [NSMutableArray array];
    dispatch_async(self.readerQueue, ^{
        @autoreleasepool {
            NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
            NSError *error = nil;
            COComicArchive *comic = [[COComicArchive alloc] initWithURL:url error:&error];
            NSUInteger first = 0;
            NSImage *image = [comic firstReadableImageWithMaxPixelSize:1600 page:&first error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (generation != self.generation) { handler([NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]); return; }
                if (!image) { handler(error); return; }
                self.comic = comic;
                NSMutableArray<NSNumber *> *pages = [NSMutableArray array];
                for (NSUInteger p=first;p<MIN(comic.pageNames.count,first+25);p++) [pages addObject:@(p)];
                self.pageIndexes = pages;
                self.fullImageDecodeCount = 1;
                [self.imageCache setObject:image forKey:@(first) cost:(NSUInteger)(image.size.width*image.size.height*4)];
                for (NSUInteger i=0;i<pages.count;i++) {
                    NSButton *button = [NSButton buttonWithTitle:@"" target:self action:@selector(pageClicked:)];
                    [button setButtonType:NSButtonTypeToggle];
                    button.bordered = NO;
                    ((NSButtonCell *)button.cell).showsStateBy = NSNoCellMask;
                    ((NSButtonCell *)button.cell).highlightsBy = NSNoCellMask;
                    button.imagePosition = NSImageOnly;
                    button.imageScaling = NSImageScaleProportionallyDown;
                    button.tag = (NSInteger)i;
                    [button setAccessibilityLabel:[NSString stringWithFormat:@"ページ%lu",(unsigned long)i+1]];
                    if (i==0) { button.image = image; [self.completedThumbnails addIndex:0]; }
                    [self.pageList addSubview:button];
                    [self.pageButtons addObject:button];
                }
                [self updateSelection:0 image:image];
                [self viewDidLayout];
                os_log(OS_LOG_DEFAULT,"cooViewer lazy view preview pages=%lu candidates=%lu initialDecoded=1 readyMs=%.3f",(unsigned long)pages.count,(unsigned long)comic.pageNames.count,(NSProcessInfo.processInfo.systemUptime-start)*1000);
                handler(nil);
                self.previewReady = YES;
                [self.sidebar.contentView scrollToPoint:NSZeroPoint];
                [self.sidebar reflectScrolledClipView:self.sidebar.contentView];
                [self loadVisibleThumbnails];
            });
        }
    });
}
@end
