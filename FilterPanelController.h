//
//  FilterPanelController.h
//  cooViewer
//
//  Created by coo on 2020/01/11.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>

@interface FilterPanelController : NSObject
{
    IBOutlet id filterPanel;
    IBOutlet id scrollView;
    IBOutlet id popupButton;
    IBOutlet id contentsView;
    
    NSMutableDictionary *filterDic;
    NSMutableArray *selectedFilterKeys;
    NSMutableDictionary *selectedFilters;
    NSMutableDictionary *selectedFilterUIViews;
    NSMutableDictionary *controlViewsByIdentifier;
}
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (IBAction)openFilterPanel:(id)sender;
@end

@interface FilterPanelController(private)
- (void)ensureFilterPanelMinimumSize;
- (void)applyDebugPresetIfNeeded;
- (void)dumpDebugPanelIfNeeded;
- (void)setUserDefaults;
- (void)sendNotification;
@end
