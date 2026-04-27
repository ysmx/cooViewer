//
//  FilterPanelController.m
//  cooViewer
//
//  Created by coo on 2020/01/11.
//

#import "FilterPanelController.h"

static const NSInteger kFilterLabelTag = 1001;
static const NSInteger kFilterCloseButtonTag = 1002;
static const NSInteger kFilterDisclosureButtonTag = 1003;
static const NSInteger kFilterResetButtonTag = 1004;
static const CGFloat kFilterLabelHeight = 20.0;
static const CGFloat kFilterPanelDefaultContentWidth = 340.0;
static const CGFloat kFilterItemSpacing = 12.0;
static const CGFloat kFilterPanelOuterPadding = 8.0;
static const CGFloat kFilterTopBarHeight = 56.0;
static const CGFloat kFilterTopBarInnerPadding = 10.0;
static const CGFloat kFilterPanelChromeHeight = 78.0;
static const CGFloat kFilterCardHorizontalPadding = 14.0;
static const CGFloat kFilterCardVerticalPadding = 12.0;
static const CGFloat kFilterCardHeaderHeight = 30.0;
static const CGFloat kFilterCardButtonInset = 10.0;
static const CGFloat kFilterCardContentSpacing = 10.0;
static const CGFloat kFilterPickerWidth = 320.0;
static const CGFloat kFilterPickerSearchHeight = 28.0;
static const CGFloat kFilterPickerHorizontalInset = 16.0;
static const CGFloat kFilterPickerVerticalInset = 16.0;
static const CGFloat kFilterPickerTopGap = 10.0;
static const CGFloat kFilterPickerMinVisibleRows = 5.0;
static const CGFloat kFilterPickerMaxVisibleRows = 10.0;
static NSString * const kFilterPickerSavedHeightDefaultsKey = @"FilterPickerPanelHeight";
static const CGFloat kFilterPanelMinContentHeight = 160.0;
static const CGFloat kFilterPickerRowHeight = 24.0;
static const CGFloat kFilterPickerHeaderHeight = 18.0;
static const CGFloat kFilterPickerSeparatorHeight = 8.0;
static const CGFloat kFilterPickerPanelGap = 8.0;

static void *kFilterObserverContext = &kFilterObserverContext;

@interface COVFilterPickerTableView : NSTableView
@end

@implementation COVFilterPickerTableView
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}
@end

@interface COVFilterBorderView : NSView
@end

@implementation COVFilterBorderView
- (BOOL)isOpaque
{
    return NO;
}
- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    NSRect borderRect = NSInsetRect([self bounds], 0.5, 0.5);
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:borderRect xRadius:4.0 yRadius:4.0];
    [[NSColor colorWithCalibratedWhite:0.18 alpha:0.92] setFill];
    [borderPath fill];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.14] setStroke];
    [borderPath stroke];
}
@end

@interface COVToolbarButton : NSButton
@end

@implementation COVToolbarButton
- (BOOL)isOpaque
{
    return NO;
}
- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = NSInsetRect([self bounds], 0.5, 0.5);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:9.0 yRadius:9.0];
    NSColor *fillColor = ([self isHighlighted]
                          ? [NSColor colorWithCalibratedRed:0.30 green:0.55 blue:1.0 alpha:0.92]
                          : [NSColor colorWithCalibratedRed:0.24 green:0.48 blue:0.96 alpha:0.90]);
    [fillColor setFill];
    [path fill];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.14] setStroke];
    [path stroke];
    [super drawRect:dirtyRect];
}
@end

static NSArray *COVDebugFilterNamesFromPresetString(NSString *preset)
{
    if ([preset length] == 0) {
        return nil;
    }

    NSMutableArray *filters = [NSMutableArray array];
    NSEnumerator *enumerator = [[preset componentsSeparatedByString:@","] objectEnumerator];
    NSString *component;
    while (component = [enumerator nextObject]) {
        NSString *trimmed = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([trimmed length] > 0) {
            [filters addObject:trimmed];
        }
    }
    if ([filters count] == 0) {
        return nil;
    }
    return filters;
}

static NSDictionary *COVFilterLibraryEntry(NSString *filterName, NSString *displayName, NSString *categoryTitle)
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            filterName, @"filterName",
            displayName, @"displayName",
            categoryTitle, @"categoryTitle",
            nil];
}

static NSAttributedString *COVToolbarButtonTitle(NSString *title)
{
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont systemFontOfSize:12.0 weight:NSFontWeightSemibold], NSFontAttributeName,
                                [NSColor whiteColor], NSForegroundColorAttributeName,
                                nil];
    return [[[NSAttributedString alloc] initWithString:title attributes:attributes] autorelease];
}

static CGFloat COVClampCGFloat(CGFloat value, CGFloat minValue, CGFloat maxValue)
{
    if (maxValue < minValue) {
        return minValue;
    }
    return MIN(MAX(value, minValue), maxValue);
}

static NSRect COVClampRectToVisibleFrame(NSRect rect, NSRect visibleFrame)
{
    rect.origin.x = COVClampCGFloat(NSMinX(rect),
                                   NSMinX(visibleFrame) + kFilterPickerPanelGap,
                                   NSMaxX(visibleFrame) - NSWidth(rect) - kFilterPickerPanelGap);
    rect.origin.y = COVClampCGFloat(NSMinY(rect),
                                   NSMinY(visibleFrame) + kFilterPickerPanelGap,
                                   NSMaxY(visibleFrame) - NSHeight(rect) - kFilterPickerPanelGap);
    return rect;
}

static CGFloat COVDistanceFromRectToRect(NSRect rect, NSRect target)
{
    CGFloat dx = 0.0;
    CGFloat dy = 0.0;
    if (NSMaxX(rect) < NSMinX(target)) {
        dx = NSMinX(target) - NSMaxX(rect);
    } else if (NSMinX(rect) > NSMaxX(target)) {
        dx = NSMinX(rect) - NSMaxX(target);
    }
    if (NSMaxY(rect) < NSMinY(target)) {
        dy = NSMinY(target) - NSMaxY(rect);
    } else if (NSMinY(rect) > NSMaxY(target)) {
        dy = NSMinY(rect) - NSMaxY(target);
    }
    return (dx * dx) + (dy * dy);
}

static CGFloat COVRectIntersectionArea(NSRect rectA, NSRect rectB)
{
    NSRect intersection = NSIntersectionRect(rectA, rectB);
    if (NSIsEmptyRect(intersection)) {
        return 0.0;
    }
    return NSWidth(intersection) * NSHeight(intersection);
}

