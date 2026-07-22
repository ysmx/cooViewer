#import "COColorPopUpButton.h"
#import <math.h>


@implementation COColorPopUpButton
- (BOOL)co_color:(NSColor *)color matchesPresetColor:(NSColor *)presetColor
{
	if (!color || !presetColor) return NO;
	
	NSColorSpace *colorSpace = [NSColorSpace genericRGBColorSpace];
	NSColor *rgbColor = [color colorUsingColorSpace:colorSpace];
	NSColor *rgbPresetColor = [presetColor colorUsingColorSpace:colorSpace];
	if (!rgbColor || !rgbPresetColor) return [color isEqualTo:presetColor];
	
	CGFloat red, green, blue, alpha;
	CGFloat presetRed, presetGreen, presetBlue, presetAlpha;
	[rgbColor getRed:&red green:&green blue:&blue alpha:&alpha];
	[rgbPresetColor getRed:&presetRed green:&presetGreen blue:&presetBlue alpha:&presetAlpha];
	
	return (fabs(red-presetRed) < 0.001 &&
			fabs(green-presetGreen) < 0.001 &&
			fabs(blue-presetBlue) < 0.001 &&
			fabs(alpha-presetAlpha) < 0.001);
}

// Shared by the non-Clear branch of -co_configureMenuItems, -setCurrentColor:, and
// -changeColor:, which all drew this same gray-framed, solid-filled 12x12 swatch inline.
// The Clear item's swatch is drawn separately below since it's a genuinely different
// shape (a diagonal strike, not a fill).
- (NSImage*)co_swatchImageForColor:(NSColor*)color
{
	NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(12,12)] autorelease];
	[image lockFocus];
	[[NSColor grayColor] set];
	NSFrameRect(NSMakeRect(0,0,12,12));
	[color set];
	NSRectFill(NSMakeRect(1,1,10,10));
	[image unlockFocus];
	return image;
}

- (void)co_configureMenuItems
{
	NSImage *image;
	NSMenuItem *item;
	NSColor *frameColor = [NSColor grayColor];
	NSColor *fillColor;

	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];

	[self removeAllItems];
	[self addItemWithTitle:@"White"];
	[self addItemWithTitle:@"White_0.5"];
	[self addItemWithTitle:@"LightGray"];
	[self addItemWithTitle:@"Gray"];
	[self addItemWithTitle:@"DarkGray"];
	[self addItemWithTitle:@"Black"];
	[self addItemWithTitle:@"Black_0.8"];
	[self addItemWithTitle:@"Blue"];
	[self addItemWithTitle:@"Cyan"];
	[self addItemWithTitle:@"Green"];
	[self addItemWithTitle:@"Magenta"];
	[self addItemWithTitle:@"Orange"];
	[self addItemWithTitle:@"Purple"];
	[self addItemWithTitle:@"Red"];
	[self addItemWithTitle:@"Yellow"];
	[self addItemWithTitle:@"Clear"];
	[self addItemWithTitle:@"Other..."];

	NSArray *itemArray = [self itemArray];
	int i;
	for (i=0;i<[itemArray count];i++) {
		item = (NSMenuItem*)[self itemAtIndex:i];
		NSString *title = [item title];

		if ([title isEqualToString:@"Other..."]) {
			[item setAction:@selector(selectItem:)];
			[item setTarget:self];
			return;
		} else if ([title isEqualToString:@"White"]) {
			fillColor = [NSColor whiteColor];
		} else if ([title isEqualToString:@"White_0.5"]) {
			fillColor = [[NSColor whiteColor] colorWithAlphaComponent:0.5];
		} else if ([title isEqualToString:@"LightGray"]) {
			fillColor = [NSColor lightGrayColor];
		} else if ([title isEqualToString:@"Gray"]) {
			fillColor = [NSColor grayColor];
		} else if ([title isEqualToString:@"DarkGray"]) {
			fillColor = [NSColor darkGrayColor];
		} else if ([title isEqualToString:@"Black"]) {
			fillColor = [NSColor blackColor];
		} else if ([title isEqualToString:@"Black_0.8"]) {
			fillColor = [[NSColor blackColor] colorWithAlphaComponent:0.8];
		} else if ([title isEqualToString:@"Blue"]) {
			fillColor = [NSColor blueColor];
		} else if ([title isEqualToString:@"Cyan"]) {
			fillColor = [NSColor cyanColor];
		} else if ([title isEqualToString:@"Green"]) {
			fillColor = [NSColor greenColor];
		} else if ([title isEqualToString:@"Magenta"]) {
			fillColor = [NSColor magentaColor];
		} else if ([title isEqualToString:@"Orange"]) {
			fillColor = [NSColor orangeColor];
		} else if ([title isEqualToString:@"Purple"]) {
			fillColor = [NSColor purpleColor];
		} else if ([title isEqualToString:@"Red"]) {
			fillColor = [NSColor redColor];
		} else if ([title isEqualToString:@"Yellow"]) {
			fillColor = [NSColor yellowColor];
		}
		if ([title isEqualToString:@"Clear"]) {
			fillColor = [NSColor clearColor];
			NSBezierPath *path = [[NSBezierPath alloc] init];
			[path moveToPoint:NSMakePoint(0,0)];
			[path lineToPoint:NSMakePoint(12,12)];
			[path moveToPoint:NSMakePoint(12,0)];
			[path lineToPoint:NSMakePoint(0,12)];
			image = [[NSImage alloc] initWithSize:NSMakeSize(12,12)];
			[image lockFocus];
			[frameColor set];
			NSFrameRect(NSMakeRect(0,0,12,12));
			[path stroke];
			[image unlockFocus];
			[item setImage:image];
			[item setAction:@selector(selectItem:)];
			[item setTarget:self];
			[item setRepresentedObject:fillColor];
			[image release];
			[path release];
		} else {
			image = [self co_swatchImageForColor:fillColor];
			[item setImage:image];
			[item setAction:@selector(selectItem:)];
			[item setTarget:self];
			[item setRepresentedObject:fillColor];
		}
	}
}

