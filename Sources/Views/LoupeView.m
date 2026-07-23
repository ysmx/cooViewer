//
//  LoupeView.m
//  cooViewer
//
//  Created by coo on 2020/01/02.
//

#import "LoupeView.h"

@implementation LoupeView

-(void)setTargetController:(Controller *)c
{
    targetController = c;
}
-(void)setMPoint:(NSPoint)p
{
    mPoint = p;
}
-(void)setFRect:(NSRect)fr
{
    fRect = fr;
}
-(void)setSRect:(NSRect)sr
{
    sRect = sr;
}
-(void)setLensRate:(float)lr
{
    lensRate = lr;
}
-(void)setRotateMode:(int)rm
{
    rotateMode = rm;
}
-(void)setLensSize:(int)ls
{
    lensSize = ls;
}
-(void)setInterpolation:(int)index
{
    interpolation = index;
}
-(void)setParentFrame:(NSRect)pf
{
    parentFrame = pf;
}

/*
 The rotateMode-dependent NSAffineTransform (translate+rotate, one of
 the loupe's two draw branches concats it and inverts afterward) and
 the corresponding mouse-point-to-draw-point remapping were byte-
 identical across -drawRect:'s single-image and two-image branches.
 The per-branch rect remapping (tempRect / fTempRect+sTempRect) is
 NOT identical between the branches - most visibly for rotateMode 2,
 where the two-image branch cross-references fRect and sRect against
 each other for the spread layout - so that part stays in each branch.
 */
- (NSAffineTransform *)co_loupeTransformForMode:(int)mode
{
	NSAffineTransform *transform = [NSAffineTransform transform];
	switch (mode) {
		case 1:
			[transform translateXBy:lensSize yBy:0];
			[transform rotateByDegrees:90];
			break;
		case 2:
			[transform translateXBy:lensSize yBy:lensSize];
			[transform rotateByDegrees:180];
			break;
		case 3:
			[transform translateXBy:0 yBy:lensSize];
			[transform rotateByDegrees:270];
			break;
		default:
			break;
	}
	return transform;
}