@implementation FilterPanelController
- (CGFloat)filterContentWidth
{
    CGFloat contentWidth = NSWidth([[scrollView contentView] bounds]);
    if (contentWidth <= 0) {
        contentWidth = NSWidth([contentsView bounds]);
    }
    return MAX(contentWidth, kFilterPanelDefaultContentWidth);
}

- (NSArray *)filterLibraryCategories
{
    return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:
             NSLocalizedString(@"Color Adjustments", @"Filter category"), @"title",
             [NSArray arrayWithObjects:kCICategoryColorAdjustment, kCICategoryStillImage, nil], @"categories",
             nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             NSLocalizedString(@"Color Effects", @"Filter category"), @"title",
             [NSArray arrayWithObjects:kCICategoryColorEffect, kCICategoryStillImage, nil], @"categories",
             nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             NSLocalizedString(@"Sharpness", @"Filter category"), @"title",
             [NSArray arrayWithObjects:kCICategorySharpen, kCICategoryStillImage, nil], @"categories",
             nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             NSLocalizedString(@"Blur", @"Filter category"), @"title",
             [NSArray arrayWithObjects:kCICategoryBlur, kCICategoryStillImage, nil], @"categories",
             nil],
            nil];
}

- (void)configureToolbarViews
{
    if (toolbarView != nil) {
        return;
    }

    NSView *panelContentView = [filterPanel contentView];

    toolbarView = [[NSView alloc] initWithFrame:NSZeroRect];
    [toolbarView setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];

    toolbarTitleLabel = [[NSTextField labelWithString:NSLocalizedString(@"Filters", @"Filter panel title")] retain];
    [toolbarTitleLabel setFont:[NSFont systemFontOfSize:13.0 weight:NSFontWeightSemibold]];
    [toolbarView addSubview:toolbarTitleLabel];

    toolbarHintLabel = [[NSTextField labelWithString:NSLocalizedString(@"Search to add filters and adjust each one individually.", @"Filter panel hint")] retain];
    [toolbarHintLabel setTextColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.60]];
    [toolbarHintLabel setFont:[NSFont systemFontOfSize:11.0]];
    [toolbarView addSubview:toolbarHintLabel];

    addFilterButton = [[COVToolbarButton alloc] initWithFrame:NSZeroRect];
    [addFilterButton setTitle:NSLocalizedString(@"Add Filter", @"Add filter button")];
    [addFilterButton setAttributedTitle:COVToolbarButtonTitle(NSLocalizedString(@"Add Filter", @"Add filter button"))];
    [addFilterButton setBezelStyle:NSBezelStyleTexturedRounded];
    [addFilterButton setBordered:NO];
    [addFilterButton setTarget:self];
    [addFilterButton setAction:@selector(showFilterPicker:)];
    [toolbarView addSubview:addFilterButton];

    [panelContentView addSubview:toolbarView];
    [popupButton setHidden:YES];
}

- (void)layoutToolbarAndScrollView
{
    NSView *panelContentView = [filterPanel contentView];
    CGFloat contentWidth = NSWidth([panelContentView bounds]);
    CGFloat contentHeight = NSHeight([panelContentView bounds]);

    [toolbarView setFrame:NSMakeRect(kFilterPanelOuterPadding,
                                     contentHeight - kFilterTopBarHeight - kFilterPanelOuterPadding,
                                     MAX(0, contentWidth - (kFilterPanelOuterPadding * 2.0)),
                                     kFilterTopBarHeight)];

    CGFloat buttonWidth = 132.0;
    CGFloat buttonHeight = 32.0;
    [addFilterButton setFrame:NSMakeRect(NSWidth([toolbarView bounds]) - buttonWidth,
                                         NSHeight([toolbarView bounds]) - buttonHeight - 2.0,
                                         buttonWidth,
                                         buttonHeight)];

    CGFloat titleWidth = MAX(0, NSMinX([addFilterButton frame]) - 12.0);
    [toolbarTitleLabel setFrame:NSMakeRect(0, NSHeight([toolbarView bounds]) - 22.0, titleWidth, 18.0)];
    [toolbarHintLabel setFrame:NSMakeRect(0, 6.0, NSWidth([toolbarView bounds]), 14.0)];

    CGFloat scrollY = kFilterPanelOuterPadding;
    CGFloat scrollTop = NSMinY([toolbarView frame]) - 6.0;
    [scrollView setFrame:NSMakeRect(kFilterPanelOuterPadding,
                                    scrollY,
                                    contentWidth - (kFilterPanelOuterPadding * 2.0),
                                    MAX(0, scrollTop - scrollY))];
}

- (void)rebuildFilterLibraryEntries
{
    NSMutableArray *entries = [NSMutableArray array];
    NSEnumerator *categoryEnumerator = [[self filterLibraryCategories] objectEnumerator];
    NSDictionary *categoryEntry;
    [popupButton removeAllItems];
    [popupButton addItemWithTitle:@""];
    [filterDic removeAllObjects];
    while (categoryEntry = [categoryEnumerator nextObject]) {
        NSString *categoryTitle = [categoryEntry objectForKey:@"title"];
        NSArray *filters = [CIFilter filterNamesInCategories:[categoryEntry objectForKey:@"categories"]];
        NSArray *sortedFilters = [filters sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *title1 = [CIFilter localizedNameForFilterName:obj1];
            NSString *title2 = [CIFilter localizedNameForFilterName:obj2];
            return [title1 localizedCaseInsensitiveCompare:title2];
        }];
        NSEnumerator *filterEnumerator = [sortedFilters objectEnumerator];
        NSString *filterName;
        while (filterName = [filterEnumerator nextObject]) {
            NSString *displayName = [CIFilter localizedNameForFilterName:filterName];
            [filterDic setObject:filterName forKey:displayName];
            [popupButton addItemWithTitle:displayName];
            [entries addObject:COVFilterLibraryEntry(filterName, displayName, categoryTitle)];
        }
    }
    [availableFilterEntries release];
    availableFilterEntries = [entries copy];
    [filteredFilterEntries release];
    filteredFilterEntries = [availableFilterEntries retain];
}

