//
//  FilterPanelController.m
//  cooViewer
//
//  Created by coo on 2020/01/11.
//

#import "FilterPanelController.h"

static const NSInteger kFilterLabelTag = 1001;
static const NSInteger kFilterCloseButtonTag = 1002;
static const CGFloat kFilterLabelHeight = 20.0;
static const CGFloat kFilterHeaderBottomSpacing = 8.0;
static const CGFloat kFilterHeaderHorizontalPadding = 6.0;
static const CGFloat kFilterCloseButtonRightInset = 8.0;
static const CGFloat kFilterTitleToButtonSpacing = 8.0;
static const CGFloat kFilterPanelDefaultContentWidth = 340.0;
static const CGFloat kFilterItemSpacing = 12.0;
static const CGFloat kFilterRowSpacing = 8.0;
static const CGFloat kFilterBoxHorizontalPadding = 14.0;
static const CGFloat kFilterBoxVerticalPadding = 10.0;
static const CGFloat kNumericFieldWidth = 56.0;
static const CGFloat kFieldHeight = 22.0;

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
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.35] setStroke];
    [borderPath stroke];
}
@end

static NSString *COVControlIdentifier(NSString *filterKey, NSString *inputKey, NSString *kind, NSInteger index)
{
    return [NSString stringWithFormat:@"%@\t%@\t%@\t%ld", filterKey, inputKey, kind, (long)index];
}

static NSArray *COVControlIdentifierComponents(NSString *identifier)
{
    return [identifier componentsSeparatedByString:@"\t"];
}

static BOOL COVNumberIsIntegralType(NSDictionary *attribute)
{
    NSString *type = [attribute objectForKey:kCIAttributeType];
    if ([type isEqualToString:kCIAttributeTypeInteger] ||
        [type isEqualToString:kCIAttributeTypeCount] ||
        [type isEqualToString:kCIAttributeTypeBoolean]) {
        return YES;
    }
    return NO;
}

static NSString *COVStringForNumber(NSNumber *number, BOOL integral)
{
    if (integral) {
        return [NSString stringWithFormat:@"%ld", (long)llround([number doubleValue])];
    }
    double value = [number doubleValue];
    if (fabs(value) >= 1000.0 || floor(value) == value) {
        return [NSString stringWithFormat:@"%.0f", value];
    }
    return [NSString stringWithFormat:@"%.3f", value];
}

static NSString *COVDisplayNameForInputKey(NSString *inputKey, NSDictionary *attribute)
{
    NSString *displayName = [attribute objectForKey:kCIAttributeDisplayName];
    if ([displayName length] > 0) {
        return displayName;
    }
    if ([inputKey hasPrefix:@"input"] && [inputKey length] > 5) {
        return [inputKey substringFromIndex:5];
    }
    return inputKey;
}

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

static NSInteger COVVectorComponentCount(CIVector *vector, NSDictionary *attribute)
{
    NSString *type = [attribute objectForKey:kCIAttributeType];
    if ([type isEqualToString:kCIAttributeTypeOffset] ||
        [type isEqualToString:kCIAttributeTypePosition]) {
        return 2;
    }
    if ([type isEqualToString:kCIAttributeTypeRectangle]) {
        return 4;
    }
    NSInteger count = [vector count];
    if (count <= 0) {
        count = 2;
    }
    return MIN(count, 4);
}

