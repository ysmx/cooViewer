/* Controller */

#import <Cocoa/Cocoa.h>
#import "ThumbnailController.h"
#import "BookmarkController.h"
#import "PreferenceController.h"
#import "NSString_Compare.h"

#import "COImageLoader.h"

#import "AppleRemote.h"
#import "MultiClickRemoteBehavior.h"

@class RemoteControl;
@class MultiClickRemoteBehavior;

@interface Controller : NSObject
{
	RemoteControl *remoteControl;
	MultiClickRemoteBehavior* remoteControlBehavior;
	
	NSMutableDictionary *currentBookSetting;
	int threadCount;
	//NSMutableArray *recentItems;
	//NSMutableDictionary *bookSettings;
	
	
	int sortMode;
	int preShuffleSortMode;  // sort mode to restore when shuffle is deactivated
	BOOL sortDescending;
	BOOL threadStop;
	int cacheSize;
	NSMutableArray *cacheArray;
	int screenCache;
	NSMutableArray *screenCacheArray;
	
	//NSWindow *accWindow;
	IBOutlet id progressIndicator;
	int rotateMode;
	IBOutlet id openRecentMenuItem;	
	
	BOOL alwaysRememberLastPage;
	
	
	int goToLastPageMode;
	int openLinkMode;
	int openRecentLimit;
	int changeCurrentFolderMode;
	
	COImageLoader *imageLoader;
	
	IBOutlet id prefController;	
	
	int bufferingMode;
	
	
	int interpolation;
	
	NSMutableArray *marksArray;
	BOOL rememberBookSettings;
	
	
	BOOL pageBar;
	
	NSDictionary *lastInput;
	
	NSMutableArray *keyArray;
	NSMutableArray *keyArrayMode2;
	NSMutableArray *keyArrayMode3;
	NSMutableArray *mouseArray;
	NSMutableArray *mouseArrayMode2;
	NSMutableArray *mouseArrayMode3;
	
	int readMode;
	
	
	
	
	IBOutlet id thumController;
	
	float wheelSensitivity;

	
	int singleSetting;
	
	NSTimer *wheelUpTimer;
	NSTimer *wheelDownTimer;
	IBOutlet id bookmarkController;
	BOOL readSubFolder;
	
    IBOutlet id normalWindow;
	
	int loopCheck;
	
	IBOutlet id fullImagePanel;
    IBOutlet id fullImageView;
	
	
	IBOutlet id openSameFolderMenuItem;
	
	
	IBOutlet id passPanel;
    IBOutlet id passTextField;
	
    //IBOutlet id pageTextField;
	
    IBOutlet id imageView;
    IBOutlet id window;
	
	int maxEnlargement;
	
    IBOutlet id bookmarkMenuItem;
	
	
	NSUserDefaults *defaults;
	BOOL timerSwitch;
	//BOOL loopSwitch;
	BOOL numberSwitch;
	BOOL fitMode;
	
	
	NSTimer *timer;
	
	
	float sliderValue;
	int nowPage;
	
	
	//NSRect fullscreenRect;
	//NSRect leftRect;
	//NSRect rightRect;
	NSData *currentBookAlias;
	NSString *currentBookPath;
	NSString *currentBookName;
	
	NSData *oldBookAlias;
	NSString *oldBookPath;
	NSString *oldBookName;
	
	NSMutableArray *completeMutableArray;
	NSMutableArray *imageMutableArray;
	//id imageMutableArray;
	
	NSMutableArray *bookmarkArray;

	
	
	//NSConditionLock *lock;
	NSLock *lock;
	
	NSImage *composedImage;
	BOOL useComposedImage;
	
	NSImage *firstImage,*secondImage;
	
	int fitScreenMode;
	
	int prevPageMode;
	int canScrollMode;
	
	NSDate *lastSameFolderMenuUpdate;
	BOOL pendingViewerActivation;
	BOOL restoreFullscreenDeactivateState;
	unsigned long openPageLoadSequence;
	NSMutableArray *archiveNavigationStack;
	
}
- (void)awakeFromNib;

- (void)setupRemoteControl;

- (IBAction)openTheLastPage:(id)sender;
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
- (IBAction)open:(id)sender;
- (void)openFromSameDir:(id)sender;
- (void)openFromSameDir:(id)sender last:(BOOL)isLast;
- (void)openFromOpenRecent:(id)sender;
- (void)openPage:(int)page last:(BOOL)last;
- (BOOL)isCurrentOpenPageLoadSequence:(NSNumber *)sequenceNumber;

