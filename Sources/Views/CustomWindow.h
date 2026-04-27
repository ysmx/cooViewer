/* CustomWindow */

#import <Cocoa/Cocoa.h>
#import "CustomImageView.h"

@interface CustomWindow : NSWindow
{
	BOOL fullscreen;
	
	id target;
	SEL selector;
	
	IBOutlet id controller;
	NSTimer *cursorTimer;
	NSTrackingRectTag tag;
	NSRect mouseRect;
	BOOL hideMenuBar;
	BOOL resizable;
	NSUInteger windowedStyleMask;
	CustomImageView *view;
}
- (void)setFullScreen:(BOOL)b;
- (BOOL)isFullScreen;

- (void)setHideMenuBar:(BOOL)b;
- (void)performMiniaturize:(id)sender;
- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)aScreen;
- (void)keyDown:(NSEvent *)theEvent;
- (void)flagsChanged:(NSEvent *)theEvent;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)updateTrackingRect;
- (void)refreshCursorAutoHide;
- (void)refreshMenuBarVisibility;

@end