static NSString *COVVectorComponentLabel(NSInteger index, NSInteger count, NSDictionary *attribute)
{
    NSString *type = [attribute objectForKey:kCIAttributeType];
    if ([type isEqualToString:kCIAttributeTypeRectangle]) {
        static NSString *labels[] = {@"X", @"Y", @"W", @"H"};
        return labels[index];
    }
    if (count == 2) {
        static NSString *labels[] = {@"X", @"Y"};
        return labels[index];
    }
    static NSString *labels[] = {@"X", @"Y", @"Z", @"W"};
    return labels[index];
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

- (void)registerControlView:(NSView *)control identifier:(NSString *)identifier
{
    [control setIdentifier:identifier];
    [controlViewsByIdentifier setObject:control forKey:identifier];
}

- (NSArray *)editableInputKeysForFilter:(CIFilter *)filter
{
    NSMutableArray *keys = [NSMutableArray array];
    NSEnumerator *enu = [[filter inputKeys] objectEnumerator];
    NSString *key;
    while (key = [enu nextObject]) {
        if ([key isEqualToString:kCIInputImageKey] ||
            [key isEqualToString:kCIInputTargetImageKey]) {
            continue;
        }
        [keys addObject:key];
    }
    return keys;
}

- (void)applyFilterValue:(id)value filterKey:(NSString *)filterKey inputKey:(NSString *)inputKey
{
    CIFilter *filter = [selectedFilters objectForKey:filterKey];
    if (filter == nil) return;
    [filter setValue:value forKey:inputKey];
    [self sendNotification];
    [self setUserDefaults];
}

- (void)syncNumericFieldForFilterKey:(NSString *)filterKey inputKey:(NSString *)inputKey number:(NSNumber *)number integral:(BOOL)integral
{
    NSString *fieldIdentifier = COVControlIdentifier(filterKey, inputKey, @"number", 0);
    NSTextField *field = [controlViewsByIdentifier objectForKey:fieldIdentifier];
    if (field) {
        [field setStringValue:COVStringForNumber(number, integral)];
    }
}

- (void)syncSliderForFilterKey:(NSString *)filterKey inputKey:(NSString *)inputKey number:(NSNumber *)number
{
    NSString *sliderIdentifier = COVControlIdentifier(filterKey, inputKey, @"slider", 0);
    NSSlider *slider = [controlViewsByIdentifier objectForKey:sliderIdentifier];
    if (slider) {
        [slider setDoubleValue:[number doubleValue]];
    }
}

- (NSNumber *)clampedNumberFromValue:(double)value attribute:(NSDictionary *)attribute
{
    NSNumber *minValue = [attribute objectForKey:kCIAttributeSliderMin];
    NSNumber *maxValue = [attribute objectForKey:kCIAttributeSliderMax];
    if (minValue == nil) minValue = [attribute objectForKey:kCIAttributeMin];
    if (maxValue == nil) maxValue = [attribute objectForKey:kCIAttributeMax];
    if (minValue) value = MAX(value, [minValue doubleValue]);
    if (maxValue) value = MIN(value, [maxValue doubleValue]);
    if (COVNumberIsIntegralType(attribute)) {
        return [NSNumber numberWithLong:llround(value)];
    }
    return [NSNumber numberWithDouble:value];
}

- (NSView *)numberRowForFilterKey:(NSString *)filterKey
                         inputKey:(NSString *)inputKey
                        attribute:(NSDictionary *)attribute
                       rowWidth:(CGFloat)rowWidth
{
    CGFloat rowHeight = 42.0;
    NSView *rowView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, rowWidth, rowHeight)] autorelease];
    NSString *displayName = COVDisplayNameForInputKey(inputKey, attribute);
    NSTextField *label = [NSTextField labelWithString:displayName];
    [label setFrame:NSMakeRect(0, rowHeight - 14.0, rowWidth, 14.0)];
    [rowView addSubview:label];

    NSDictionary *attrs = attribute;
    NSNumber *minValue = [attrs objectForKey:kCIAttributeSliderMin];
    NSNumber *maxValue = [attrs objectForKey:kCIAttributeSliderMax];
    if (minValue == nil) minValue = [attrs objectForKey:kCIAttributeMin];
    if (maxValue == nil) maxValue = [attrs objectForKey:kCIAttributeMax];
    NSNumber *currentValue = [[selectedFilters objectForKey:filterKey] valueForKey:inputKey];
    BOOL integral = COVNumberIsIntegralType(attrs);
    CGFloat controlY = 0.0;

    if (minValue && maxValue && [maxValue doubleValue] > [minValue doubleValue]) {
        NSSlider *slider = [[[NSSlider alloc] initWithFrame:NSMakeRect(0, controlY, rowWidth - kNumericFieldWidth - 8.0, kFieldHeight)] autorelease];
        [slider setMinValue:[minValue doubleValue]];
        [slider setMaxValue:[maxValue doubleValue]];
        [slider setDoubleValue:[currentValue doubleValue]];
        [slider setTarget:self];
        [slider setAction:@selector(numberSliderChanged:)];
        NSString *sliderIdentifier = COVControlIdentifier(filterKey, inputKey, @"slider", 0);
        [self registerControlView:slider identifier:sliderIdentifier];
        [rowView addSubview:slider];
    }

    NSTextField *field = [[[NSTextField alloc] initWithFrame:NSMakeRect(rowWidth - kNumericFieldWidth, controlY, kNumericFieldWidth, kFieldHeight)] autorelease];
    [field setStringValue:COVStringForNumber(currentValue, integral)];
    [field setTarget:self];
    [field setAction:@selector(numberFieldChanged:)];
    NSString *fieldIdentifier = COVControlIdentifier(filterKey, inputKey, @"number", 0);
    [self registerControlView:field identifier:fieldIdentifier];
    [rowView addSubview:field];

    return rowView;
}