- (id)initWithFrame:(NSRect)buttonFrame pullsDown:(BOOL)flag
{
	self = [super initWithFrame:buttonFrame pullsDown:flag];
	if (self) {
		[self co_configureMenuItems];
	}
	return self;
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[[aNotification object] orderOut:self];
	[self changeColor:[aNotification object]];
}

- (void)setCurrentColor:(NSColor*)aColor
{
	[currentColor autorelease];
	currentColor = [aColor retain];
	
	NSArray *itemArray = [self itemArray];
	int i;
	for (i=0;i<[itemArray count];i++) {
		NSMenuItem *item = [self itemAtIndex:i];
		if ([self co_color:aColor matchesPresetColor:[item representedObject]]) {
			[self selectItemAtIndex:i];
			item = (NSMenuItem*)[self lastItem];
			[item setImage:nil];
			return;
		}
	}
	
	NSMenuItem *item = [self lastItem];
	NSImage *image = [self co_swatchImageForColor:currentColor];
	[item setImage:image];
	[self selectItemAtIndex:[self numberOfItems]-1];
}

- (NSColor*)currentColor
{
	return currentColor;
}
- (void)changeColor:(id)sender
{
	[currentColor autorelease];
	currentColor = [[sender color] retain];
	
	NSMenuItem *item = [self lastItem];
	NSImage *image = [self co_swatchImageForColor:currentColor];
	[item setImage:image];
	[self selectItemAtIndex:[self numberOfItems]-1];

	[[self target] performSelector:[self action] withObject:self];
}

- (void)selectItem:(id)sender
{
	if (sender == [self lastItem]) {
		NSColorPanel *panel = [NSColorPanel sharedColorPanel];
		[panel setColor:currentColor];
		[panel setLevel:NSMainMenuWindowLevel];
		[panel setContinuous:NO];
		[panel setDelegate:(id)self];
		[panel makeKeyAndOrderFront:self];
	} else {
		[self setCurrentColor:[sender representedObject]];
		[[self target] performSelector:[self action] withObject:self];
	}
}

-(void)awakeFromNib
{
	[self co_configureMenuItems];
}

@end