- (void)updateFilterPickerLayout
{
    if (filterPickerPanel == nil) {
        return;
    }

    CGFloat scrollWidth = kFilterPickerWidth - (kFilterPickerHorizontalInset * 2.0);
    CGFloat panelHeight = NSHeight([[filterPickerPanel contentView] frame]);
    CGFloat scrollHeight = MAX(120.0, panelHeight - (kFilterPickerVerticalInset * 2.0) - kFilterPickerSearchHeight - kFilterPickerTopGap);
    NSView *panelContentView = [filterPickerPanel contentView];
    [panelContentView setFrame:NSMakeRect(0, 0, kFilterPickerWidth, panelHeight)];
    [filterSearchField setFrame:NSMakeRect(kFilterPickerHorizontalInset,
                                           panelHeight - kFilterPickerVerticalInset - kFilterPickerSearchHeight,
                                           scrollWidth,
                                           kFilterPickerSearchHeight)];
    [filterPickerScrollView setFrame:NSMakeRect(kFilterPickerHorizontalInset,
                                                kFilterPickerVerticalInset,
                                                scrollWidth,
                                                scrollHeight)];
    CGFloat totalTableHeight = 0;
    for (NSDictionary *item in filterPickerDisplayItems) {
        NSString *type = [item objectForKey:@"type"];
        if ([type isEqualToString:@"header"]) totalTableHeight += kFilterPickerHeaderHeight;
        else if ([type isEqualToString:@"separator"]) totalTableHeight += kFilterPickerSeparatorHeight;
        else totalTableHeight += kFilterPickerRowHeight;
    }
    [filterTableView setFrame:NSMakeRect(0, 0, scrollWidth, MAX(scrollHeight, totalTableHeight))];
    [[filterPickerScrollView contentView] scrollToPoint:NSZeroPoint];
    [filterPickerScrollView reflectScrolledClipView:[filterPickerScrollView contentView]];
}

- (void)refreshFilterPickerResults
{
    NSString *query = [[filterSearchField stringValue] lowercaseString];
    if ([query length] == 0) {
        NSArray *newEntries = [availableFilterEntries retain];
        [filteredFilterEntries release];
        filteredFilterEntries = newEntries;
    } else {
        NSMutableArray *entries = [NSMutableArray array];
        NSEnumerator *enumerator = [availableFilterEntries objectEnumerator];
        NSDictionary *entry;
        while (entry = [enumerator nextObject]) {
            NSString *displayName = [[entry objectForKey:@"displayName"] lowercaseString];
            NSString *categoryTitle = [[entry objectForKey:@"categoryTitle"] lowercaseString];
            if ([displayName rangeOfString:query].location != NSNotFound ||
                [categoryTitle rangeOfString:query].location != NSNotFound) {
                [entries addObject:entry];
            }
        }
        [filteredFilterEntries release];
        filteredFilterEntries = [entries copy];
    }
    [self rebuildFilterPickerDisplayItems];
    [filterTableView reloadData];
    [self updateFilterPickerLayout];
}

- (void)rebuildFilterPickerDisplayItems
{
    NSMutableArray *displayItems = [NSMutableArray array];
    NSMutableArray *seenCategories = [NSMutableArray array];
    NSMutableDictionary *categoryEntries = [NSMutableDictionary dictionary];
    for (NSDictionary *entry in filteredFilterEntries) {
        NSString *category = [entry objectForKey:@"categoryTitle"];
        if (![seenCategories containsObject:category]) {
            [seenCategories addObject:category];
            [categoryEntries setObject:[NSMutableArray array] forKey:category];
        }
        [[categoryEntries objectForKey:category] addObject:entry];
    }
    BOOL firstCategory = YES;
    for (NSString *category in seenCategories) {
        if (!firstCategory) {
            [displayItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"separator", @"type", nil]];
        }
        firstCategory = NO;
        [displayItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"header", @"type", category, @"title", nil]];
        for (NSDictionary *entry in [categoryEntries objectForKey:category]) {
            NSMutableDictionary *displayEntry = [NSMutableDictionary dictionaryWithDictionary:entry];
            [displayEntry setObject:@"entry" forKey:@"type"];
            [displayItems addObject:displayEntry];
        }
    }
    [filterPickerDisplayItems release];
    filterPickerDisplayItems = [displayItems copy];
}

- (void)buildFilterPickerIfNeeded
{
    if (filterPickerPanel != nil) {
        return;
    }

    NSInteger allCategoryCount = [[self filterLibraryCategories] count];
    NSInteger separatorCount = MAX(0, allCategoryCount - 1);
    CGFloat rowCount = MAX(kFilterPickerMinVisibleRows,
                           MIN(kFilterPickerMaxVisibleRows, (CGFloat)[filteredFilterEntries count]));
    CGFloat defaultHeight = kFilterPickerVerticalInset + kFilterPickerSearchHeight + kFilterPickerTopGap
                            + ceil(rowCount * kFilterPickerRowHeight)
                            + ceil((CGFloat)allCategoryCount * kFilterPickerHeaderHeight)
                            + ceil((CGFloat)separatorCount * kFilterPickerSeparatorHeight)
                            + kFilterPickerVerticalInset;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat savedHeight = [defaults doubleForKey:kFilterPickerSavedHeightDefaultsKey];
    CGFloat initialHeight = (savedHeight > 0.0 ? savedHeight : defaultHeight);

    CGFloat maxContentHeight = kFilterPickerVerticalInset + kFilterPickerSearchHeight + kFilterPickerTopGap
                               + ceil((CGFloat)[availableFilterEntries count] * kFilterPickerRowHeight)
                               + ceil((CGFloat)allCategoryCount * kFilterPickerHeaderHeight)
                               + ceil((CGFloat)separatorCount * kFilterPickerSeparatorHeight)
                               + kFilterPickerVerticalInset;

    filterPickerPanel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, kFilterPickerWidth, initialHeight)
                                                   styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskUtilityWindow | NSWindowStyleMaskResizable | NSWindowStyleMaskClosable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [filterPickerPanel setTitle:NSLocalizedString(@"Add Filter", @"Add filter panel title")];
    [filterPickerPanel setReleasedWhenClosed:NO];
    [filterPickerPanel setHidesOnDeactivate:YES];
    [filterPickerPanel setFloatingPanel:YES];
    [filterPickerPanel setDelegate:(id)self];
    [filterPickerPanel setContentMinSize:NSMakeSize(kFilterPickerWidth, defaultHeight)];
    [filterPickerPanel setContentMaxSize:NSMakeSize(kFilterPickerWidth, maxContentHeight)];
    [filterPickerPanel setMinSize:[filterPickerPanel frameRectForContentRect:NSMakeRect(0, 0, kFilterPickerWidth, defaultHeight)].size];
    [filterPickerPanel setMaxSize:[filterPickerPanel frameRectForContentRect:NSMakeRect(0, 0, kFilterPickerWidth, maxContentHeight)].size];

    filterSearchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
    [filterSearchField setPlaceholderString:NSLocalizedString(@"Search Filters", @"Filter search field placeholder")];
    [filterSearchField setDelegate:self];
    [filterSearchField setTarget:self];
    [filterSearchField setAction:@selector(filterSearchChanged:)];
    [[filterSearchField cell] setSendsSearchStringImmediately:YES];
    [[filterSearchField cell] setSendsWholeSearchString:NO];
    [[filterPickerPanel contentView] addSubview:filterSearchField];

    filterPickerScrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    [filterPickerScrollView setBorderType:NSNoBorder];
    [filterPickerScrollView setHasVerticalScroller:YES];
    [filterPickerScrollView setDrawsBackground:NO];

    filterTableView = [[COVFilterPickerTableView alloc] initWithFrame:NSZeroRect];
    [filterTableView setHeaderView:nil];
    [filterTableView setDelegate:self];
    [filterTableView setDataSource:self];
    [filterTableView setRowHeight:kFilterPickerRowHeight];
    [filterTableView setFocusRingType:NSFocusRingTypeNone];
    [filterTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
    [filterTableView setTarget:self];
    [filterTableView setAction:@selector(selectFilterFromPicker:)];
    NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"filter"] autorelease];
    [column setWidth:kFilterPickerWidth - (kFilterPickerHorizontalInset * 2.0)];
    [filterTableView addTableColumn:column];
    [filterPickerScrollView setDocumentView:filterTableView];
    [[filterPickerPanel contentView] addSubview:filterPickerScrollView];
    [self rebuildFilterPickerDisplayItems];
    [self updateFilterPickerLayout];
}

