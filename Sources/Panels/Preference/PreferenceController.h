/* PreferenceController */

#import <Cocoa/Cocoa.h>
#import "Controller.h"
#import "COColorPopUpButton.h"
#import "COTextView.h"
#import "CustomWindow.h"
#import "AccessorySettingView.h"

@interface PreferenceController : NSObject
{
	int editedInputIndex;
	BOOL editMode;

	NSMutableDictionary *lastInput;
	NSMutableArray *currentKeyArray;
	NSMutableArray *currentMouseArray;

	NSMutableArray *keyArray;
	NSMutableArray *keyArrayMode2;
	NSMutableArray *keyArrayMode3;
	NSMutableArray *mouseArray;
	NSMutableArray *mouseArrayMode2;
	NSMutableArray *mouseArrayMode3;

	NSUserDefaults *defaults;

	IBOutlet NSPopUpButton *sortModePopUpButton;
	NSButton *sortDescendingButton;


	IBOutlet NSButton *changeOpenWithCheck;
	IBOutlet NSButton *changeCreatorCheck;

	IBOutlet NSButton *dontHideMenubarCheck;
	IBOutlet NSButton *showThumbnailCheck;

	IBOutlet NSTextField *imageCacheTextField;
	IBOutlet NSTextField *screenCacheTextField;
	IBOutlet NSTextField *thumbnailCacheTextField;

    IBOutlet NSPopUpButton *bufferingModePopUpButton;
    IBOutlet NSPopUpButton *canScrollActionPopUpButton;
    IBOutlet Controller *controller;
    IBOutlet NSPopUpButton *enlargePopUpButton;
    IBOutlet NSButton *fitOriginalCheck;
    IBOutlet NSTabView *inputTabView;
    IBOutlet NSTableView *inputTableView;
    IBOutlet NSPopUpButton *interpolationPopUpButton;
    IBOutlet NSPanel *keyConfigPanel;
    IBOutlet NSPopUpButton *keyModePopUpButton;
    IBOutlet NSPopUpButton *keyPanelPopUpButton;
	IBOutlet NSButton *keyPanelSwitchActionCheck;
    IBOutlet NSTextField *keyValueTextField;
    IBOutlet NSPopUpButton *loopPopUpButton;
    IBOutlet NSTextField *loupeSizeTextField;
    IBOutlet NSTextField *loupeRateTextField;
    IBOutlet NSPanel *mouseConfigPanel;
    IBOutlet NSPopUpButton *mouseModePopUpButton;
    IBOutlet NSPopUpButton *mousePanelActionPopUpButton;
    IBOutlet NSPopUpButton *mousePanelButtonPopUpButton;
    IBOutlet NSPopUpButton *mousePanelClickPopUpButton;
    IBOutlet NSButton *mousePanelControlCheck;
    IBOutlet NSButton *mousePanelOptionCheck;
    IBOutlet NSButton *mousePanelShiftCheck;
	IBOutlet NSButton *mousePanelSwitchActionCheck;
    IBOutlet NSTableView *mouseTableView;
    IBOutlet NSTextField *mouseValueTextField;
    IBOutlet NSButton *openLastFolderCheck;
    IBOutlet COColorPopUpButton *pageBarBGColor;
    IBOutlet COColorPopUpButton *pageBarBorderColor;
    IBOutlet COColorPopUpButton *pageBarReadedColor;
	IBOutlet NSButton *pageBarShowThumbCheck;
	IBOutlet NSButton *pageBarAutoHideCheck;
    IBOutlet COColorPopUpButton *pageColor;
    IBOutlet COColorPopUpButton *pageBGColor;
    IBOutlet COColorPopUpButton *pageBorderColor;
	IBOutlet NSButton *pageNumAutoHideCheck;
    IBOutlet NSPanel *preferences;
    IBOutlet NSPopUpButton *prevPageActionPopUpButton;
    IBOutlet NSButtonCell *readLeftButton;
    IBOutlet NSButtonCell *readRightButton;
    IBOutlet NSButton *readSingleCheckButton;
    IBOutlet NSButton *readSubFolderCheck;
    IBOutlet NSButton *rememberBookSettingsCheck;
    IBOutlet NSTextField *singleSettingTextField;
    IBOutlet NSSlider *slideshowSlider;
    IBOutlet NSTextField *slideshowTextField;
    IBOutlet NSTextField *thumbnailTextFieldCol;
    IBOutlet NSTextField *thumbnailTextFieldRow;
    IBOutlet NSSlider *wheelSlider;
    IBOutlet CustomWindow *window;
    IBOutlet COColorPopUpButton *viewBackGroundColor;
    IBOutlet NSButton *alwaysRememberLastCheck;
    IBOutlet NSTextField *numberOfOpenRecentTextField;