- (NSView *)booleanRowForFilterKey:(NSString *)filterKey
                          inputKey:(NSString *)inputKey
                         attribute:(NSDictionary *)attribute
                          rowWidth:(CGFloat)rowWidth
{
    NSButton *checkbox = [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, rowWidth, 18.0)] autorelease];
    [checkbox setButtonType:NSSwitchButton];
    [checkbox setTitle:COVDisplayNameForInputKey(inputKey, attribute)];
    [checkbox setState:[[[selectedFilters objectForKey:filterKey] valueForKey:inputKey] boolValue] ? NSControlStateValueOn : NSControlStateValueOff];
    [checkbox setTarget:self];
    [checkbox setAction:@selector(booleanValueChanged:)];
    NSString *identifier = COVControlIdentifier(filterKey, inputKey, @"bool", 0);
    [self registerControlView:checkbox identifier:identifier];

    NSView *rowView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, rowWidth, 18.0)] autorelease];
    [rowView addSubview:checkbox];
    return rowView;
}

- (NSView *)vectorRowForFilterKey:(NSString *)filterKey
                         inputKey:(NSString *)inputKey
                        attribute:(NSDictionary *)attribute
                         rowWidth:(CGFloat)rowWidth
{
    CIVector *vector = [[selectedFilters objectForKey:filterKey] valueForKey:inputKey];
    NSInteger count = COVVectorComponentCount(vector, attribute);
    CGFloat rowHeight = 44.0;
    NSView *rowView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, rowWidth, rowHeight)] autorelease];
    NSTextField *label = [NSTextField labelWithString:COVDisplayNameForInputKey(inputKey, attribute)];
    [label setFrame:NSMakeRect(0, rowHeight - 14.0, rowWidth, 14.0)];
    [rowView addSubview:label];

    CGFloat gap = 6.0;
    CGFloat fieldWidth = floor((rowWidth - ((count - 1) * gap)) / count);
    NSInteger index;
    for (index = 0; index < count; index++) {
        CGFloat fieldX = (fieldWidth + gap) * index;
        NSView *fieldContainer = [[[NSView alloc] initWithFrame:NSMakeRect(fieldX, 0, fieldWidth, kFieldHeight)] autorelease];
        NSTextField *prefix = [NSTextField labelWithString:COVVectorComponentLabel(index, count, attribute)];
        [prefix setFrame:NSMakeRect(0, 4, 12, 14)];
        [fieldContainer addSubview:prefix];

        NSTextField *field = [[[NSTextField alloc] initWithFrame:NSMakeRect(16, 0, fieldWidth - 16, kFieldHeight)] autorelease];
        [field setStringValue:COVStringForNumber([NSNumber numberWithDouble:[vector valueAtIndex:index]], NO)];
        [field setTarget:self];
        [field setAction:@selector(vectorFieldChanged:)];
        NSString *identifier = COVControlIdentifier(filterKey, inputKey, @"vector", index);
        [self registerControlView:field identifier:identifier];
        [fieldContainer addSubview:field];
        [rowView addSubview:fieldContainer];
    }
    return rowView;
}

- (NSView *)colorRowForFilterKey:(NSString *)filterKey
                        inputKey:(NSString *)inputKey
                       attribute:(NSDictionary *)attribute
                        rowWidth:(CGFloat)rowWidth
{
    CGFloat rowHeight = 44.0;
    NSView *rowView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, rowWidth, rowHeight)] autorelease];
    NSTextField *label = [NSTextField labelWithString:COVDisplayNameForInputKey(inputKey, attribute)];
    [label setFrame:NSMakeRect(0, rowHeight - 14.0, rowWidth, 14.0)];
    [rowView addSubview:label];

    CIColor *color = [[selectedFilters objectForKey:filterKey] valueForKey:inputKey];
    NSColor *nsColor = [NSColor colorWithCalibratedRed:[color red] green:[color green] blue:[color blue] alpha:[color alpha]];
    NSColorWell *well = [[[NSColorWell alloc] initWithFrame:NSMakeRect(0, 0, 52, kFieldHeight)] autorelease];
    [well setColor:nsColor];
    [well setTarget:self];
    [well setAction:@selector(colorValueChanged:)];
    NSString *identifier = COVControlIdentifier(filterKey, inputKey, @"color", 0);
    [self registerControlView:well identifier:identifier];
    [rowView addSubview:well];
    return rowView;
}