- (NSRect)filterPickerFrameNearButtonRect:(NSRect)buttonRectOnScreen
{
    NSWindow *buttonWindow = [addFilterButton window];
    NSScreen *screen = [buttonWindow screen];
    if (screen == nil) {
        screen = [filterPanel screen];
    }
    if (screen == nil) {
        screen = [NSScreen mainScreen];
    }

    NSRect visibleFrame = [screen visibleFrame];
    NSRect panelFrame = [filterPanel frame];
    NSRect pickerFrame = [filterPickerPanel frame];
    NSSize pickerSize = pickerFrame.size;
    NSRect desiredFrame = NSMakeRect(NSMaxX(buttonRectOnScreen) - pickerSize.width,
                                     NSMinY(buttonRectOnScreen) - pickerSize.height - kFilterPickerPanelGap,
                                     pickerSize.width,
                                     pickerSize.height);
    desiredFrame = COVClampRectToVisibleFrame(desiredFrame, visibleFrame);

    if (!NSIntersectsRect(desiredFrame, panelFrame)) {
        return desiredFrame;
    }

    NSRect candidates[4];
    candidates[0] = NSMakeRect(NSMaxX(panelFrame) + kFilterPickerPanelGap,
                               desiredFrame.origin.y,
                               pickerSize.width,
                               pickerSize.height);
    candidates[1] = NSMakeRect(NSMinX(panelFrame) - pickerSize.width - kFilterPickerPanelGap,
                               desiredFrame.origin.y,
                               pickerSize.width,
                               pickerSize.height);
    candidates[2] = NSMakeRect(desiredFrame.origin.x,
                               NSMinY(panelFrame) - pickerSize.height - kFilterPickerPanelGap,
                               pickerSize.width,
                               pickerSize.height);
    candidates[3] = NSMakeRect(desiredFrame.origin.x,
                               NSMaxY(panelFrame) + kFilterPickerPanelGap,
                               pickerSize.width,
                               pickerSize.height);

    BOOL foundNonOverlappingFrame = NO;
    NSRect bestFrame = desiredFrame;
    CGFloat bestScore = CGFLOAT_MAX;

    for (NSInteger i = 0; i < 4; i++) {
        NSRect candidate = COVClampRectToVisibleFrame(candidates[i], visibleFrame);
        CGFloat overlapArea = COVRectIntersectionArea(candidate, panelFrame);
        CGFloat distanceScore = COVDistanceFromRectToRect(candidate, buttonRectOnScreen);
        if (overlapArea <= 0.5) {
            if (!foundNonOverlappingFrame || distanceScore < bestScore) {
                foundNonOverlappingFrame = YES;
                bestFrame = candidate;
                bestScore = distanceScore;
            }
        } else if (!foundNonOverlappingFrame) {
            CGFloat overlapPenalty = overlapArea * 1000000.0;
            CGFloat score = overlapPenalty + distanceScore;
            if (score < bestScore) {
                bestFrame = candidate;
                bestScore = score;
            }
        }
    }

    return bestFrame;
}

- (void)startObservingFilter:(CIFilter *)filter
{
    NSEnumerator *enu = [[filter inputKeys] objectEnumerator];
    NSString *key;
    while (key = [enu nextObject]) {
        if ([key isEqualToString:kCIInputImageKey] || [key isEqualToString:kCIInputTargetImageKey]) continue;
        [filter addObserver:self forKeyPath:key options:0 context:kFilterObserverContext];
    }
}

- (void)stopObservingFilter:(CIFilter *)filter
{
    NSEnumerator *enu = [[filter inputKeys] objectEnumerator];
    NSString *key;
    while (key = [enu nextObject]) {
        if ([key isEqualToString:kCIInputImageKey] || [key isEqualToString:kCIInputTargetImageKey]) continue;
        [filter removeObserver:self forKeyPath:key context:kFilterObserverContext];
    }
}

- (void)autoExpandPanelIfNeeded
{
    if ([selectedFilterKeys count] == 0) return;

    CGFloat needed = 0;
    for (NSString *key in selectedFilterKeys) {
        NSView *v = [selectedFilterUIViews objectForKey:key];
        if (v) needed += NSHeight([v frame]);
    }
    needed += MAX(0.0, (CGFloat)([selectedFilterKeys count] - 1)) * kFilterItemSpacing;

    CGFloat available = NSHeight([[scrollView contentView] bounds]);
    if (needed <= available + 0.5) return;

    CGFloat expansion = ceil(needed - available);
    NSRect panelFrame = [filterPanel frame];
    NSScreen *screen = [filterPanel screen] ?: [NSScreen mainScreen];
    CGFloat minY = NSMinY([screen visibleFrame]);

    CGFloat newOriginY = panelFrame.origin.y - expansion;
    CGFloat newHeight = panelFrame.size.height + expansion;
    if (newOriginY < minY) {
        newOriginY = minY;
        newHeight = NSMaxY(panelFrame) - minY;
    }
    if (newHeight <= panelFrame.size.height + 0.5) return;

    _lastLayoutContentWidth = NSWidth([[filterPanel contentView] bounds]);
    [filterPanel setFrame:NSMakeRect(panelFrame.origin.x, newOriginY, panelFrame.size.width, newHeight) display:YES];
    [self layoutToolbarAndScrollView];
}