- (void)askInArchivePassword:(COImageLoader*)loader;
- (IBAction)sheetCancel:(id)sender;
- (IBAction)sheetOk:(id)sender;


- (NSImage*)loadThumbnailImage:(int)index;
- (NSImage*)loadImage:(int)index;
- (void)lookahead;
- (void)lookaheadAndCompose;


- (BOOL)isSmallImage:(NSImage *)image page:(int)page;
- (NSImage *)returnComposeImage:(NSImage *)image1 and:(NSImage *)image2;
- (void)composeImage;


- (BOOL)imageDisplayIfHasScreenCache;
- (void)imageDisplay;
- (void)lockedImageDisplay;


- (IBAction)preferences:(id)sender;
- (void)setPreferences;
- (void)strongSetBookmark;

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (void)setBookmarkMenu;
- (void)setSameFolderMenu;
- (void)setSameFolderMenu:(BOOL)force;
- (void)setOpenRecentMenu;
- (IBAction)clearRecent:(id)sender;


- (void)setPageTextField;
- (NSString*)pageTextFieldString;
- (IBAction)changeReadModeMenu:(id)sender;
- (IBAction)changeSortModeMenu:(id)sender;
- (void)goBookmark:(id)sender;
- (IBAction)editBookmark:(id)sender;
- (IBAction)deleteSettings:(id)sender;


- (IBAction)fitToScreen:(id)sender;
- (IBAction)fitToScreenWidth:(id)sender;
- (IBAction)fitToScreenWidthDivide:(id)sender;
- (IBAction)noScale:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)rotateLeft:(id)sender;
- (IBAction)showFilterPanel:(id)sender;


- (IBAction)fullscreen:(id)sender;
- (BOOL)isSlideshowRunning;
- (void)refreshSecondaryDisplayCoverWindows;
- (void)viewSet;
- (void)windowWillClose:(NSNotification *)aNotofication;
- (void)applicationWillTerminate:(NSNotification *)notification;


- (void)viewDidEndLiveResize:(NSNotification *)aNotification;
- (void)windowDidResize:(NSNotification *)aNotification;

- (void)openLink:(NSURL *)url;
- (NSString*)archivePathForDisplayedImageAtIndex:(int)displayedImageIndex;
- (int)restorePageForCurrentDisplay;
- (BOOL)openArchiveAtCurrentMouseLocation;
- (BOOL)openArchiveAtPath:(NSString*)path;
- (BOOL)openArchiveAtPath:(NSString*)path restorePage:(int)restorePage;
- (BOOL)restorePreviousArchiveNavigation;

- (int)maxEnlargement;
- (int)readMode;
- (BOOL)readFromLeft;
- (BOOL)firstImage;
- (id)image1;
- (id)image2;
- (BOOL)indicator;
- (float)nowPar;
- (int)nowPage;
- (int)co_firstImagePageIndex;
- (int)co_secondImagePageIndex;
- (int)pageCount;
- (NSArray*)bookmarkArray;
- (id)openSameFolderMenuItem;
- (int)sortMode;
- (BOOL)sortDescending;
- (int)openLinkMode;



- (NSString*)pathFromAliasData:(NSData*)data;
- (NSData*)aliasDataFromPath:(NSString*)path;

- (AliasHandle)aliasFromPath:(NSString *)fullPath;
- (NSData *)dataFromAlias:(AliasHandle)alias;
- (NSString *)pathFromAlias:(AliasHandle)alias;
- (AliasHandle)aliasFromData:(NSData*)data;


- (id)searchFromBookSettings:(NSString*)path key:(NSString**)key;
- (id)searchFromRecentItems:(NSString*)path index:(int*)index;
- (id)searchFromLastPages:(NSString*)path index:(int*)index;

- (id)searchFromBookSettings:(NSString*)path key:(NSString**)key more:(BOOL)b;
/*
- (id)searchFromRecentItems:(NSString*)path index:(int*)index more:(BOOL)b;
- (id)searchFromLastPages:(NSString*)path index:(int*)index more:(BOOL)b;
*/
@end

