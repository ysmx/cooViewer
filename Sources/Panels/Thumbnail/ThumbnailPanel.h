/* ThumbnailPanel */

#import <Cocoa/Cocoa.h>
#import "ThumbnailController.h"
#import "ThumbnailMatrix.h"

@interface ThumbnailPanel : NSPanel
{
    IBOutlet ThumbnailMatrix *matrix;
	ThumbnailController *target;
	SEL selector;
	float setting;
}
@end
