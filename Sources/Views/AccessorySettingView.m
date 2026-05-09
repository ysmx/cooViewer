//
//  AccessorySettingView.m
//  cooViewer
//
//  Created by coo on 08/02/15.
//  Copyright 2008 coo. All rights reserved.
//

#import "AccessorySettingView.h"
#import "NSBezierPath_Adding.h"
#import "NSAttributedString_Adding.h"
#import "Controller.h"

@interface AccessorySettingView ()
-(int)placementForPoint:(NSPoint)point;
-(void)setAccessoryPlacement:(int)placement;
@end

@implementation AccessorySettingView
-(void)setPreferences
{
	[super setPreferences];
	autoHidePageBar = NO;
	autoHidedPageBar = NO;
	autoHidePageString = NO;
	autoHidedPageString = NO;
}
-(void)setPageBarBGColor:(NSColor*)color
{
	[pageBarBGColor release];
	pageBarBGColor = [color retain];
}
-(void)setPageBarBorderColor:(NSColor*)color
{
	[pageBarBorderColor release];
	pageBarBorderColor = [color retain];
}
-(void)setPageBarReadedColor:(NSColor*)color
{
	[pageBarReadedColor release];
	pageBarReadedColor = [color retain];
}

-(void)setTextFontColor:(NSColor*)color
{
	[textFontColor release];
	textFontColor = [color retain];
}
-(void)setTextBGColor:(NSColor*)color
{
	[textBGColor release];
	textBGColor = [color retain];
}
-(void)setTextBorderColor:(NSColor*)color
{
	[textBorderColor release];
	textBorderColor = [color retain];
}
-(void)setTextFont:(NSFont*)font
{
	[textFont release];
	textFont = [font retain];
}