- (NSPoint)co_loupeDrawPointForMode:(int)mode
{
	switch (mode) {
		case 1:
			return NSMakePoint(mPoint.y, parentFrame.size.width - mPoint.x);
		case 2:
			return NSMakePoint(parentFrame.size.width - mPoint.x, parentFrame.size.height - mPoint.y);
		case 3:
			return NSMakePoint(parentFrame.size.height - mPoint.y, mPoint.x);
		default:
			return mPoint;
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSPoint iPoint;
    NSInteger widthValue,heightValue;
    
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    [gc saveGraphicsState];
    //[gc setShouldAntialias:NO];
    switch (interpolation) {
        case 1:
            [gc setImageInterpolation:NSImageInterpolationNone];
            break;
        case 2:
            [gc setImageInterpolation:NSImageInterpolationLow];
            break;
        case 3:
            [gc setImageInterpolation:NSImageInterpolationHigh];
            break;
        default:
            [gc setImageInterpolation:NSImageInterpolationDefault];
            break;
    }
    
    [[NSColor blackColor] set];
    NSRectFill(NSMakeRect(0,0,lensSize+2,lensSize+2));
    
    
    if (NSPointInRect(mPoint,fRect) || NSPointInRect(mPoint,sRect)) {
        if (NSIsEmptyRect(sRect)) {
            NSImage *image;
            NSAffineTransform *transform = [self co_loupeTransformForMode:rotateMode];
            NSPoint drawPoint = [self co_loupeDrawPointForMode:rotateMode];
            NSRect tempRect = fRect;
            image = [targetController image1];
            widthValue = [image size].width;
            heightValue = [image size].height;

            if (rotateMode==1 || rotateMode==3) {
                tempRect = NSMakeRect(fRect.origin.y,fRect.origin.x,fRect.size.height,fRect.size.width);
            }
            float x = [image size].width/tempRect.size.width;
            iPoint.x = (int)((drawPoint.x - tempRect.origin.x)*lensRate*x);
            iPoint.y = (int)((drawPoint.y - tempRect.origin.y)*lensRate*x);
            [transform concat];
            [image drawInRect:NSMakeRect((iPoint.x*-1+lensSize/2),(iPoint.y*-1+lensSize/2),widthValue*lensRate,heightValue*lensRate)
                    fromRect:NSMakeRect(0,0,widthValue,heightValue)
                    operation:NSCompositingOperationSourceOver fraction:1.0];
            [transform invert];
            [transform concat];
        } else {
            //!NSIsEmptyRect(sRect)
            NSImage *image;
            NSAffineTransform *transform = [self co_loupeTransformForMode:rotateMode];
            NSPoint drawPoint = [self co_loupeDrawPointForMode:rotateMode];
            NSRect fTempRect = fRect;
            NSRect sTempRect = sRect;
            if (rotateMode==1) {
                fTempRect = NSMakeRect(fRect.origin.y,fRect.origin.x,fRect.size.height,fRect.size.width);
                sTempRect = NSMakeRect(sRect.origin.y,sRect.origin.x,sRect.size.height,sRect.size.width);
            } else if (rotateMode==2) {
                fTempRect = NSMakeRect(sRect.origin.x,fRect.origin.y,fRect.size.width,fRect.size.height);
                sTempRect = NSMakeRect(fRect.size.width+sRect.origin.x,sRect.origin.y,sRect.size.width,sRect.size.height);
            } else if (rotateMode==3) {
                fTempRect = NSMakeRect(sRect.origin.y,fRect.origin.x,fRect.size.height,fRect.size.width);
                sTempRect = NSMakeRect(fRect.size.height,sRect.origin.x,sRect.size.height,sRect.size.width);
            }
            [transform concat];
            if (NSPointInRect(mPoint,fRect)) {
                if ([targetController readFromLeft]) {
                    image = [targetController image1];
                } else {
                    image = [targetController image2];
                }
                widthValue = [image size].width;
                heightValue = [image size].height;
                
                /*
                float x = [image size].width/fTempRect.size.width;
                iPoint.x = (int)((drawPoint.x - fTempRect.origin.x)*x);
                iPoint.y = (int)((drawPoint.y - fTempRect.origin.y)*x);
                */
                float x = [image size].width/fTempRect.size.width;
                iPoint.x = (int)((drawPoint.x - fTempRect.origin.x)*lensRate*x);
                iPoint.y = (int)((drawPoint.y - fTempRect.origin.y)*lensRate*x);
                if (NSIntersectsRect(NSMakeRect(mPoint.x-lensSize/2,mPoint.y-lensSize/2,lensSize,lensSize),sRect)) {
                    NSImage *sImage;
                    if ([targetController readFromLeft]) {
                        sImage = [targetController image2];
                    } else {
                        sImage = [targetController image1];
                    }
                    NSInteger sWidthValue = [sImage size].width;
                    NSInteger sHeightValue = [sImage size].height;
                    float sx = [sImage size].width/sTempRect.size.width;
                    NSPoint sPoint;
                    sPoint.x = (int)((drawPoint.x - sTempRect.origin.x)*lensRate*x);
                    sPoint.y = (int)((drawPoint.y - sTempRect.origin.y)*lensRate*x);
                    [sImage drawInRect:NSMakeRect((sPoint.x*-1+lensSize/2),(sPoint.y*-1+lensSize/2),sWidthValue*lensRate,sHeightValue*lensRate)
                            fromRect:NSMakeRect(0,0,sWidthValue,sHeightValue)
                            operation:NSCompositingOperationSourceOver fraction:1.0];
                }
            } else /*if (NSPointInRect(mPoint,sRect))*/ {
                if ([targetController readFromLeft]) {
                    image = [targetController image2];
                } else {
                    image = [targetController image1];
                }
                widthValue = [image size].width;
                heightValue = [image size].height;
                
                /*
                float x = [image size].width/sTempRect.size.width;
                iPoint.x = (int)((drawPoint.x - sTempRect.origin.x)*x);
                iPoint.y = (int)((drawPoint.y - sTempRect.origin.y)*x);
                */
                float x = [image size].width/sTempRect.size.width;
                iPoint.x = (int)((drawPoint.x - sTempRect.origin.x)*lensRate*x);
                iPoint.y = (int)((drawPoint.y - sTempRect.origin.y)*lensRate*x);
                if (NSIntersectsRect(NSMakeRect(mPoint.x-lensSize/2,mPoint.y-lensSize/2,lensSize,lensSize),fRect)) {
                    NSImage *sImage;
                    if ([targetController readFromLeft]) {
                        sImage = [targetController image1];
                    } else {
                        sImage = [targetController image2];
                    }
                    NSInteger sWidthValue = [sImage size].width;
                    NSInteger sHeightValue = [sImage size].height;
                    float sx = [sImage size].width/fTempRect.size.width;
                    NSPoint sPoint;
                    sPoint.x = (int)((drawPoint.x - fTempRect.origin.x)*lensRate*x);
                    sPoint.y = (int)((drawPoint.y - fTempRect.origin.y)*lensRate*x);
                    [sImage drawInRect:NSMakeRect((sPoint.x*-1+lensSize/2),(sPoint.y*-1+lensSize/2),sWidthValue*lensRate,sHeightValue*lensRate)
                            fromRect:NSMakeRect(0,0,sWidthValue,sHeightValue)
                            operation:NSCompositingOperationSourceOver fraction:1.0];
                }
            }
            [image drawInRect:NSMakeRect((iPoint.x*-1+lensSize/2),(iPoint.y*-1+lensSize/2),widthValue*lensRate,heightValue*lensRate)
                    fromRect:NSMakeRect(0,0,widthValue,heightValue)
                    operation:NSCompositingOperationSourceOver fraction:1.0];
            [transform invert];
            [transform concat];
        }
    }
    
    [[NSColor lightGrayColor] set];
    NSFrameRectWithWidth(NSMakeRect(0,0,lensSize,lensSize),1.0);

    [gc restoreGraphicsState];
}

@end
