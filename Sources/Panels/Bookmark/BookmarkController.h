/* BookmarkController */

#import <Cocoa/Cocoa.h>
#import "Controller.h"
#import "BookmarkPanel.h"

@interface BookmarkController : NSObject
{
	IBOutlet Controller *controller;

	// Not CustomWindow, despite the XIB wiring it to one: -editBookmark:
	// reassigns this to whatever [NSApp keyWindow] currently is (to
	// restore focus after the sheet closes), which is plain NSWindow.
	IBOutlet NSWindow *window;
    IBOutlet BookmarkPanel *bookmarkPanel;
    IBOutlet NSTableView *bookmarkTableView;

    IBOutlet BookmarkPanel *allBookmarkPanel;
    IBOutlet NSTableView *allBookmarkTableView;
    IBOutlet NSTableView *allBookNameTableView;
    IBOutlet NSTextField *allNewBookmarkTextField;
	IBOutlet NSSplitView *allBookmarkSplitView;

    IBOutlet NSMenu *contextMenuItem;

    IBOutlet NSTextField *newBookmarkTextField;
    IBOutlet NSButton *deleteBookmarkButton;
    IBOutlet NSButton *deleteAllBookmarkButton;
    IBOutlet NSButton *addAllBookmarkButton;
    IBOutlet NSButton *openInSelfButton;
    IBOutlet NSButton *openInFinderButton;

	NSUserDefaults *defaults;
	NSMutableArray *bookmarkArray;
	NSMutableArray *sourceBookmarkArray;

	NSMutableDictionary *allBookmark;
	NSMutableArray *bookNameArray;
	
//	NSArray *names;
//	NSArray *pages;
//	NSArray *paths;
	NSString *directoryPath;
	NSString *bookName;

	NSMutableDictionary *completeAll;
}

- (void)setSplitViewPosition:(NSSplitView *)splitView position:(NSString *)position;

-(void)setPathDic:(NSDictionary*)dic;
-(void)editBookmark:(NSMutableArray*)array;
-(void)editAllBookmark:(NSMutableArray*)array;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

- (IBAction)deleteRow:(id)sender;
- (IBAction)deleteBookRow:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)addNewBookmark:(id)sender;
- (IBAction)openInFinder:(id)sender;
- (IBAction)openInSelf:(id)sender;
@end