- (void)relayoutFilterCards
{
    if ([selectedFilterKeys count] == 0) return;
    CGFloat contentWidth = [self filterContentWidth];
    CGFloat currentY = 0;
    for (NSString *filterKey in selectedFilterKeys) {
        NSView *v = [selectedFilterUIViews objectForKey:filterKey];
        if (v) currentY += NSHeight([v frame]) + kFilterItemSpacing;
    }
    currentY -= kFilterItemSpacing;
    CGFloat finalHeight = MAX(NSHeight([[scrollView contentView] bounds]), currentY);
    [contentsView setFrameSize:NSMakeSize(contentWidth, finalHeight)];
    CGFloat relayoutY = finalHeight;
    for (NSString *filterKey in selectedFilterKeys) {
        NSView *v = [selectedFilterUIViews objectForKey:filterKey];
        if (v) {
            relayoutY -= NSHeight([v frame]);
            [v setFrameOrigin:NSMakePoint(0, relayoutY)];
            relayoutY -= kFilterItemSpacing;
        }
    }
}

- (void)addFilterNamed:(NSString *)filterName
{
    if ([selectedFilterKeys containsObject:filterName]) {
        return;
    }
    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    if (newFilter == nil) {
        return;
    }
    [newFilter setDefaults];
    [selectedFilterKeys addObject:filterName];
    [selectedFilters setObject:newFilter forKey:filterName];
    [collapsedFilterKeys removeObject:filterName];
    [self startObservingFilter:newFilter];
    [self drawFilterUIViews];
    [self autoExpandPanelIfNeeded];
    [self relayoutFilterCards];
    NSView *newCardView = [selectedFilterUIViews objectForKey:filterName];
    if (newCardView) {
        [newCardView scrollRectToVisible:[newCardView bounds]];
    }
    [self sendNotification];
    [self setUserDefaults];
}

- (NSView *)baseViewForFilterKey:(NSString *)filterKey width:(CGFloat)contentWidth
{
    CIFilter *filter = [selectedFilters objectForKey:filterKey];
    NSString *localizedFilterName = [CIFilter localizedNameForFilterName:[filter name]];
    BOOL isCollapsed = [collapsedFilterKeys containsObject:filterKey];

    NSButton *closeBtn = [[[NSButton alloc] init] autorelease];
    [closeBtn setImage:[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate]];
    [closeBtn setBezelStyle:NSInlineBezelStyle];
    [closeBtn setBordered:NO];
    [closeBtn setFrameSize:NSMakeSize(16,16)];
    [closeBtn setTarget:self];
    [closeBtn setAction:@selector(deleteFilter:)];
    [closeBtn setIdentifier:[filter name]];
    [closeBtn setTag:kFilterCloseButtonTag];

    NSButton *disclosureButton = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [disclosureButton setTitle:(isCollapsed ? @"▸" : @"▾")];
    [disclosureButton setBordered:NO];
    [disclosureButton setFont:[NSFont systemFontOfSize:12.0 weight:NSFontWeightSemibold]];
    [disclosureButton setTarget:self];
    [disclosureButton setAction:@selector(toggleFilterCollapsed:)];
    [disclosureButton setIdentifier:[filter name]];
    [disclosureButton setTag:kFilterDisclosureButtonTag];

    NSTextField *label = [NSTextField labelWithString:localizedFilterName];
    [label setTag:kFilterLabelTag];
    [label setFont:[NSFont systemFontOfSize:13.0 weight:NSFontWeightSemibold]];
    [[label cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [label setTextColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.95]];

    IKFilterUIView *filterUIView = nil;
    CGFloat filterUIHeight = 0;
    if (!isCollapsed) {
        NSDictionary *uiOptions = [NSDictionary dictionaryWithObject:IKUISizeMini forKey:IKUISizeFlavor];
        NSArray *excludedKeys = [NSArray arrayWithObjects:kCIInputImageKey, kCIInputTargetImageKey, nil];
        filterUIView = [filter viewForUIConfiguration:uiOptions excludedKeys:excludedKeys];
        if (filterUIView) {
            filterUIHeight = NSHeight([filterUIView frame]);
        }
    }

    CGFloat contentSectionHeight = isCollapsed ? 0.0 : (filterUIHeight + kFilterCardVerticalPadding + kFilterCardContentSpacing);
    CGFloat cardHeight = contentSectionHeight + kFilterCardHeaderHeight + kFilterCardVerticalPadding;

    COVFilterBorderView *cardView = [[[COVFilterBorderView alloc] initWithFrame:NSMakeRect(0, 0, contentWidth, cardHeight)] autorelease];
    [cardView setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];

    CGFloat headerY = cardHeight - kFilterCardHeaderHeight - 8.0;
    CGFloat disclosureX = kFilterCardButtonInset;
    [disclosureButton setFrame:NSMakeRect(disclosureX, headerY + 1.0, 16.0, 18.0)];
    [cardView addSubview:disclosureButton];

    CGFloat closeButtonX = contentWidth - kFilterCardButtonInset - NSWidth([closeBtn frame]);
    [closeBtn setFrameOrigin:NSMakePoint(closeButtonX, headerY + 2.0)];
    [cardView addSubview:closeBtn];

    NSButton *resetBtn = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
    [resetBtn setTitle:@"↺"];
    [resetBtn setBordered:NO];
    [resetBtn setFont:[NSFont systemFontOfSize:13.0 weight:NSFontWeightLight]];
    [resetBtn setContentTintColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.55]];
    [resetBtn setTarget:self];
    [resetBtn setAction:@selector(resetFilterParameters:)];
    [resetBtn setIdentifier:[filter name]];
    [resetBtn setTag:kFilterResetButtonTag];
    [resetBtn setFrame:NSMakeRect(closeButtonX - 20.0, headerY + 1.0, 16.0, 18.0)];
    [cardView addSubview:resetBtn];

    CGFloat labelX = NSMaxX([disclosureButton frame]) + 6.0;
    CGFloat labelWidth = MAX(0.0, NSMinX([resetBtn frame]) - labelX - 6.0);
    [label setFrame:NSMakeRect(labelX, headerY + 1.0, labelWidth, kFilterLabelHeight)];
    [cardView addSubview:label];

    if (!isCollapsed) {
        NSView *separator = [[[NSView alloc] initWithFrame:NSMakeRect(kFilterCardHorizontalPadding,
                                                                      contentSectionHeight,
                                                                      contentWidth - (kFilterCardHorizontalPadding * 2.0),
                                                                      1.0)] autorelease];
        [separator setWantsLayer:YES];
        [[separator layer] setBackgroundColor:[[NSColor colorWithCalibratedWhite:1.0 alpha:0.08] CGColor]];
        [cardView addSubview:separator];

        if (filterUIView) {
            [filterUIView setFrameOrigin:NSMakePoint(kFilterCardHorizontalPadding, kFilterCardVerticalPadding)];
            [cardView addSubview:filterUIView];
        }
    }

    return cardView;
}

