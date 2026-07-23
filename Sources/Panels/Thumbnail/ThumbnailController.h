/* ThumbnailController */

#import <Cocoa/Cocoa.h>
#import "COImageLoader.h"
#import "Controller.h"
#import "ThumbnailMatrix.h"
#import "COPopUpTextField.h"

// Forward-declared, not #import-ed: ThumbnailPanel.h #imports this header
// (for its own typed target ivar), so importing it back here would race
// the #import include guards. All of -panel's use sites only call
// inherited NSPanel/NSWindow methods, so the forward declaration alone is
// enough - no separate #import is needed in ThumbnailController.m either.
@class ThumbnailPanel;

@interface ThumbnailController : NSObject
{
	BOOL bookmarkMode;
	int nowBookmarkPage;
		
	COImageLoader *imageLoader;
	
	
	int doCount;
	
	int cellCount;
	BOOL stop;
	BOOL mangaMode;
	
    IBOutlet Controller *controller;
    IBOutlet ThumbnailMatrix *matrix;
    IBOutlet ThumbnailPanel *panel;

	NSMutableArray *pathArray;
	int now;
	int sortMode;
    IBOutlet NSPopUpButton *sortPopUpButton;
	NSButton *sortDescendingButton;
    IBOutlet NSTextField *stateTextField;
    IBOutlet COPopUpTextField *nameTextField;
    IBOutlet NSButton *onlyBookmarkButton;
    IBOutlet NSButton *comicModeButton;
    IBOutlet NSMenu *contextMenu;
	
	NSArray *keyArray;
	
	NSMutableArray *thumImageArray;
	int maxCacheCount;
	
	float wheelSensitivity;
	NSTimer *wheelUpTimer,*wheelDownTimer;	
}
-(void)setmaxCacheCount:(int)size;
-(void)setImageLoader:(COImageLoader*)loader;

-(id)loadImage:(int)index;



-(void)showBookmarkThumbnail;
-(void)setBookmarkImageCells:(BOOL)back;
-(void)setBookmarkImageCellsMethod:(NSNumber*)backValue;
-(void)setBookmarkImageCellWithInfo:(id)infoDic;



-(BOOL)isVisible;

-(void)setCellRow:(int)rowI column:(int)columnI;

-(void)showThumbnail:(int)nowPage;
-(void)setImageCells:(BOOL)back;
-(void)setImageCellsMethod:(NSNumber*)backValue;
-(void)setImageCellWithInfo:(id)info;

-(void)setImageToCellAtRow:(int)row column:(int)col back:(BOOL)back;
-(void)setThumbnailControlsVisible:(BOOL)visible;

-(void)clearCell;
- (void)imageSelected:(id)sender;
-(void)appleRemoteAction:(NSString*)characters;
-(void)action:(NSEvent*)event;
-(void)wheelAction:(NSEvent*)event;
-(void)wheelSetting:(float)set;
-(void)wheelUp;
-(void)wheelDown;
-(void)setPageKey:(NSArray*)array;
-(IBAction)sort:(id)sender;
-(IBAction)next:(id)sender;
-(IBAction)prev:(id)sender;
-(void)mangaModePrev;


-(IBAction)onlyBookmark:(id)sender;
-(IBAction)comicMode:(id)sender;

-(IBAction)contextAction:(id)sender;
@end