- (NSView *)fallbackRowForFilterKey:(NSString *)filterKey
                           inputKey:(NSString *)inputKey
                          attribute:(NSDictionary *)attribute
                           rowWidth:(CGFloat)rowWidth
{
    NSView *rowView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, rowWidth, 34.0)] autorelease];
    NSTextField *label = [NSTextField labelWithString:COVDisplayNameForInputKey(inputKey, attribute)];
    [label setFrame:NSMakeRect(0, 18.0, rowWidth, 14.0)];
    [rowView addSubview:label];
    NSTextField *message = [NSTextField labelWithString:NSLocalizedString(@"Unsupported Filter Parameter", nil)];
    [message setTextColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.65]];
    [message setFrame:NSMakeRect(0, 0, rowWidth, 14.0)];
    [rowView addSubview:message];
    return rowView;
}

- (NSView *)editorRowForFilterKey:(NSString *)filterKey
                         inputKey:(NSString *)inputKey
                           filter:(CIFilter *)filter
                         rowWidth:(CGFloat)rowWidth
{
    NSDictionary *attribute = [[filter attributes] objectForKey:inputKey];
    NSString *attributeClass = [attribute objectForKey:kCIAttributeClass];
    NSString *attributeType = [attribute objectForKey:kCIAttributeType];

    if ([attributeClass isEqualToString:@"NSNumber"]) {
        if ([attributeType isEqualToString:kCIAttributeTypeBoolean]) {
            return [self booleanRowForFilterKey:filterKey inputKey:inputKey attribute:attribute rowWidth:rowWidth];
        }
        return [self numberRowForFilterKey:filterKey inputKey:inputKey attribute:attribute rowWidth:rowWidth];
    }
    if ([attributeClass isEqualToString:@"CIVector"]) {
        return [self vectorRowForFilterKey:filterKey inputKey:inputKey attribute:attribute rowWidth:rowWidth];
    }
    if ([attributeClass isEqualToString:@"CIColor"]) {
        return [self colorRowForFilterKey:filterKey inputKey:inputKey attribute:attribute rowWidth:rowWidth];
    }
    if ([attributeClass isEqualToString:@"NSString"]) {
        return [self fallbackRowForFilterKey:filterKey inputKey:inputKey attribute:attribute rowWidth:rowWidth];
    }
    return [self fallbackRowForFilterKey:filterKey inputKey:inputKey attribute:attribute rowWidth:rowWidth];
}