-(void)awakeFromNib
{
    [filterPanel setFrameAutosaveName:@"FilterPanel"];
    [self ensureFilterPanelMinimumSize];

    filterDic = [[NSMutableDictionary alloc] init];
    selectedFilterUIViews = [[NSMutableDictionary alloc] init];
    collapsedFilterKeys = [[NSMutableSet alloc] init];
    [CIPlugIn loadAllPlugIns];
    [self rebuildFilterLibraryEntries];
    [self configureToolbarViews];
    [self buildFilterPickerIfNeeded];
    [self layoutToolbarAndScrollView];
    _lastLayoutContentWidth = NSWidth([[filterPanel contentView] bounds]);

    selectedFilters = [[NSMutableDictionary alloc] init];
    selectedFilterKeys = [[NSMutableArray alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults arrayForKey:@"CIFilterKeys"]) {
        NSArray *tmpSelectedFilterKeys = [defaults arrayForKey:@"CIFilterKeys"];
        NSMutableDictionary *dic;
        if (@available(macOS 10.13, *)) {
            dic = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:[defaults objectForKey:@"CIFilters"] error:nil];
        } else {
            dic = [NSKeyedUnarchiver unarchiveObjectWithData:[defaults objectForKey:@"CIFilters"]];
        }
        NSEnumerator *enu = [tmpSelectedFilterKeys objectEnumerator];
        NSString *filterKey;
        while (filterKey = [enu nextObject]) {
            if ([dic objectForKey:filterKey]) {
                [selectedFilterKeys addObject:filterKey];
                [selectedFilters setObject:[dic objectForKey:filterKey] forKey:filterKey];
                [self startObservingFilter:[dic objectForKey:filterKey]];
            }
        }
        [self drawFilterUIViews];
        [self sendNotification];
    }
    [self applyDebugPresetIfNeeded];
}
- (void)fitPanelHeightToContent
{
    CGFloat neededContentHeight;
    if ([selectedFilterKeys count] == 0) {
        neededContentHeight = kFilterPanelMinContentHeight;
    } else {
        CGFloat totalCards = 0;
        for (NSString *key in selectedFilterKeys) {
            NSView *v = [selectedFilterUIViews objectForKey:key];
            if (v) totalCards += NSHeight([v frame]);
        }
        totalCards += MAX(0.0, (CGFloat)([selectedFilterKeys count] - 1)) * kFilterItemSpacing;
        neededContentHeight = totalCards + kFilterTopBarHeight + (kFilterPanelOuterPadding * 2.0) + 6.0;
        neededContentHeight = MAX(neededContentHeight, kFilterPanelMinContentHeight);
    }

    NSRect contentRect = NSMakeRect(0, 0, NSWidth([[filterPanel contentView] frame]), neededContentHeight);
    CGFloat newWindowHeight = [filterPanel frameRectForContentRect:contentRect].size.height;
    NSRect panelFrame = [filterPanel frame];
    CGFloat newOriginY = NSMaxY(panelFrame) - newWindowHeight;
    NSScreen *screen = [filterPanel screen] ?: [NSScreen mainScreen];
    CGFloat minY = NSMinY([screen visibleFrame]);
    if (newOriginY < minY) {
        newOriginY = minY;
        newWindowHeight = NSMaxY(panelFrame) - minY;
    }
    _lastLayoutContentWidth = NSWidth([[filterPanel contentView] bounds]);
    [filterPanel setFrame:NSMakeRect(panelFrame.origin.x, newOriginY, panelFrame.size.width, newWindowHeight) display:NO];
    [self layoutToolbarAndScrollView];
}
- (IBAction)openFilterPanel:(id)sender
{
    [self ensureFilterPanelMinimumSize];
    [self layoutToolbarAndScrollView];
    [self fitPanelHeightToContent];
    [filterPanel makeKeyAndOrderFront:self];
}
- (IBAction)filterSelected:(id)sender
{
    NSString *filterName = [filterDic objectForKey:[sender title]];
    [self addFilterNamed:filterName];
    [sender setTitle:@""];
}
- (void)drawFilterUIViews
{
    NSEnumerator *existingViews = [[contentsView subviews] objectEnumerator];
    NSView *existingView;
    while (existingView = [existingViews nextObject]) {
        [existingView removeFromSuperview];
    }
    [selectedFilterUIViews removeAllObjects];

    CGFloat contentWidth = [self filterContentWidth];
    CGFloat currentY = 0;
    NSEnumerator *enu = [selectedFilterKeys objectEnumerator];
    NSString *filterKey;
    while (filterKey = [enu nextObject]) {
        NSView *baseView = [self baseViewForFilterKey:filterKey width:contentWidth];
        [baseView setFrameOrigin:NSMakePoint(0, currentY)];
        [contentsView addSubview:baseView];
        [selectedFilterUIViews setObject:baseView forKey:filterKey];
        currentY += NSHeight([baseView frame]) + kFilterItemSpacing;
    }
    if ([selectedFilterKeys count] > 0) {
        currentY -= kFilterItemSpacing;
    }

    CGFloat finalHeight = MAX(NSHeight([[scrollView contentView] bounds]), currentY);
    [contentsView setFrameSize:NSMakeSize(contentWidth, finalHeight)];

    CGFloat relayoutY = finalHeight;
    enu = [selectedFilterKeys objectEnumerator];
    while (filterKey = [enu nextObject]) {
        NSView *baseView = [selectedFilterUIViews objectForKey:filterKey];
        relayoutY -= NSHeight([baseView frame]);
        [baseView setFrameOrigin:NSMakePoint(0, relayoutY)];
        relayoutY -= kFilterItemSpacing;
    }
}
- (void)showFilterPicker:(id)sender
{
    [self buildFilterPickerIfNeeded];
    [filterSearchField setStringValue:@""];
    [self refreshFilterPickerResults];
    [filterTableView deselectAll:nil];
    NSRect buttonRectInWindow = [addFilterButton convertRect:[addFilterButton bounds] toView:nil];
    NSRect buttonRectOnScreen = [[addFilterButton window] convertRectToScreen:buttonRectInWindow];
    NSRect pickerFrame = [self filterPickerFrameNearButtonRect:buttonRectOnScreen];
    [filterPickerPanel setFrame:pickerFrame display:YES];
    [filterPickerPanel makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}
- (void)filterSearchChanged:(id)sender
{
    [self refreshFilterPickerResults];
}
- (void)selectFilterFromPicker:(id)sender
{
    NSInteger row = [filterTableView clickedRow];
    if (row < 0 || row >= (NSInteger)[filterPickerDisplayItems count]) {
        row = [filterTableView selectedRow];
    }
    if (row < 0 || row >= (NSInteger)[filterPickerDisplayItems count]) {
        return;
    }
    NSDictionary *item = [filterPickerDisplayItems objectAtIndex:row];
    if (![[item objectForKey:@"type"] isEqualToString:@"entry"]) {
        return;
    }
    [self addFilterNamed:[item objectForKey:@"filterName"]];
}
- (void)toggleFilterCollapsed:(id)sender
{
    NSString *filterName = [sender identifier];
    if ([collapsedFilterKeys containsObject:filterName]) {
        [collapsedFilterKeys removeObject:filterName];
    } else {
        [collapsedFilterKeys addObject:filterName];
    }
    [self drawFilterUIViews];
}
- (BOOL)windowShouldClose:(NSWindow *)sender
{
    if (sender == filterPanel) {
        [filterPanel orderOut:self];
        return NO;
    }
    return YES;
}
- (void)windowWillClose:(NSNotification *)notification
{
    if ([notification object] == filterPickerPanel && [filterPanel isVisible]) {
        [filterPanel makeKeyAndOrderFront:self];
    }
}
- (void)windowDidResize:(NSNotification *)notification
{
    if ([notification object] == filterPanel) {
        [self layoutToolbarAndScrollView];
        CGFloat newWidth = NSWidth([[filterPanel contentView] bounds]);
        if (fabs(newWidth - _lastLayoutContentWidth) > 0.5) {
            _lastLayoutContentWidth = newWidth;
            [self drawFilterUIViews];
        }
    } else if ([notification object] == filterPickerPanel) {
        [self updateFilterPickerLayout];
        [[NSUserDefaults standardUserDefaults] setDouble:NSHeight([[filterPickerPanel contentView] frame])
                                                 forKey:kFilterPickerSavedHeightDefaultsKey];
    }
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [filterPickerDisplayItems count];
}
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSDictionary *item = [filterPickerDisplayItems objectAtIndex:row];
    NSString *type = [item objectForKey:@"type"];
    if ([type isEqualToString:@"header"]) return kFilterPickerHeaderHeight;
    if ([type isEqualToString:@"separator"]) return kFilterPickerSeparatorHeight;
    return kFilterPickerRowHeight;
}
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    NSDictionary *item = [filterPickerDisplayItems objectAtIndex:row];
    return [[item objectForKey:@"type"] isEqualToString:@"entry"];
}
- (void)controlTextDidChange:(NSNotification *)obj
{
    if ([obj object] == filterSearchField) {
        [self refreshFilterPickerResults];
    }
}
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CGFloat columnWidth = [tableColumn width];
    NSDictionary *item = [filterPickerDisplayItems objectAtIndex:row];

    if ([[item objectForKey:@"type"] isEqualToString:@"separator"]) {
        NSView *sepView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, columnWidth, kFilterPickerSeparatorHeight)] autorelease];
        NSView *line = [[[NSView alloc] initWithFrame:NSMakeRect(8, floor((kFilterPickerSeparatorHeight - 1.0) / 2.0), columnWidth - 16, 1.0)] autorelease];
        [line setWantsLayer:YES];
        [[line layer] setBackgroundColor:[[NSColor separatorColor] CGColor]];
        [sepView addSubview:line];
        return sepView;
    }

    if ([[item objectForKey:@"type"] isEqualToString:@"header"]) {
        NSView *headerView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, columnWidth, kFilterPickerHeaderHeight)] autorelease];
        NSTextField *headerLabel = [NSTextField labelWithString:[[item objectForKey:@"title"] uppercaseString]];
        [headerLabel setFont:[NSFont systemFontOfSize:9.5 weight:NSFontWeightSemibold]];
        [headerLabel setTextColor:[NSColor secondaryLabelColor]];
        [headerLabel setFrame:NSMakeRect(8, floor((kFilterPickerHeaderHeight - 11.0) / 2.0), columnWidth - 16, 11)];
        [headerView addSubview:headerLabel];
        return headerView;
    }

    NSView *rowView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, columnWidth, kFilterPickerRowHeight)] autorelease];
    NSTextField *titleLabel = [NSTextField labelWithString:[item objectForKey:@"displayName"]];
    [titleLabel setFont:[NSFont systemFontOfSize:12.0]];
    [titleLabel sizeToFit];
    CGFloat labelH = NSHeight([titleLabel frame]);
    [titleLabel setFrame:NSMakeRect(16, floor((kFilterPickerRowHeight - labelH) / 2.0), columnWidth - 24, labelH)];
    [rowView addSubview:titleLabel];
    return rowView;
}
- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    return YES;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != kFilterObserverContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    [self sendNotification];
    [self setUserDefaults];
}
- (void)resetFilterParameters:(id)sender
{
    CIFilter *filter = [selectedFilters objectForKey:[sender identifier]];
    if (filter == nil) return;
    [filter setDefaults];
    [self drawFilterUIViews];
    [self sendNotification];
    [self setUserDefaults];
}
- (void)deleteFilter:(id)sender
{
    CIFilter *filter = [selectedFilters objectForKey:[sender identifier]];
    if (filter) {
        [self stopObservingFilter:filter];
    }
    [selectedFilters removeObjectForKey:[sender identifier]];
    [selectedFilterUIViews removeObjectForKey:[sender identifier]];
    [selectedFilterKeys removeObject:[sender identifier]];
    [self drawFilterUIViews];
    [self sendNotification];
    [self setUserDefaults];
}
@end