    IBOutlet NSTextField *fontTextField;
    IBOutlet NSTextField *pageBarFontTextField;
    IBOutlet COColorPopUpButton *pageBarFontColor;

    IBOutlet NSButton *showPageNumCheck;
    IBOutlet NSButton *showPageBarCheck;

    IBOutlet NSPanel *accessorySettingPanel;
    IBOutlet AccessorySettingView *accessorySettingView;


    IBOutlet COTextView *keyPanelTextView;

    IBOutlet NSPopUpButton *goToLastPopUpButton;

    IBOutlet NSPopUpButton *openLinkPopUpButton;

    IBOutlet NSPanel *disposeSettingPanel;
    IBOutlet NSProgressIndicator *disposeSettingProgress;

    IBOutlet NSPopUpButton *changeCurrentFolderPopUpButton;

    IBOutlet NSButton *useCalayerCheck;
}
+ (NSArray*)defaultKeyArray;
+ (NSArray*)defaultKeyArrayMode2;
+ (NSArray*)defaultKeyArrayMode3;
+ (NSArray*)defaultMouseArray;
+ (NSArray*)defaultMouseArrayMode2;
+ (NSArray*)defaultMouseArrayMode3;

+ (void)setDefaultKeyArray;
+ (void)setDefaultKeyArrayMode2;
+ (void)setDefaultKeyArrayMode3;
+ (void)setDefaultMouseArray;
+ (void)setDefaultMouseArrayMode2;
+ (void)setDefaultMouseArrayMode3;


- (void)preferences;

- (IBAction)showFontPanel:(id)sender;


- (IBAction)showPageBarFontPanel:(id)sender;
- (IBAction)changePageBarFontColor:(id)sender;
- (IBAction)changePageBarBGColor:(id)sender;

- (IBAction)changeFontColor:(id)sender;
- (IBAction)changeFontBGColor:(id)sender;
- (IBAction)keyConfig:(id)sender;
- (IBAction)keyConfigAction:(id)sender;
- (IBAction)keyConfigDelete:(id)sender;
- (IBAction)keyPanelCancel:(id)sender;
- (IBAction)keyPanelOk:(id)sender;
- (IBAction)keyPanelPopUpButtonAction:(id)sender;
- (IBAction)mouseConfig:(id)sender;
- (IBAction)mouseConfigDelete:(id)sender;
- (IBAction)mousePanelActionPopUpButtonAction:(id)sender;
- (IBAction)mousePanelCancel:(id)sender;
- (IBAction)mousePanelOk:(id)sender;
- (IBAction)selectedKeyMode:(id)sender;
- (IBAction)selectedMouseMode:(id)sender;
- (IBAction)setValueToSlider:(id)sender;
- (IBAction)sheetCancel:(id)sender;
- (IBAction)sheetOk:(id)sender;
- (IBAction)sliderMoved:(id)sender;
- (IBAction)changeBufferingMode:(id)sender;


- (IBAction)keyReset:(id)sender;
- (IBAction)mouseReset:(id)sender;

- (IBAction)dummyAction:(id)sender;

- (IBAction)disposeSettings:(id)sender;
- (IBAction)disposeSettingsCancel:(id)sender;

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;


	- (IBAction)setPosition:(id)sender;
	- (IBAction)resetPageNumberPosition:(id)sender;
	- (IBAction)resetPageBarPositionAndSize:(id)sender;
	- (IBAction)resetPageNumberAppearance:(id)sender;
	- (IBAction)resetPageBarAppearance:(id)sender;
	- (BOOL)inKeyEdit;
- (void)setKeyCharacters:(NSString*)characters;
@end