@interface Controller (Input)
- (void)timeredRemoteButtonEvent:(NSString*)characters;
- (void)keyAction:(NSEvent*)sender;
- (BOOL)getKeyAction:(unichar)character mod:(int)cMod mode:(int)mode slideshow:(BOOL)slideshow;
- (void)mouseAction:(NSEvent*)sender;
- (void)gestureAction:(NSEvent*)sender moved:(int)moved;
- (void)multiTouchAction:(NSEvent*)sender action:(int)action;
- (BOOL)getMouseAction:(int)button mod:(int)cMod mode:(int)mode left:(BOOL)left;
- (IBAction)contextAction:(id)sender;
- (void)wheelAction:(NSEvent*)event;

// Looks up rootMenu>parentTitle>itemTitle and performs it if enabled - shared
// by the key/mouse action switches for openTheLastPage/switchFullScreen/minimizeWindow.
+ (void)co_performMenuActionInMenu:(NSMenu*)rootMenu parentTitle:(NSString*)parentTitle itemTitle:(NSString*)itemTitle;

// Shared by the key/mouse action switches' PageUp/PageDown/ScrollToTop/
// ScrollToEnd/Scroll*/boundary-triggered-page-turn cases.
- (void)co_performPageUp;
- (void)co_performPageDown;
- (void)co_performPageUpAndPrevPage;
- (void)co_performPageDownAndNextPage;
- (void)co_performScrollToTop;
- (void)co_performScrollToEnd;
- (void)co_performScrollWithValue:(int)value dx:(int)dx dy:(int)dy;

// Shared by the key/mouse action switches' changeViewMode/enlargeViewMode/
// reduceViewMode and loupeRatePlus/loupeRateMinus cases. direction matches
// ViewerFitScreenDirection's raw values (0=cycle, 1=enlarge, 2=reduce) -
// declared as a plain int here rather than the Swift enum type so this
// header stays importable from targets without cooViewer's generated
// Swift header (e.g. cooViewerTests).
- (void)co_performFitScreenTransition:(int)direction;
- (void)co_performLoupeRatePlus:(float)value;
- (void)co_performLoupeRateMinus:(float)value;

// Shared by the key/mouse action switches' switchSingle/shownumber/
// showThumbnail/changeReadMode/showPageBar/origRight/origLeft/
// showInFinderR/showInFinderL cases.
- (void)co_performSwitchSingle;
- (void)co_performShowNumber;
- (void)co_performShowThumbnail;
- (void)co_performChangeReadMode;
- (void)co_performShowPageBar;
- (void)co_performOrigRight;
- (void)co_performOrigLeft;
- (void)co_performShowInFinderRight;
- (void)co_performShowInFinderLeft;

- (void)goToPar:(float)par;
- (void)addBookmark;
- (BOOL)isBookmarkedPage:(int)page;
- (BOOL)removeBookmark;
- (void)goTo:(int)page array:(NSArray*)array;
- (void)nextFolder;
- (void)backFolder;
- (void)backFolderLast;
- (void)nextBookmark;
- (void)backBookmark;
- (void)showThumbnail;
- (void)prevPage;
- (void)halfprevPage;
- (void)goToLast;
- (void)goToFirst;
- (void)changeReadMode:(int)mode;
- (void)setSortMode:(int)mode page:(int)p;
- (void)setSortDescending:(BOOL)descending page:(int)p;
- (IBAction)switchSingle:(id)sender;

- (IBAction)viewAtOriginalSizeFirst:(id)sender;
- (IBAction)viewAtOriginalSizeSecond:(id)sender;
- (IBAction)showInFinderFirst:(id)sender;
- (IBAction)showInFinderSecond:(id)sender;

- (void)switchBindWithPage:(int)page;
- (void)switchSingleWithPage:(int)page;
- (void)addBookmarkWithPage:(int)page;
- (BOOL)removeBookmarkWithPage:(int)page;

- (void)nextSubFolder;
- (void)prevSubFolder;

- (void)trashLeft;
- (void)trashRight;
- (void)trashFile:(NSString*)path;

/*
- (IBAction)nextFolder:(id)sender;
- (IBAction)addBookmark:(id)sender;
- (IBAction)backFolder:(id)sender;
- (IBAction)nextBookmark:(id)sender;
- (IBAction)backBookmark:(id)sender;
- (IBAction)showThumbnail:(id)sender;
*/

- (IBAction)slideshow:(id)sender;

- (void)nextOriginal;
- (void)prevOriginal;
@end

@interface Controller(private)
-(void)setCurrentBookPath:(NSString *)new;
-(void)setOldBookPath;
-(void)setCurrentBookPathAndOldBookPath:(NSString *)new;
-(void)checkCurrentFolderUpdated;
@end