-(void)drawRect:(NSRect)frameRect
{	
	if (positionSettingMode>=0) {
		NSColor *backgroundColor = [[self window] backgroundColor];
		if (!backgroundColor) backgroundColor = [NSColor blackColor];
		[backgroundColor set];
		NSRectFill([self bounds]);
		
		pageBarRect = [self pageBarRect];
		float pbWidth = pageBarRect.size.width;
		
		float nowPar = 0.3;
		float now = nowPar*pbWidth;
		
		NSRect innerRect = NSInsetRect(pageBarRect,1,1);
		NSBezierPath *base = [NSBezierPath bezierPathWithRectWithDoubleArc:innerRect];
		[base closePath];
		if (![pageBarBGColor isEqualTo:[NSColor clearColor]]) {
			[pageBarBGColor set];
			[base fill];
		}
		if (![pageBarReadedColor isEqualTo:[NSColor clearColor]]) {
			NSRect slice,remainder;
			if ([controller readFromLeft]) {
				NSDivideRect(innerRect, &slice, &remainder, now, NSMinXEdge);
			} else {
				NSDivideRect(innerRect, &slice, &remainder, now, NSMaxXEdge);
			}
			
			[NSGraphicsContext saveGraphicsState]; 		
			[base addClip]; 
			[pageBarReadedColor set];
			NSRectFillUsingOperation(slice,NSCompositingOperationSourceOver);
			[NSGraphicsContext restoreGraphicsState]; 		
		}
		if (![pageBarBorderColor isEqualTo:[NSColor clearColor]]) {
			[pageBarBorderColor set];
			[base stroke];
		}
		NSImage *resizeIndicator = [NSImage imageNamed:@"NSGrayResizeCorner"];
		
		NSRect tempRect = pageBarRect;
		tempRect.origin.x += tempRect.size.width-10;
		tempRect.size.width = 10;
		tempRect.size.height = 10;
		[resizeIndicator drawInRect:tempRect fromRect:NSMakeRect(0,0,15,15) operation:NSCompositingOperationSourceOver fraction:1.0];
		
		NSBezierPath *path = [NSBezierPath bezierPath];
			switch (pageBarPosition) {
				case 0:
					[path moveToPoint:NSMakePoint(0,pageBarRect.origin.y+pageBarRect.size.height)];
					[path lineToPoint:NSMakePoint(pageBarRect.origin.x,pageBarRect.origin.y+pageBarRect.size.height)];
					[path moveToPoint:NSMakePoint(pageBarRect.origin.x,[self visibleRect].size.height)];
					[path lineToPoint:NSMakePoint(pageBarRect.origin.x,pageBarRect.origin.y+pageBarRect.size.height)];
					break;
				case COAccessoryPlacementTopCenter:
					[path moveToPoint:NSMakePoint(NSMidX(pageBarRect),pageBarRect.origin.y+pageBarRect.size.height)];
					[path lineToPoint:NSMakePoint(NSMidX(pageBarRect),[self visibleRect].size.height)];
					break;
				case 1:
					[path moveToPoint:NSMakePoint([self visibleRect].size.width,pageBarRect.origin.y+pageBarRect.size.height)];
					[path lineToPoint:NSMakePoint(pageBarRect.origin.x+pageBarRect.size.width,pageBarRect.origin.y+pageBarRect.size.height)];
					[path moveToPoint:NSMakePoint(pageBarRect.origin.x+pageBarRect.size.width,[self visibleRect].size.height)];
					[path lineToPoint:NSMakePoint(pageBarRect.origin.x+pageBarRect.size.width,pageBarRect.origin.y+pageBarRect.size.height)];
				break;
				case 2:
					[path moveToPoint:NSMakePoint(0,pageBarRect.origin.y)];
					[path lineToPoint:NSMakePoint(pageBarRect.origin.x,pageBarRect.origin.y)];
					[path moveToPoint:NSMakePoint(pageBarRect.origin.x,0)];
					[path lineToPoint:NSMakePoint(pageBarRect.origin.x,pageBarRect.origin.y)];
					break;
				case COAccessoryPlacementBottomCenter:
					[path moveToPoint:NSMakePoint(NSMidX(pageBarRect),0)];
					[path lineToPoint:NSMakePoint(NSMidX(pageBarRect),pageBarRect.origin.y)];
					break;
				case 3:
					[path moveToPoint:NSMakePoint([self visibleRect].size.width,pageBarRect.origin.y)];
					[path lineToPoint:NSMakePoint(pageBarRect.origin.x+pageBarRect.size.width,pageBarRect.origin.y)];
					[path moveToPoint:NSMakePoint(pageBarRect.origin.x+pageBarRect.size.width,0)];
					[path lineToPoint:NSMakePoint(pageBarRect.origin.x+pageBarRect.size.width,pageBarRect.origin.y)];
				break;
			default:
				break;
		}
		[[[NSColor grayColor] colorWithAlphaComponent:0.8] set];
		CGFloat array[2];
		array[0] = 3.0;
		array[1] = 5.0;
		[path setLineDash:array count:2 phase:0.0];
		[path stroke];
		
		
		pageStringRect = [self pageStringRect];
		[pageString drawAtPoint:pageStringRect.origin bg:textBGColor border:textBorderColor];
		path = [NSBezierPath bezierPath];
			switch (pageStringPosition) {
				case 0:
					[path moveToPoint:NSMakePoint(0,pageStringRect.origin.y+pageStringRect.size.height)];
					[path lineToPoint:NSMakePoint(pageStringRect.origin.x,pageStringRect.origin.y+pageStringRect.size.height)];
					[path moveToPoint:NSMakePoint(pageStringRect.origin.x,[self visibleRect].size.height)];
					[path lineToPoint:NSMakePoint(pageStringRect.origin.x,pageStringRect.origin.y+pageStringRect.size.height)];
					break;
				case COAccessoryPlacementTopCenter:
					[path moveToPoint:NSMakePoint(NSMidX(pageStringRect),pageStringRect.origin.y+pageStringRect.size.height)];
					[path lineToPoint:NSMakePoint(NSMidX(pageStringRect),[self visibleRect].size.height)];
					break;
				case 1:
					[path moveToPoint:NSMakePoint([self visibleRect].size.width,pageStringRect.origin.y+pageStringRect.size.height)];
					[path lineToPoint:NSMakePoint(pageStringRect.origin.x+pageStringRect.size.width,pageStringRect.origin.y+pageStringRect.size.height)];
					[path moveToPoint:NSMakePoint(pageStringRect.origin.x+pageStringRect.size.width,[self visibleRect].size.height)];
					[path lineToPoint:NSMakePoint(pageStringRect.origin.x+pageStringRect.size.width,pageStringRect.origin.y+pageStringRect.size.height)];
				break;
				case 2:
					[path moveToPoint:NSMakePoint(0,pageStringRect.origin.y)];
					[path lineToPoint:NSMakePoint(pageStringRect.origin.x,pageStringRect.origin.y)];
					[path moveToPoint:NSMakePoint(pageStringRect.origin.x,0)];
					[path lineToPoint:NSMakePoint(pageStringRect.origin.x,pageStringRect.origin.y)];
					break;
				case COAccessoryPlacementBottomCenter:
					[path moveToPoint:NSMakePoint(NSMidX(pageStringRect),0)];
					[path lineToPoint:NSMakePoint(NSMidX(pageStringRect),pageStringRect.origin.y)];
					break;
				case 3:
					[path moveToPoint:NSMakePoint([self visibleRect].size.width,pageStringRect.origin.y)];
					[path lineToPoint:NSMakePoint(pageStringRect.origin.x+pageStringRect.size.width,pageStringRect.origin.y)];
					[path moveToPoint:NSMakePoint(pageStringRect.origin.x+pageStringRect.size.width,0)];
					[path lineToPoint:NSMakePoint(pageStringRect.origin.x+pageStringRect.size.width,pageStringRect.origin.y)];
				break;
			default:
				break;
		}
		[[[NSColor grayColor] colorWithAlphaComponent:0.8] set];
		[path setLineDash:array count:2 phase:0.0];
		[path stroke];
		
		
		return;
	}
	[super drawRect:frameRect];
}