- (NSView *)baseViewForFilterKey:(NSString *)filterKey width:(CGFloat)contentWidth
{
    CIFilter *filter = [selectedFilters objectForKey:filterKey];
    NSString *localizedFilterName = [CIFilter localizedNameForFilterName:[filter name]];

    NSButton *closeBtn = [[[NSButton alloc] init] autorelease];
    [closeBtn setImage:[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate]];
    [closeBtn setBezelStyle:NSInlineBezelStyle];
    [closeBtn setBordered:NO];
    [closeBtn setFrameSize:NSMakeSize(15,16)];
    [closeBtn setTarget:self];
    [closeBtn setAction:@selector(deleteFilter:)];
    [closeBtn setIdentifier:[filter name]];
    [closeBtn setTag:kFilterCloseButtonTag];

    NSTextField *label = [NSTextField labelWithString:localizedFilterName];
    [label setTag:kFilterLabelTag];
    [[label cell] setLineBreakMode:NSLineBreakByTruncatingTail];

    CGFloat innerWidth = contentWidth - (kFilterBoxHorizontalPadding * 2.0);
    CGFloat currentY = kFilterBoxVerticalPadding;
    NSMutableArray *rowViews = [NSMutableArray array];
    NSEnumerator *enu = [[self editableInputKeysForFilter:filter] objectEnumerator];
    NSString *inputKey;
    while (inputKey = [enu nextObject]) {
        NSView *rowView = [self editorRowForFilterKey:filterKey inputKey:inputKey filter:filter rowWidth:innerWidth];
        [rowView setFrameOrigin:NSMakePoint(kFilterBoxHorizontalPadding, currentY)];
        [rowViews addObject:rowView];
        currentY += NSHeight([rowView frame]) + kFilterRowSpacing;
    }
    if ([rowViews count] > 0) {
        currentY -= kFilterRowSpacing;
    }
    currentY += kFilterBoxVerticalPadding;

    COVFilterBorderView *borderView = [[[COVFilterBorderView alloc] initWithFrame:NSMakeRect(0, 0, contentWidth, currentY)] autorelease];
    NSEnumerator *rowEnum = [rowViews objectEnumerator];
    NSView *rowView;
    while (rowView = [rowEnum nextObject]) {
        [borderView addSubview:rowView];
    }

    CGFloat headerOriginY = currentY + kFilterHeaderBottomSpacing;
    NSView *baseView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, contentWidth, headerOriginY + kFilterLabelHeight)] autorelease];
    [baseView addSubview:label];
    [baseView addSubview:closeBtn];
    [baseView addSubview:borderView];

    [borderView setFrameOrigin:NSMakePoint(0, 0)];
    CGFloat closeButtonX = contentWidth - kFilterCloseButtonRightInset - NSWidth([closeBtn frame]);
    CGFloat closeButtonY = headerOriginY + floor((kFilterLabelHeight - NSHeight([closeBtn frame])) / 2.0);
    CGFloat labelWidth = closeButtonX - kFilterHeaderHorizontalPadding - kFilterTitleToButtonSpacing;
    [closeBtn setFrameOrigin:NSMakePoint(closeButtonX, closeButtonY)];
    [label setFrame:NSMakeRect(kFilterHeaderHorizontalPadding, headerOriginY, MAX(0, labelWidth), kFilterLabelHeight)];
    [baseView setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];
    return baseView;
}

