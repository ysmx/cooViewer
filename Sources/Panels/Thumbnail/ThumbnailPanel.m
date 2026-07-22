#import "ThumbnailPanel.h"

@implementation ThumbnailPanel

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	self = [super initWithContentRect:contentRect
							styleMask:NSWindowStyleMaskBorderless
							  backing:bufferingType
								defer:deferCreation
		];
	return self;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation screen:(NSScreen *)screen
{
	self = [super initWithContentRect:contentRect
							styleMask:NSWindowStyleMaskBorderless
							  backing:bufferingType
								defer:deferCreation
							   screen:screen
		];
	return self;
}

-(BOOL)canBecomeKeyWindow{return YES;}

-(void)awakeFromNib
{
	[self setAcceptsMouseMovedEvents:YES];
	[self makeFirstResponder:matrix];
}

- (void)setTarget:(ThumbnailController *)tar
{
	target = tar;
}

- (void)setAction:(SEL)sel
{
	selector = sel;
}
/*
- (void)mouseMoved:(NSEvent *)theEvent
{
	[super mouseMoved:theEvent];
	NSLog(@"kita0");
}
*/
-(void)becomeKeyWindow
{
	[super becomeKeyWindow];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DontHideMenuBar"] == NO) [NSMenu setMenuBarVisible:NO];
}

-(void)resignKeyWindow
{
	//[self performClose:self];
	[super resignKeyWindow];
}


-(NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)aScreen
{
	if ([NSMenu menuBarVisible]) {
		NSRect result = [[NSScreen mainScreen] frame];
		result.size.height -= 6;
		return result;
	}
	return [super constrainFrameRect:[[NSScreen mainScreen] frame] toScreen:aScreen];
}



- (void)performClose:(id)sender
{
	[self close];
	[target performSelector:@selector(clearCell)];
}

- (void)sendEvent:(NSEvent *)theEvent
{
	if ([theEvent type] == NSEventTypeKeyDown) {
		[target performSelector:@selector(action:) withObject:theEvent];
	} else {
		[super sendEvent:theEvent];
	}
}
/*
- (void)keyDown:(NSEvent *)theEvent
{
	NSLog(@"kita");
	[target performSelector:@selector(action:) withObject:theEvent];
}*/



- (void)scrollWheel:(NSEvent *)theEvent
{
	if (setting == 0) {
		return;
	}
	[target performSelector:@selector(wheelAction:) withObject:theEvent];
}

-(void)wheelSetting:(float)set
{
	setting = set;
}

@end