@implementation FilterPanelController(private)
- (void)ensureFilterPanelMinimumSize
{
    NSSize currentContentSize = [[filterPanel contentView] frame].size;
    CGFloat visibleScrollWidth = NSWidth([[scrollView contentView] frame]);
    if (visibleScrollWidth <= 0) {
        visibleScrollWidth = NSWidth([scrollView frame]);
    }
    CGFloat nonScrollableWidth = MAX(0.0, currentContentSize.width - visibleScrollWidth);
    CGFloat minContentWidth = ceil(kFilterPanelDefaultContentWidth + nonScrollableWidth + 2.0);
    NSSize minContentSize = NSMakeSize(minContentWidth, kFilterPanelMinContentHeight);
    [filterPanel setContentMinSize:minContentSize];

    NSRect minFrameRect = [filterPanel frameRectForContentRect:NSMakeRect(0, 0, minContentSize.width, minContentSize.height)];
    [filterPanel setMinSize:minFrameRect.size];

    if (currentContentSize.width < minContentSize.width) {
        [filterPanel setContentSize:NSMakeSize(minContentSize.width, currentContentSize.height)];
    }
}
- (void)applyDebugPresetIfNeeded
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *preset = [[[NSProcessInfo processInfo] environment] objectForKey:@"COOVIEWER_FILTER_DEBUG_PRESET"];
    if ([preset length] == 0) {
        preset = [defaults stringForKey:@"FilterPanelDebugFilters"];
    }
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    BOOL shouldApplyPreset = ([preset length] > 0
                              || [arguments containsObject:@"--debug-filter-panel"]
                              || [defaults boolForKey:@"FilterPanelDebugPreset"]);
    if (shouldApplyPreset == NO) return;
    if ([defaults boolForKey:@"FilterPanelDebugPreset"]) {
        [defaults removeObjectForKey:@"FilterPanelDebugPreset"];
        [defaults synchronize];
    }
    if ([defaults stringForKey:@"FilterPanelDebugFilters"]) {
        [defaults removeObjectForKey:@"FilterPanelDebugFilters"];
        [defaults synchronize];
    }

    NSEnumerator *stopEnu = [selectedFilters objectEnumerator];
    CIFilter *existingFilter;
    while (existingFilter = [stopEnu nextObject]) {
        [self stopObservingFilter:existingFilter];
    }
    [selectedFilterKeys removeAllObjects];
    [selectedFilters removeAllObjects];

    NSArray *debugFilters = COVDebugFilterNamesFromPresetString(preset);
    if ([debugFilters count] == 0) {
        debugFilters = [NSArray arrayWithObjects:@"CIGammaAdjust", @"CIToneMapHeadroom", nil];
    }
    NSEnumerator *enu = [debugFilters objectEnumerator];
    NSString *filterName;
    while (filterName = [enu nextObject]) {
        CIFilter *filter = [CIFilter filterWithName:filterName];
        if (filter) {
            [filter setDefaults];
            [selectedFilterKeys addObject:filterName];
            [selectedFilters setObject:filter forKey:filterName];
            [self startObservingFilter:filter];
        }
    }

    [self drawFilterUIViews];
    [self sendNotification];
    [self setUserDefaults];
    [self ensureFilterPanelMinimumSize];
    if ([defaults boolForKey:@"FilterPanelSnapToMinimumWidth"]) {
        NSSize minContentSize = [filterPanel contentMinSize];
        NSSize currentContentSize = [[filterPanel contentView] frame].size;
        [filterPanel setContentSize:NSMakeSize(minContentSize.width, currentContentSize.height)];
        [defaults removeObjectForKey:@"FilterPanelSnapToMinimumWidth"];
        [defaults synchronize];
    }
    [filterPanel makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    if ([defaults boolForKey:@"FilterPanelOpenPickerOnLaunch"]) {
        [defaults removeObjectForKey:@"FilterPanelOpenPickerOnLaunch"];
        [defaults synchronize];
        [self showFilterPicker:addFilterButton];
        [self dumpDebugFilterPickerIfNeeded];
    }
    [self dumpDebugPanelIfNeeded];
}
- (void)dumpDebugPanelIfNeeded
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if ([arguments containsObject:@"--dump-filter-panel"] == NO
        && [defaults boolForKey:@"FilterPanelDumpOnLaunch"] == NO) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSView *targetView = [filterPanel contentView];
        NSBitmapImageRep *rep = [targetView bitmapImageRepForCachingDisplayInRect:[targetView bounds]];
        [targetView cacheDisplayInRect:[targetView bounds] toBitmapImageRep:rep];
        NSData *pngData = [rep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
        [pngData writeToFile:@"/tmp/cooviewer-filter-panel.png" atomically:YES];
        [defaults removeObjectForKey:@"FilterPanelDumpOnLaunch"];
        [defaults synchronize];
    });
}
- (void)dumpDebugFilterPickerIfNeeded
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"FilterPanelDumpPickerOnLaunch"] == NO) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSView *targetView = [filterPickerPanel contentView];
        NSBitmapImageRep *rep = [targetView bitmapImageRepForCachingDisplayInRect:[targetView bounds]];
        [targetView cacheDisplayInRect:[targetView bounds] toBitmapImageRep:rep];
        NSData *pngData = [rep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
        [pngData writeToFile:@"/tmp/cooviewer-filter-picker.png" atomically:YES];
        [defaults removeObjectForKey:@"FilterPanelDumpPickerOnLaunch"];
        [defaults synchronize];
    });
}
- (void)setUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data;
    if (@available(macOS 10.13, *)) {
        NSError *archiveError = nil;
        data = [NSKeyedArchiver archivedDataWithRootObject:selectedFilters requiringSecureCoding:NO error:&archiveError];
    } else {
        data = [NSKeyedArchiver archivedDataWithRootObject:selectedFilters];
    }
    [defaults setObject:data forKey:@"CIFilters"];
    [defaults setObject:selectedFilterKeys forKey:@"CIFilterKeys"];
}
- (void)sendNotification
{
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:selectedFilterKeys,@"keys",selectedFilters,@"filters",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FilterUIValueDidChange" object:dic];
}
@end
