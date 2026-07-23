
#import <Cocoa/Cocoa.h>
#import "Controller.h"


@interface FullImagePanel : NSPanel {
	NSArray *keyArray;
	Controller *target;
	BOOL fitMode;
}
- (void)setFitMode:(BOOL)yes;
-(void)setSelfMaxSize;
@end
