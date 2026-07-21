//
//  AccessoryGeometry.m
//  cooViewer
//
//  Pure layout/geometry helpers used by AccessoryView, split out so they
//  can be unit tested without pulling in the rest of the view hierarchy.
//

#import "AccessoryGeometry.h"

NSRect COIntRect(NSRect aRect)
{
	NSRect tempRect = aRect;
	tempRect.origin.x = (int)(tempRect.origin.x+0.5);
	tempRect.origin.y = (int)(tempRect.origin.y+0.5);
	tempRect.size.width = (int)(tempRect.size.width+0.5);
	tempRect.size.height = (int)(tempRect.size.height+0.5);
	return tempRect;
}

BOOL COAccessoryPlacementIsTop(int placement)
{
	return (placement == COAccessoryPlacementTopLeft ||
			placement == COAccessoryPlacementTopRight ||
			placement == COAccessoryPlacementTopCenter);
}

BOOL COAccessoryPlacementIsRight(int placement)
{
	return (placement == COAccessoryPlacementTopRight ||
			placement == COAccessoryPlacementBottomRight);
}

BOOL COAccessoryPlacementIsCenter(int placement)
{
	return (placement == COAccessoryPlacementTopCenter ||
			placement == COAccessoryPlacementBottomCenter);
}

NSRect COPageBarLayoutRect(NSRect contentFrame, NSPoint margin, float widthValue, float heightValue, int position)
{
	float width = widthValue+1;
	float height = heightValue+1;
	NSRect rect;
	switch (position) {
		case COAccessoryPlacementTopLeft:
			rect = NSMakeRect(contentFrame.origin.x+margin.x+2,
							  contentFrame.size.height-17-height-margin.y-3,
							  width,height);
			break;
		case COAccessoryPlacementTopRight:
			rect = NSMakeRect(contentFrame.origin.x+contentFrame.size.width-width-margin.x-3,
							  contentFrame.origin.y-17-height+contentFrame.size.height-margin.y-3,
							  width,height);
			break;
		case COAccessoryPlacementBottomLeft:
			rect = NSMakeRect(contentFrame.origin.x+margin.x+2,
							  contentFrame.origin.y+margin.y+2,
							  width,height);
			break;
		case COAccessoryPlacementBottomRight:
			rect = NSMakeRect(contentFrame.origin.x+contentFrame.size.width-width-margin.x-3,
							  contentFrame.origin.y+margin.y+2,
							  width,height);
			break;
		case COAccessoryPlacementTopCenter:
			rect = NSMakeRect(contentFrame.origin.x+(contentFrame.size.width-width)/2,
							  contentFrame.size.height-17-height-margin.y-3,
							  width,height);
			break;
		case COAccessoryPlacementBottomCenter:
			rect = NSMakeRect(contentFrame.origin.x+(contentFrame.size.width-width)/2,
							  contentFrame.origin.y+margin.y+2,
							  width,height);
			break;
		default:
			rect = NSMakeRect(0,0,width,height);
			break;
	}
	return COIntRect(rect);
}

static NSSize COPageStringDrawingSize(NSAttributedString *string)
{
	if (!string) return NSZeroSize;
	NSRect rect = [string boundingRectWithSize:NSMakeSize(100000.0, 100000.0)
									   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading];
	return NSMakeSize(ceil(rect.size.width), ceil(rect.size.height));
}

static NSSize COPageStringSizeWithBG(NSAttributedString *string)
{
	NSSize drawingSize = COPageStringDrawingSize(string);
	return NSMakeSize(drawingSize.width+18,drawingSize.height+10);
}

CGFloat COPageStringTextLeftOffset(void)
{
	return 9.0;
}

static BOOL COColorShouldDraw(NSColor *color)
{
	if (!color || [color isEqualTo:[NSColor clearColor]]) return NO;
	return ([color alphaComponent] > 0.0);
}

void CODrawPageStringAtPoint(NSAttributedString *string, NSPoint pt, NSColor *bg, NSColor *border)
{
	if (!string) return;

	NSSize totalSize = COPageStringSizeWithBG(string);
	NSRect backgroundRect = NSMakeRect(pt.x+1,pt.y+1,totalSize.width-2,totalSize.height-2);
	NSRect stringRect = NSInsetRect(backgroundRect,COPageStringTextLeftOffset()-1.0,4);
	BOOL drawBG = COColorShouldDraw(bg);
	BOOL drawBorder = COColorShouldDraw(border);

	if (drawBG || drawBorder) {
		NSBezierPath *bezier = [NSBezierPath bezierPathWithRoundedRect:backgroundRect xRadius:6.0 yRadius:6.0];
		if (drawBG) {
			[bg set];
			[bezier fill];
		}
		if (drawBorder) {
			[border set];
			[bezier stroke];
		}
	}
	[string drawInRect:stringRect];
}

NSRect COPageStringLayoutRect(NSRect contentFrame, NSAttributedString *string, NSPoint margin, int position)
{
	NSSize pageStringSize = COPageStringSizeWithBG(string);
	NSRect rect = NSMakeRect(0,0,pageStringSize.width,pageStringSize.height);
	rect.size.width = rect.size.width + 1;
	rect.size.height = rect.size.height + 1;
	switch (position) {
		case COAccessoryPlacementTopLeft:
			rect.origin.x = margin.x+2;
			rect.origin.y = contentFrame.size.height-rect.size.height-margin.y;
			break;
		case COAccessoryPlacementTopRight:
			rect.origin.x = contentFrame.size.width-rect.size.width-margin.x-2;
			rect.origin.y = contentFrame.size.height-rect.size.height-margin.y;
			break;
		case COAccessoryPlacementBottomLeft:
			rect.origin.x = margin.x+2;
			rect.origin.y = 17+margin.y+2;
			break;
		case COAccessoryPlacementBottomRight:
			rect.origin.x = contentFrame.size.width-rect.size.width-margin.x-2;
			rect.origin.y = 17+margin.y+2;
			break;
		case COAccessoryPlacementTopCenter:
			rect.origin.x = (contentFrame.size.width-rect.size.width)/2;
			rect.origin.y = contentFrame.size.height-rect.size.height-margin.y;
			break;
		case COAccessoryPlacementBottomCenter:
			rect.origin.x = (contentFrame.size.width-rect.size.width)/2;
			rect.origin.y = 17+margin.y+2;
			break;
		default:
			break;
	}
	return COIntRect(rect);
}
