/* BookmarkController */

#import <Cocoa/Cocoa.h>
#import "Controller.h"
#import "BookmarkPanel.h"

@interface BookmarkController : NSObject
{
	IBOutlet Controller *controller;

    IBOutlet BookmarkPanel *allBookmarkPanel;
    IBOutlet NSTableView *allBookmarkTableView;
    IBOutlet NSTableView *allBookNameTableView;
	IBOutlet NSSplitView *allBookmarkSplitView;

    IBOutlet NSMenu *contextMenuItem;

    IBOutlet NSButton *deleteAllBookmarkButton;
    IBOutlet NSButton *addAllBookmarkButton;
    IBOutlet NSButton *openInSelfButton;

	NSUserDefaults *defaults;

	NSMutableDictionary *allBookmark;
	NSMutableArray *bookNameArray;

	NSMutableDictionary *completeAll;
}

- (void)setSplitViewPosition:(NSSplitView *)splitView position:(NSString *)position;

// currentBookPath is the currently-open book's path (nil if none is open);
// when given, that book's row is pre-selected so its bookmarks show
// immediately -- this is the single entry point for both the "editing the
// open book" and "browsing every book's bookmarks" cases, which used to be
// two separate screens (see #57's design discussion for why they were merged).
-(void)editAllBookmark:(NSString*)currentBookPath;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

- (IBAction)deleteRow:(id)sender;
- (IBAction)deleteBookRow:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)addNewBookmark:(id)sender;
- (IBAction)openInFinder:(id)sender;
- (IBAction)openInSelf:(id)sender;
@end
