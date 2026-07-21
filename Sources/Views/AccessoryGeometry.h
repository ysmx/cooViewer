//
//  AccessoryGeometry.h
//  cooViewer
//
//  Pure layout/geometry helpers used by AccessoryView, split out so they
//  can be unit tested without pulling in the rest of the view hierarchy.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, COAccessoryPlacement) {
	COAccessoryPlacementTopLeft = 0,
	COAccessoryPlacementTopRight = 1,
	COAccessoryPlacementBottomLeft = 2,
	COAccessoryPlacementBottomRight = 3,
	COAccessoryPlacementTopCenter = 4,
	COAccessoryPlacementBottomCenter = 5
};

NSRect COIntRect(NSRect aRect);
BOOL COAccessoryPlacementIsTop(int placement);
BOOL COAccessoryPlacementIsRight(int placement);
BOOL COAccessoryPlacementIsCenter(int placement);

NSRect COPageBarLayoutRect(NSRect contentFrame, NSPoint margin, float widthValue, float heightValue, int position);
NSRect COPageStringLayoutRect(NSRect contentFrame, NSAttributedString *string, NSPoint margin, int position);
CGFloat COPageStringTextLeftOffset(void);
void CODrawPageStringAtPoint(NSAttributedString *string, NSPoint pt, NSColor *bg, NSColor *border);
