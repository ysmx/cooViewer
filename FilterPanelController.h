//
//  FilterPanelController.h
//  cooViewer
//
//  Created by coo on 2020/01/11.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>

@interface FilterPanelController : NSObject <NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate>
{
    IBOutlet id filterPanel;
    IBOutlet id scrollView;
    IBOutlet id popupButton;
    IBOutlet id contentsView;
    
    NSMutableDictionary *filterDic;
    NSMutableArray *selectedFilterKeys;
    NSMutableDictionary *selectedFilters;
    NSMutableDictionary *selectedFilterUIViews;
    NSMutableSet *collapsedFilterKeys;

    NSView *toolbarView;
    NSButton *addFilterButton;
    NSTextField *toolbarTitleLabel;
    NSTextField *toolbarHintLabel;

    NSPanel *filterPickerPanel;
    NSSearchField *filterSearchField;
    NSScrollView *filterPickerScrollView;
    NSTableView *filterTableView;
    NSArray *availableFilterEntries;
    NSArray *filteredFilterEntries;
    NSArray *filterPickerDisplayItems;
    CGFloat _lastLayoutContentWidth;
}
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (IBAction)openFilterPanel:(id)sender;
@end

@interface FilterPanelController(private)
- (void)ensureFilterPanelMinimumSize;
- (void)applyDebugPresetIfNeeded;
- (void)dumpDebugPanelIfNeeded;
- (void)dumpDebugFilterPickerIfNeeded;
- (void)setUserDefaults;
- (void)sendNotification;
@end