-(void)awakeFromNib
{
    [filterPanel setFrameAutosaveName:@"FilterPanel"];
    [self ensureFilterPanelMinimumSize];

    filterDic = [[NSMutableDictionary alloc] init];
    selectedFilterUIViews = [[NSMutableDictionary alloc] init];
    controlViewsByIdentifier = [[NSMutableDictionary alloc] init];
    [CIPlugIn loadAllPlugIns];

    NSArray *usingCategories =
        [NSArray arrayWithObjects:
                        [NSArray arrayWithObjects:kCICategoryColorAdjustment,kCICategoryStillImage, nil],
                        [NSArray arrayWithObjects:kCICategoryColorEffect,kCICategoryStillImage, nil],
                        [NSArray arrayWithObjects:kCICategorySharpen,kCICategoryStillImage, nil],
                        [NSArray arrayWithObjects:kCICategoryBlur,kCICategoryStillImage, nil],
                        nil
          ];

    NSEnumerator *catenu = [usingCategories objectEnumerator];
    NSArray *cate;
    [popupButton addItemWithTitle:@""];
    while (cate = [catenu nextObject]) {
        NSArray *filters = [CIFilter filterNamesInCategories:cate];
        NSEnumerator *enu = [filters objectEnumerator];
        NSString *filterName;
        while (filterName = [enu nextObject]) {
            [filterDic setObject:filterName forKey:[CIFilter localizedNameForFilterName:filterName]];
            [popupButton addItemWithTitle:[CIFilter localizedNameForFilterName:filterName]];
        }
    }

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
            }
        }
        [self drawFilterUIViews];
        [self sendNotification];
    }
    [self applyDebugPresetIfNeeded];
}
- (IBAction)openFilterPanel:(id)sender
{
    [self ensureFilterPanelMinimumSize];
    [filterPanel orderFront:self];
}
- (IBAction)filterSelected:(id)sender
{
    NSString *filterName = [filterDic objectForKey:[sender title]];
    if ([selectedFilterKeys containsObject:filterName]!=YES) {
        CIFilter *newFilter = [CIFilter filterWithName:filterName];
        if (newFilter) {
            [newFilter setDefaults];
            [selectedFilterKeys addObject:filterName];
            [selectedFilters setObject:newFilter forKey:filterName];
            [self drawFilterUIViews];
        }
    }
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
    [controlViewsByIdentifier removeAllObjects];

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
- (void)numberSliderChanged:(id)sender
{
    NSArray *parts = COVControlIdentifierComponents([sender identifier]);
    if ([parts count] < 4) return;
    NSString *filterKey = [parts objectAtIndex:0];
    NSString *inputKey = [parts objectAtIndex:1];
    NSDictionary *attribute = [(NSDictionary *)[[selectedFilters objectForKey:filterKey] attributes] objectForKey:inputKey];
    NSNumber *number = [self clampedNumberFromValue:[sender doubleValue] attribute:attribute];
    [self syncNumericFieldForFilterKey:filterKey inputKey:inputKey number:number integral:COVNumberIsIntegralType(attribute)];
    [self applyFilterValue:number filterKey:filterKey inputKey:inputKey];
}
- (void)numberFieldChanged:(id)sender
{
    NSArray *parts = COVControlIdentifierComponents([sender identifier]);
    if ([parts count] < 4) return;
    NSString *filterKey = [parts objectAtIndex:0];
    NSString *inputKey = [parts objectAtIndex:1];
    NSDictionary *attribute = [(NSDictionary *)[[selectedFilters objectForKey:filterKey] attributes] objectForKey:inputKey];
    NSNumber *number = [self clampedNumberFromValue:[[sender stringValue] doubleValue] attribute:attribute];
    [self syncNumericFieldForFilterKey:filterKey inputKey:inputKey number:number integral:COVNumberIsIntegralType(attribute)];
    [self syncSliderForFilterKey:filterKey inputKey:inputKey number:number];
    [self applyFilterValue:number filterKey:filterKey inputKey:inputKey];
}
- (void)booleanValueChanged:(id)sender
{
    NSArray *parts = COVControlIdentifierComponents([sender identifier]);
    if ([parts count] < 4) return;
    NSNumber *value = [NSNumber numberWithBool:([sender state] == NSControlStateValueOn)];
    [self applyFilterValue:value filterKey:[parts objectAtIndex:0] inputKey:[parts objectAtIndex:1]];
}
- (void)vectorFieldChanged:(id)sender
{
    NSArray *parts = COVControlIdentifierComponents([sender identifier]);
    if ([parts count] < 4) return;
    NSString *filterKey = [parts objectAtIndex:0];
    NSString *inputKey = [parts objectAtIndex:1];
    NSDictionary *attribute = [(NSDictionary *)[[selectedFilters objectForKey:filterKey] attributes] objectForKey:inputKey];
    CIVector *currentVector = [[selectedFilters objectForKey:filterKey] valueForKey:inputKey];
    NSInteger count = COVVectorComponentCount(currentVector, attribute);
    CGFloat values[4] = {0,0,0,0};
    NSInteger index;
    for (index = 0; index < count; index++) {
        NSString *identifier = COVControlIdentifier(filterKey, inputKey, @"vector", index);
        NSTextField *field = [controlViewsByIdentifier objectForKey:identifier];
        values[index] = [[field stringValue] doubleValue];
    }
    CIVector *vector;
    if (count == 2) {
        vector = [CIVector vectorWithX:values[0] Y:values[1]];
    } else {
        vector = [CIVector vectorWithX:values[0] Y:values[1] Z:values[2] W:values[3]];
    }
    [self applyFilterValue:vector filterKey:filterKey inputKey:inputKey];
}
- (void)colorValueChanged:(id)sender
{
    NSArray *parts = COVControlIdentifierComponents([sender identifier]);
    if ([parts count] < 4) return;
    NSColor *color = [[sender color] colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
    CIColor *ciColor = [CIColor colorWithRed:[color redComponent]
                                       green:[color greenComponent]
                                        blue:[color blueComponent]
                                       alpha:[color alphaComponent]];
    [self applyFilterValue:ciColor filterKey:[parts objectAtIndex:0] inputKey:[parts objectAtIndex:1]];
}
- (void)windowDidResize:(NSNotification *)notification
{
    if ([notification object] == filterPanel) {
        [self drawFilterUIViews];
    }
}
- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    return YES;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self sendNotification];
    [self setUserDefaults];
}
- (void)deleteFilter:(id)sender
{
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
    NSSize minContentSize = NSMakeSize(minContentWidth, currentContentSize.height);
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
- (void)setUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selectedFilters];
    [defaults setObject:data forKey:@"CIFilters"];
    [defaults setObject:selectedFilterKeys forKey:@"CIFilterKeys"];
}
- (void)sendNotification
{
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:selectedFilterKeys,@"keys",selectedFilters,@"filters",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FilterUIValueDidChange" object:dic];
}
@end