-(NSRect)pageBarRect
{	
	NSRect contentFrame = [self frame];
	return [self pageBarLayoutRectForContentFrame:contentFrame avoidPageString:YES];
}

-(NSRect)pageStringRect
{
	NSRect contentFrame = [self frame];
	return [self pageStringLayoutRectForContentFrame:contentFrame];
}

-(void)resetPageNumberPositionToDefaults
{
	[self setAccessoryPlacement:COAccessoryPlacementTopLeft];
	[self display];
}

-(void)resetPageBarPositionAndSizeToDefaults
{
	[self setAccessoryPlacement:COAccessoryPlacementTopLeft];
	pageBarWidth = 200;
	pageBarHeight = 15;
	pageBarRect = [self pageBarRect];
	[self display];
}

-(void)setPositionSettingMode:(BOOL)b
{
	if (b) {
		positionSettingMode = 1;
		if (pageStringPosition < COAccessoryPlacementTopLeft || pageStringPosition > COAccessoryPlacementBottomCenter) {
			pageStringPosition = COAccessoryPlacementTopLeft;
		}
		[self setAccessoryPlacement:pageStringPosition];
	} else {
		positionSettingMode = 0;
	}
	[pageStringAttr release];
	if ([textBGColor isEqualTo:[NSColor clearColor]]) {
		NSColor *shadowColor = [textFontColor colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
		CGFloat white,alpha;
		[shadowColor getWhite:&white alpha:&alpha];
		NSShadow *shadow = [[NSShadow alloc] init];
		[shadow setShadowBlurRadius:white];
		[shadow setShadowColor:textFontColor];
		pageStringAttr = [[NSDictionary dictionaryWithObjectsAndKeys:
			textFontColor,NSForegroundColorAttributeName,
			textFont,NSFontAttributeName,
			shadow,NSShadowAttributeName,
			nil] retain];
		[shadow release];
	} else {
		pageStringAttr = [[NSDictionary dictionaryWithObjectsAndKeys:
			textFontColor,NSForegroundColorAttributeName,
			textFont,NSFontAttributeName,
			nil] retain];
	}
	[self setPageString:[pageString string]];
}

-(BOOL)positionSettingMode
{
	if (positionSettingMode>0) {
		return YES;
	}
	return NO;
}


#pragma mark PositionSetting
-(int)placementForPoint:(NSPoint)point
{
	NSRect rect = [self visibleRect];
	CGFloat leftThird = NSMinX(rect)+NSWidth(rect)/3;
	CGFloat rightThird = NSMinX(rect)+NSWidth(rect)*2/3;
	BOOL top = (point.y >= NSMidY(rect));
	
	if (point.x < leftThird) {
		return top ? COAccessoryPlacementTopLeft : COAccessoryPlacementBottomLeft;
	}
	if (point.x >= rightThird) {
		return top ? COAccessoryPlacementTopRight : COAccessoryPlacementBottomRight;
	}
	return top ? COAccessoryPlacementTopCenter : COAccessoryPlacementBottomCenter;
}

-(void)setAccessoryPlacement:(int)placement
{
	pageStringPosition = placement;
	pageBarPosition = placement;
	pageMargin = NSZeroPoint;
	pageBarMargin = NSZeroPoint;
	pageStringRect = [self pageStringRect];
	pageBarRect = [self pageBarRect];
}

-(void)mouseDown:(NSEvent*)event
{
	pageBarRect = [self pageBarRect];
	NSRect tempRect = pageBarRect;
	tempRect.origin.x += tempRect.size.width-10;
	tempRect.size.width = 10;
	tempRect.size.height = 10;
	
	mouseOldPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	if (NSPointInRect(mouseOldPoint,tempRect)) {
		positionSettingMode = 3;
	} else {
		positionSettingMode = 2;
		[self setAccessoryPlacement:[self placementForPoint:mouseOldPoint]];
		[self display];
	}
	
	//NSLog(@"mouseDown %i",positionSettingMode);
}
-(void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint newMousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (!NSPointInRect(newMousePoint,[self visibleRect])) return;;
	float xMoved = newMousePoint.x-mouseOldPoint.x;
	switch (positionSettingMode) {
		case 3:
			pageBarWidth += xMoved;
			if (pageBarWidth <= 0) {
				pageBarWidth -= xMoved;
			}
			if (pageBarWidth < pageBarHeight) {
				pageBarWidth = pageBarHeight;
			} 
			break;
		default:
			[self setAccessoryPlacement:[self placementForPoint:newMousePoint]];
			break;
	}
	pageStringRect = [self pageStringRect];
	pageBarRect = [self pageBarRect];
	[self display];
	
	mouseOldPoint = newMousePoint;
	//NSLog(@"mouseDragged %i",positionSettingMode);
}
-(void)mouseUp:(NSEvent *)theEvent
{
	positionSettingMode = 0;
	//NSLog(@"mouseUp %i",positionSettingMode);
}


#pragma mark return
-(int)pageBarPosition
{
	return pageBarPosition;
}
-(int)pageNumPosition
{
	return pageStringPosition;
}
-(NSDictionary*)pageMargin
{
	NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:pageMargin.x],@"x",
		[NSNumber numberWithInt:pageMargin.y],@"y",nil];
	return dic;
}
-(NSDictionary*)pageBarMargin
{
	NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:pageBarMargin.x],@"x",
		[NSNumber numberWithInt:pageBarMargin.y],@"y",nil];
	return dic;
}
-(NSDictionary*)pageBarSize
{
	NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:pageBarWidth],@"width",
		[NSNumber numberWithInt:pageBarHeight],@"height",nil];
	return dic;
}
@end
