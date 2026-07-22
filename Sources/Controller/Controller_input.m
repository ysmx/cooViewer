#import "Controller.h"
#import "cooViewer-Swift.h"
#import "CustomWindow.h"
#import "BookmarkController.h"
#import "CustomImageView.h"
#import "FullImagePanel.h"

@interface Controller (SortPrivate)
- (BOOL)co_sortModeSupportsDescending:(int)mode;
@end

@implementation Controller (Input)

static BOOL appleRemoteHoldDown = NO;

+ (void)co_performMenuActionInMenu:(NSMenu*)rootMenu parentTitle:(NSString*)parentTitle itemTitle:(NSString*)itemTitle
{
	NSMenu *menu = [[rootMenu itemWithTitle:parentTitle] submenu];
	NSMenuItem *item = [menu itemWithTitle:itemTitle];
	if ([item isEnabled]) {
		[menu performActionForItemAtIndex:[menu indexOfItem:item]];
	}
}

- (void)co_performPageUp
{
	[imageView scrollUp];
}

- (void)co_performPageDown
{
	[imageView scrollDown];
}

- (void)co_performPageUpAndPrevPage
{
	if ([imageView prev] == YES) {
		if (prevPageMode == 1) [imageView setStartFromEnd:YES];
		[self prevPage];
	}
}

- (void)co_performPageDownAndNextPage
{
	if ([imageView next] == YES) {
		[lock lock];
		[lock unlock];
		useComposedImage = YES;
		[self imageDisplay];
	}
}

- (void)co_performScrollToTop
{
	[imageView scrollToTop];
}

- (void)co_performScrollToEnd
{
	[imageView scrollToLast];
}

- (void)co_performScrollWithValue:(int)value dx:(int)dx dy:(int)dy
{
	[imageView scrollTo:[ViewerScrollDelta pointWithValue:value dx:dx dy:dy]];
}

- (void)co_performFitScreenTransition:(int)direction
{
	[self setPageTextField];
	NSNumber *target = [ViewerFitScreenTransition targetWithCurrent:fitScreenMode direction:(ViewerFitScreenDirection)direction];
	if (!target) return;
	switch ([target intValue]) {
		case 0:
			[self fitToScreen:nil];
			break;
		case 1:
			[self fitToScreenWidth:nil];
			break;
		case 2:
			[self noScale:nil];
			break;
		case 3:
			[self fitToScreenWidthDivide:nil];
			break;
		default:
			break;
	}
}

- (void)co_performLoupeRatePlus:(float)value
{
	[defaults setFloat:[ViewerLoupeRate increasedWithCurrent:[defaults floatForKey:@"LoupeRate"] by:value] forKey:@"LoupeRate"];
	[imageView setLoupeRate];
}

- (void)co_performLoupeRateMinus:(float)value
{
	[defaults setFloat:[ViewerLoupeRate decreasedWithCurrent:[defaults floatForKey:@"LoupeRate"] by:value] forKey:@"LoupeRate"];
	[imageView setLoupeRate];
}

- (void)co_performSwitchSingle
{
	[lock lock];
	[lock unlock];
	[self switchSingle:nil];
}

- (void)co_performShowNumber
{
	if (numberSwitch) {
		[imageView setPageString:nil];
		numberSwitch = NO;
		[defaults setBool:numberSwitch forKey:@"ShowNumber"];
	} else {
		numberSwitch = YES;
		[self setPageTextField];
		[defaults setBool:numberSwitch forKey:@"ShowNumber"];
	}
}

- (void)co_performShowThumbnail
{
	if (secondImage) {
		int temp = nowPage;
		temp--;
		[thumController showThumbnail:temp];
	} else {
		[thumController showThumbnail:nowPage];
	}
}

- (void)co_performChangeReadMode
{
	[lock lock];
	[lock unlock];
	[self changeReadMode:[ViewerReadMode nextWithCurrent:readMode]];
}

- (void)co_performShowPageBar
{
	if (pageBar) {
		pageBar = NO;
	} else {
		pageBar = YES;
	}
	[defaults setBool:pageBar forKey:@"ShowPageBar"];
	[imageView drawPageBar];
}

- (void)co_performOrigRight
{
	if ([self readFromLeft]) {
		[self viewAtOriginalSizeSecond:self];
	} else {
		[self viewAtOriginalSizeFirst:self];
	}
}

- (void)co_performOrigLeft
{
	if ([self readFromLeft]) {
		[self viewAtOriginalSizeFirst:self];
	} else {
		[self viewAtOriginalSizeSecond:self];
	}
}

- (void)co_performShowInFinderRight
{
	if ([self readFromLeft]) {
		[self showInFinderSecond:self];
	} else {
		[self showInFinderFirst:self];
	}
}

- (void)co_performShowInFinderLeft
{
	if ([self readFromLeft]) {
		[self showInFinderFirst:self];
	} else {
		[self showInFinderSecond:self];
	}
}

#pragma mark action
- (void)remoteButton:(RemoteControlEventIdentifier)buttonIdentifier pressedDown: (BOOL) pressedDown clickCount: (unsigned int)clickCount
{
	appleRemoteHoldDown = NO;
	if (!pressedDown) {
		return;
	}
	UpdateSystemActivity( OverallAct );
	//UpdateSystemActivity(UsrActivity);
	
    unichar character = buttonIdentifier;
	switch(buttonIdentifier) {
		case kRemoteButtonRight_Hold:
			appleRemoteHoldDown = YES;
			character = kRemoteButtonRight;
			break;	
		case kRemoteButtonLeft_Hold:
			appleRemoteHoldDown = YES;
			character = kRemoteButtonLeft;
			break;			
		case kRemoteButtonPlus_Hold:
			appleRemoteHoldDown = YES;
			character = kRemoteButtonPlus;
			break;				
		case kRemoteButtonMinus_Hold:
			appleRemoteHoldDown = YES;
			character = kRemoteButtonMinus;
			break;				
		case kRemoteButtonPlay_Hold:
			appleRemoteHoldDown = YES;
			character = kRemoteButtonPlay;
			break;			
		case kRemoteButtonMenu_Hold:
			appleRemoteHoldDown = YES;
			character = kRemoteButtonMenu;
			break;
		default:
			break;
	}
	NSString *characters = [NSString stringWithCharacters:&character length:1];
	
	if (![window isVisible] || ![window isKeyWindow]) {
		if ([prefController inKeyEdit]) {
			[prefController setKeyCharacters:characters];
			appleRemoteHoldDown = NO;
			return;
		}
		if (![thumController isVisible]) {
			appleRemoteHoldDown = NO;
			return;
		}
	}
	[self timeredRemoteButtonEvent:characters];
}
- (void)timeredRemoteButtonEvent:(NSString*)characters;
{	
	if ([thumController isVisible]) {
		[thumController appleRemoteAction:characters];
	} else {
		BOOL slideshow = NO;
		if (timerSwitch) {
			[timer invalidate];
			timerSwitch = NO;
			slideshow = YES;
			[imageView setSlideshow:NO];
		}
		useComposedImage = NO;
		threadStop = NO;
		unichar character = [characters characterAtIndex:0];
		unsigned int cMod = 100;
		if (fitScreenMode == 0) {
			[self getKeyAction:character mod:cMod mode:0 slideshow:slideshow];
		} else if (fitScreenMode == 1) {
			if (![self getKeyAction:character mod:cMod mode:1 slideshow:slideshow]) {
				[self getKeyAction:character mod:cMod mode:0 slideshow:slideshow];
			}
		} else if (fitScreenMode == 2 || fitScreenMode == 3) {
			if (![self getKeyAction:character mod:cMod mode:2 slideshow:slideshow]) {
				[self getKeyAction:character mod:cMod mode:0 slideshow:slideshow];
			}
		}
	}
	if (!appleRemoteHoldDown) return;
	[self performSelector:@selector(timeredRemoteButtonEvent:) withObject:characters afterDelay:0.1];
}

- (void)keyAction:(NSEvent*)sender
{	
	BOOL slideshow = NO;
	if (timerSwitch) {
		[timer invalidate];
		timerSwitch = NO;
		slideshow = YES;
		[imageView setSlideshow:NO];
		//return;
	}
	useComposedImage = NO;
	threadStop = NO;
	NSString *characters = [sender charactersIgnoringModifiers];
    unichar character = [characters characterAtIndex: 0];
	
	if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:character]){
		if ([imageView pageMover]) {
			if ([imageView tempPageNum] > 99999) {
				return;
			}
			[imageView drawPageMover:[characters intValue]];
			return;
		}
	} else if (character == 0x1B) {
		//esc
		if ([imageView pageMover]) {
			[imageView drawPageMover:-1];
			return;
		} else {
			threadStop = YES;
			[lock lock];
			[lock unlock];
			threadStop = NO;
			[window performClose:self];
			return;
		}
	} else if (character == NSDeleteCharacter) {
		if ([imageView pageMover]) {
			if ([imageView tempPageNum]<=0) {
				return;
			} else {
				[imageView drawPageMover:-2];
				return;
			}
		}
	} 
	
	unsigned int cMod = COKeyModifierMaskForEvent(sender, character, YES);
	if (cMod == COKeyModifierCommand && character == 'w') {
		[window performClose:self];
		return;
	}
	if (![imageView pageMover] &&
		(character == NSCarriageReturnCharacter || character == NSEnterCharacter) &&
		(cMod == 0 || cMod == COKeyModifierNumeric)) {
		if ([self openArchiveAtCurrentMouseLocation]) return;
	}
	if (![imageView pageMover] &&
		(character == NSDeleteCharacter || character == NSBackspaceCharacter) &&
		cMod == 0) {
		if ([self restorePreviousArchiveNavigation]) return;
	}
	
	if (fitScreenMode == 0) {
		[self getKeyAction:character mod:cMod mode:0 slideshow:slideshow];
	} else if (fitScreenMode == 1) {
		if (![self getKeyAction:character mod:cMod mode:1 slideshow:slideshow]) {
			[self getKeyAction:character mod:cMod mode:0 slideshow:slideshow];
		}
	} else if (fitScreenMode == 2 || fitScreenMode == 3) {
		if (![self getKeyAction:character mod:cMod mode:2 slideshow:slideshow]) {
			[self getKeyAction:character mod:cMod mode:0 slideshow:slideshow];
		}
	}
}

- (BOOL)getKeyAction:(unichar)character mod:(int)cMod mode:(int)mode slideshow:(BOOL)slideshow
{
	NSArray *bindings = nil;
	switch (mode) {
		case 0:
			bindings = keyArray;
			break;
		case 1:
			bindings = keyArrayMode2;
			break;
		case 2:
			bindings = keyArrayMode3;
			break;
		default:break;
	}
	{
		ViewerActionResolution *resolution = [ViewerActionResolver resolveKeyActionWithCharacter:character
																						  modifier:cMod
																						  bindings:bindings ?: @[]
																					  readFromLeft:[self readFromLeft]];
		if (resolution) {
			int action = resolution.action;
			NSDictionary *dic = resolution.binding;
			switch (action) {
				case 0:
					//nextpage
					[lock lock];
					[lock unlock];
					useComposedImage = YES;
					[self imageDisplay];
					break;
					
					
				case 1:
					//prevpage
					//[lock lock];
					//[lock unlock];
					[self prevPage];
					break;
					
					
					
				case 2:
					//halfnext
					[lock lock];
					[lock unlock];
					if (nowPage < [completeMutableArray count]) {
						if (secondImage){
							nowPage--;
							[lock lock];
							[lock unlock];
							[imageMutableArray insertObject:[self loadImage:nowPage] atIndex:0];
							//[imageMutableArray insertObject:secondImage atIndex:0];
						}
					}
						[self imageDisplay];
					break;
					
					
					
				case 3:
					//halfprev
					[lock lock];
					[lock unlock];
					[self halfprevPage];
					break;
					
					
					
				case 4:
					//lastpage
					[self goToLast];
					break;
					
					
					
				case 5:
					//toppage
					if (secondImage) {
						if (nowPage > 2) {
							threadStop = YES;
							[lock lock];
							[lock unlock];
							threadStop = NO;
							[imageMutableArray removeAllObjects];
							nowPage = 0;
							[self lookahead];
							[self imageDisplay];
						}
					} else {
						if (nowPage > 1) {
							threadStop = YES;
							[lock lock];
							[lock unlock];
							threadStop = NO;
							[imageMutableArray removeAllObjects];
							nowPage = 0;
							[self lookahead];
							[self imageDisplay];
						}
					}		
					break;
					
					
					
				case 6:
					//nextbookmark
					[lock lock];
					[lock unlock];
					[self nextBookmark];
					break;
					
					
				case 7:
					//prevbookmark
					[lock lock];
					[lock unlock];
					[self backBookmark];	
					break;
					
					
					
				case 8:
					//nextfolder
					[lock lock];
					[lock unlock];
					[self nextFolder];
					break;
					
					
					
				case 9:
					//prevfolder
					[lock lock];
					[lock unlock];
					[self backFolder];
					break;
					
					
				case 10:
					//add/removebookmark
					if ([self removeBookmark]) {
					} else {
						[self addBookmark];
					}
					break;
					
					
				case 11:
					//switchSingle
					[self co_performSwitchSingle];
					break;



				case 12:
					//shownumber
					[self co_performShowNumber];
					break;
					
					
					
				case 13:
					//skip
					threadStop = YES;
					[lock lock];
					[lock unlock];
					threadStop = NO;
					[imageMutableArray removeAllObjects];
					int skipI = [[dic objectForKey:@"value"] intValue];
					skipI -= 2;
					if (!secondImage) {
						//skipI += 1;
					}
						nowPage += skipI;
					if (nowPage >= [completeMutableArray count]) {
						nowPage = (int)[completeMutableArray count];
						nowPage -= 2;
					}
						[self lookahead];
					if ([imageMutableArray count] > 1) {
						if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO) {
							[imageMutableArray removeObjectAtIndex:0];
							nowPage++;
						} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
							[imageMutableArray removeObjectAtIndex:0];
							nowPage++;
						}
					}
						
						[self imageDisplay];
					
					break;
					
					
					
				case 14:
					//backskip
					threadStop = YES;
					[lock lock];
					[lock unlock];
					threadStop = NO;
					[imageMutableArray removeAllObjects];
					int bskipI = [[dic objectForKey:@"value"] intValue];
					bskipI += 2;
					if (!secondImage) {
						//bskipI -= 1;
					}
						nowPage -= bskipI;
					if (nowPage < 0) {
						nowPage = 0;
					}
						[self lookahead];
					[self imageDisplay];
					
					break;
					
					
					
				case 15:
					//origRight
					[self co_performOrigRight];
					break;



				case 16:
					//origLeft
					[self co_performOrigLeft];
					break;
					
					
					
				case 17:
					//slideshow
					if (!slideshow) {
						[self slideshow:nil];
					}
					[self setPageTextField];
					break;
					
					
					
				case 18:
					//showThumbnail
					[self co_performShowThumbnail];
					break;



				case 19:
					//changeReadMode
					[self co_performChangeReadMode];
					break;

				case 20:
					//showPageBar
					[self co_performShowPageBar];
					break;
				case 21:
					//showPageMover
					if (![imageView pageMover]) {
						[imageView drawPageMover:0];
					} else {
						if ([imageView tempPageNum]<=0) {
							[imageView drawPageMover:-1];
							break;
						} else {
							[lock lock];
							[lock unlock];
							int tempPageNum = [imageView tempPageNum];
							tempPageNum--;
							[self goTo:tempPageNum array:nil];
							[imageView drawPageMover:-1];
						}
					}
					break;
				case 22:
					//show in finder R
					[self co_performShowInFinderRight];
					break;
				case 23:
					//showInFinderL
					[self co_performShowInFinderLeft];
					break;
				case 24:
					//PageUp
					[self co_performPageUp];
					break;
				case 25:
					//PageDown
					[self co_performPageDown];
					break;
				case 26:
					//PageUp + PrevPage
					[self co_performPageUpAndPrevPage];
					break;
				case 27:
					//PageDown + NextPage
					[self co_performPageDownAndNextPage];
					break;
				case 28:
					//ScrollToTop
					[self co_performScrollToTop];
					break;
				case 29:
					//ScrollToEnd
					[self co_performScrollToEnd];
					break;
				case 30:
					//ScrollUp
					[self co_performScrollWithValue:[[dic objectForKey:@"value"] intValue] dx:0 dy:-1];
					break;
				case 31:
					//ScrollDown
					[self co_performScrollWithValue:[[dic objectForKey:@"value"] intValue] dx:0 dy:1];
					break;
				case 32:
					//ScrollLeft
					[self co_performScrollWithValue:[[dic objectForKey:@"value"] intValue] dx:1 dy:0];
					break;
				case 33:
					//ScrollRight
					[self co_performScrollWithValue:[[dic objectForKey:@"value"] intValue] dx:-1 dy:0];
					break;
				case 34:
					//loupe
					[imageView setLoupe];
					break;
				case 35:
					//nextSubFolder
					[self nextSubFolder];
					break;
				case 36:
					//prevSubFolder
					[self prevSubFolder];
					break;
				case 37:
					//loupeRatePlus
					[self co_performLoupeRatePlus:[[dic objectForKey:@"value"] floatValue]];
					break;
				case 38:
					//loupeRateMinus
					[self co_performLoupeRateMinus:[[dic objectForKey:@"value"] floatValue]];
					break;
				case 39:
					//goto%
					[self goToPar:([[dic objectForKey:@"value"] floatValue]/100)];
					break;
				case 40:
					//rotateRight
					[self rotateRight:nil];
					break;
				case 41:
					//rotateLeft
					[self rotateLeft:nil];
					break;
				case 42:
					//changeViewMode
					[self co_performFitScreenTransition:ViewerFitScreenDirectionCycle];
					break;
				case 51:
					//enlargeViewMode
					[self co_performFitScreenTransition:ViewerFitScreenDirectionEnlarge];
					break;
				case 52:
					//reduceViewMode
					[self co_performFitScreenTransition:ViewerFitScreenDirectionReduce];
					break;
				case 43:
					//trashRight
					[self trashRight];
					break;
				case 44:
					//trashLeft
					[self trashLeft];
					break;
				case 45:
					//changeSortMode
					sortMode = [ViewerSortModeTransition nextWithCurrent:sortMode canSortByDate:[imageLoader canSortByDate]];
					[self setSortMode:sortMode page:0];
					break;
				case 46:
					//close
					threadStop = YES;
					[lock lock];
					[lock unlock];
					threadStop = NO;
					[window performClose:self];
					break;
				case 47:
					//randam
					[self setSortMode:1 page:0];
					break;
				case 48:
					//openTheLastPage
					[Controller co_performMenuActionInMenu:[NSApp mainMenu] parentTitle:NSLocalizedString(@"File", @"") itemTitle:NSLocalizedString(@"Open the last page", @"")];
					break;
				case 49:
					//switchFullScreen
					[Controller co_performMenuActionInMenu:[NSApp mainMenu] parentTitle:NSLocalizedString(@"Window", @"") itemTitle:NSLocalizedString(@"Fullscreen", @"")];
					break;
				case 50:
					//minimizeWindow
					[Controller co_performMenuActionInMenu:[NSApp mainMenu] parentTitle:NSLocalizedString(@"Window", @"") itemTitle:NSLocalizedString(@"Minimize", @"")];
					break;
				default:
					break;
			}
			return YES;
		}
	}
	return NO;
}


- (void)mouseAction:(NSEvent*)sender
{
	if (timerSwitch) {
		[timer invalidate];
		timerSwitch=NO;
		[imageView setSlideshow:NO];
	}
	
	int button = (int)[sender buttonNumber];
	unsigned int cMod = 0;
	BOOL shift = ([sender modifierFlags] & NSEventModifierFlagShift) ? YES : NO;
	BOOL option = ([sender modifierFlags] & NSEventModifierFlagOption) ? YES : NO;
	BOOL control = ([sender modifierFlags] & NSEventModifierFlagControl) ? YES : NO;
	
	if (shift) {
		cMod += 1;
	}
	if (option) {
		cMod += 2;
	}
	if (control) {
		cMod += 4;
	}
	
	
	useComposedImage = NO;
	threadStop = NO;
	NSRect left,right;
	switch (readMode) {
		case 0:
			NSDivideRect ([[window contentView] frame], &left, &right, [[window contentView] frame].size.width/2, NSMinXEdge);
			break;
		case 1:
			NSDivideRect ([[window contentView] frame], &right, &left, [[window contentView] frame].size.width/2, NSMinXEdge);
			break;
		case 2:
			NSDivideRect ([[window contentView] frame], &left, &right, [[window contentView] frame].size.width/2, NSMinXEdge);
			break;
		case 3:
			NSDivideRect ([[window contentView] frame], &right, &left, [[window contentView] frame].size.width/2, NSMinXEdge);
			break;
		default:
			NSDivideRect ([[window contentView] frame], &left, &right, [[window contentView] frame].size.width/2, NSMinXEdge);
			break;
	}
	BOOL leftBool = NSPointInRect([sender locationInWindow], left);
	if (fitScreenMode == 0) {
		[self getMouseAction:button mod:cMod mode:0 left:leftBool];
	} else if (fitScreenMode == 1 || fitScreenMode == 3) {
		if (![self getMouseAction:button mod:cMod mode:1 left:leftBool]) {
			[self getMouseAction:button mod:cMod mode:0 left:leftBool];
		}
	} else if (fitScreenMode == 2) {
		if (![self getMouseAction:button mod:cMod mode:2 left:leftBool]) {
			[self getMouseAction:button mod:cMod mode:0 left:leftBool];
		}
	}
}

- (void)multiTouchAction:(NSEvent*)sender action:(int)action
{
	unsigned int cMod = 0;
	int button = 0;
	switch (action) {
		case 0:
			//swipe right
			button += 1000;
			break;
		case 1:
			//swipe left
			button += 2000;
			break;
		case 2:
			//swipe up
			button += 3000;
			break;
		case 3:
			//swipe down
			button += 4000;
			break;
		case 4:
			//pinch in
			button += 5000;
			break;
		case 5:
			//pinch out
			button += 6000;
			break;
		case 6:
			//rotate right
			button += 7000;
			break;
		case 7:
			//rotate left
			button += 8000;
			break;
		default:
			break;
	}
	BOOL shift = ([sender modifierFlags] & NSEventModifierFlagShift) ? YES : NO;
	BOOL option = ([sender modifierFlags] & NSEventModifierFlagOption) ? YES : NO;
	BOOL control = ([sender modifierFlags] & NSEventModifierFlagControl) ? YES : NO;
	
	if (shift) {
		cMod += 1;
	}
	if (option) {
		cMod += 2;
	}
	if (control) {
		cMod += 4;
	}
	
	
	useComposedImage = NO;
	threadStop = NO;
	NSRect left,right;
	switch (readMode) {
		case 0:
			NSDivideRect ([imageView frame], &left, &right, [imageView frame].size.width/2, NSMinXEdge);
			break;
		case 1:
			NSDivideRect ([imageView frame], &right, &left, [imageView frame].size.width/2, NSMinXEdge);
			break;
		case 2:
			NSDivideRect ([imageView frame], &left, &right, [imageView frame].size.width/2, NSMinXEdge);
			break;
		case 3:
			NSDivideRect ([imageView frame], &right, &left, [imageView frame].size.width/2, NSMinXEdge);
			break;
		default:
			NSDivideRect ([imageView frame], &left, &right, [imageView frame].size.width/2, NSMinXEdge);
			break;
	}
	BOOL leftBool = NSPointInRect([sender locationInWindow], left);
	if (fitScreenMode == 0) {
		[self getMouseAction:button mod:cMod mode:0 left:leftBool];
	} else if (fitScreenMode == 1) {
		if (![self getMouseAction:button mod:cMod mode:1 left:leftBool]) {
			[self getMouseAction:button mod:cMod mode:0 left:leftBool];
		}
	} else if (fitScreenMode == 2 || fitScreenMode == 3) {
		if (![self getMouseAction:button mod:cMod mode:2 left:leftBool]) {
			[self getMouseAction:button mod:cMod mode:0 left:leftBool];
		}
	}
}

- (void)gestureAction:(NSEvent*)sender moved:(int)moved
{
	int button = (int)[sender buttonNumber];
	unsigned int cMod = 0;
	switch (moved) {
		case 0:
			//left
			cMod += 200;
			break;
		case 1:
			//right
			cMod += 300;
			break;
		case 2:
			//up
			cMod += 400;
			break;
		case 3:
			//down
			cMod += 500;
			break;
		default:
			break;
	}
	BOOL shift = ([sender modifierFlags] & NSEventModifierFlagShift) ? YES : NO;
	BOOL option = ([sender modifierFlags] & NSEventModifierFlagOption) ? YES : NO;
	BOOL control = ([sender modifierFlags] & NSEventModifierFlagControl) ? YES : NO;
	
	if (shift) {
		cMod += 1;
	}
	if (option) {
		cMod += 2;
	}
	if (control) {
		cMod += 4;
	}
	
	
	useComposedImage = NO;
	threadStop = NO;
	NSRect left,right;
	switch (readMode) {
		case 0:
			NSDivideRect ([imageView frame], &left, &right, [imageView frame].size.width/2, NSMinXEdge);
			break;
		case 1:
			NSDivideRect ([imageView frame], &right, &left, [imageView frame].size.width/2, NSMinXEdge);
			break;
		case 2:
			NSDivideRect ([imageView frame], &left, &right, [imageView frame].size.width/2, NSMinXEdge);
			break;
		case 3:
			NSDivideRect ([imageView frame], &right, &left, [imageView frame].size.width/2, NSMinXEdge);
			break;
		default:
			NSDivideRect ([imageView frame], &left, &right, [imageView frame].size.width/2, NSMinXEdge);
			break;
	}
	BOOL leftBool = NSPointInRect([sender locationInWindow], left);
	if (fitScreenMode == 0) {
		if (![self getMouseAction:button mod:cMod mode:0 left:leftBool]) {
			[self getMouseAction:button mod:100 mode:0 left:leftBool];
		}
	} else if (fitScreenMode == 1) {
		if (![self getMouseAction:button mod:cMod mode:1 left:leftBool]) {
			if (![self getMouseAction:button mod:cMod mode:0 left:leftBool]) {
				if (![self getMouseAction:button mod:100 mode:1 left:leftBool]) {
					[self getMouseAction:button mod:100 mode:0 left:leftBool];
				}
			}
		}
	} else if (fitScreenMode == 2 || fitScreenMode == 3) {
		if (![self getMouseAction:button mod:cMod mode:2 left:leftBool]) {
			if (![self getMouseAction:button mod:cMod mode:0 left:leftBool]) {
				if (![self getMouseAction:button mod:100 mode:2 left:leftBool]) {
					[self getMouseAction:button mod:100 mode:0 left:leftBool];
				}
			}
		}
	}
}

//- (void)getMouseAction:(int)button mod:(int)cMod left:(BOOL)left

- (BOOL)getMouseAction:(int)button mod:(int)cMod mode:(int)mode left:(BOOL)left
{
	NSArray *bindings = nil;
	switch (mode) {
		case 0:
			bindings = mouseArray;
			break;
		case 1:
			bindings = mouseArrayMode2;
			break;
		case 2:
			bindings = mouseArrayMode3;
			break;
		default:break;
	}
	{
		ViewerActionResolution *resolution = [ViewerActionResolver resolveMouseActionWithButton:button
																						 modifier:cMod
																						 bindings:bindings ?: @[]
																					 readFromLeft:[self readFromLeft]];
		if (resolution) {
			int action = resolution.action;
			NSDictionary *dic = resolution.binding;
			switch (action) {
				case 0:
					//next/prevpage
					if (left) {
						[lock lock];
						[lock unlock];
						useComposedImage = YES;
						[self imageDisplay];
					} else {
						//[lock lock];
						//[lock unlock];
						[self prevPage];
					}
						break;
				case 1:
					//halfnext/prevpage
					[lock lock];
					[lock unlock];
					if (left) {
						if (nowPage < [completeMutableArray count]) {
							if (secondImage){
								nowPage--;
								[imageMutableArray insertObject:[self loadImage:nowPage] atIndex:0];
								//[imageMutableArray insertObject:secondImage atIndex:0];
							}
						}
						[self imageDisplay];
					} else {
						[self halfprevPage];
					}
						break;
				case 2:
					//lastpage/toppage
					if (left) {
						if (nowPage < [completeMutableArray count]) {
							threadStop = YES;
							[lock lock];
							[lock unlock];
							threadStop = NO;
							[imageMutableArray removeAllObjects];
							nowPage = (int)[completeMutableArray count];
							if (readMode > 1) {
								nowPage--;
								[self lookahead];
							} else {
								nowPage -= 2;
								[self lookahead];
								if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO) {
									[imageMutableArray removeObjectAtIndex:0];
									nowPage++;
								} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
									[imageMutableArray removeObjectAtIndex:0];
									nowPage++;
								}
							}
							[self imageDisplay];
						}
					} else {
						if (secondImage) {
							if (nowPage > 2) {
								threadStop = YES;
								[lock lock];
								[lock unlock];
								threadStop = NO;
								[imageMutableArray removeAllObjects];
								nowPage = 0;
								[self lookahead];
								[self imageDisplay];
							}
						} else {
							if (nowPage > 1) {
								threadStop = YES;
								[lock lock];
								[lock unlock];
								threadStop = NO;
								[imageMutableArray removeAllObjects];
								nowPage = 0;
								[self lookahead];
								[self imageDisplay];
							}
						}	
					}
					break;
				case 3:
					//next/prevbookmark
					[lock lock];
					[lock unlock];
					if (left) {
						[self nextBookmark];
					} else {
						[self backBookmark];
					}
						break;
				case 4:
					//next/prevfolder
					[lock lock];
					[lock unlock];
					if (left) {
						[self nextFolder];
					} else {
						[self backFolder];
					}
						break;
				case 5:
					//skip/backskip
					if (left) {
						threadStop = YES;
						[lock lock];
						[lock unlock];
						threadStop = NO;
						[imageMutableArray removeAllObjects];
						int skipI = [[dic objectForKey:@"value"] intValue];
						skipI -= 2;
						nowPage += skipI;
						if (nowPage >= [completeMutableArray count]) {
							nowPage = (int)[completeMutableArray count];
							nowPage -= 2;
						}
						[self lookahead];
						if ([imageMutableArray count] > 1) {
							if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO) {
								[imageMutableArray removeObjectAtIndex:0];
								nowPage++;
							} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
								[imageMutableArray removeObjectAtIndex:0];
								nowPage++;
							}
						}
						[self imageDisplay];
					} else {
						threadStop = YES;
						[lock lock];
						[lock unlock];
						threadStop = NO;
						[imageMutableArray removeAllObjects];
						int bskipI = [[dic objectForKey:@"value"] intValue];
						bskipI += 2;
						nowPage -= bskipI;
						if (nowPage < 0) {
							nowPage = 0;
						}
						[self lookahead];
						[self imageDisplay];
					}
					break;
				case 6:
					//nextpage
					[lock lock];
					[lock unlock];
					useComposedImage = YES;
					[self imageDisplay];
					break;
				case 7:
					//prevpage 
					//[lock lock];
					//[lock unlock];
					[self prevPage];
					break;
				case 8:
					//halfnext
					[lock lock];
					[lock unlock];
					if (nowPage < [completeMutableArray count]) {
						if (secondImage){
							nowPage--;
							[imageMutableArray insertObject:[self loadImage:nowPage] atIndex:0];
							//[imageMutableArray insertObject:secondImage atIndex:0];
						}
					}
					[self imageDisplay];
					break;
				case 9:
					//halfprev
					[lock lock];
					[lock unlock];
					[self halfprevPage];
					break;
				case 10:
					//lastpage
					[self goToLast];
					break;
				case 11:
					//toppage
					if (secondImage) {
						if (nowPage > 2) {
							threadStop = YES;
							[lock lock];
							[lock unlock];
							threadStop = NO;
							[imageMutableArray removeAllObjects];
							nowPage = 0;
							[self lookahead];
							[self imageDisplay];
						}
					} else {
						if (nowPage > 1) {
							threadStop = YES;
							[lock lock];
							[lock unlock];
							threadStop = NO;
							[imageMutableArray removeAllObjects];
							nowPage = 0;
							[self lookahead];
							[self imageDisplay];
						}
					}		
					
					break;
				case 12:
					//nextbookmark	
					[lock lock];
					[lock unlock];
					[self nextBookmark];
					break;
				case 13:
					//prevbookmark
					[lock lock];
					[lock unlock];
					[self backBookmark];		
					break;
				case 14:
					//nextfolder	
					[lock lock];
					[lock unlock];
					[self nextFolder];
					break;
				case 15:
					//prevfolder
					[lock lock];
					[lock unlock];
					[self backFolder];
					break;
				case 16:
					//add/removebookmark
					if ([self removeBookmark]) {
					} else {
						[self addBookmark];
					}
					break;
				case 17:
					//switchSingle
					[self co_performSwitchSingle];
					break;
				case 18:
					//shownumber
					[self co_performShowNumber];
					break;
				case 19:
					//skip
					threadStop = YES;
					[lock lock];
					[lock unlock];
					threadStop = NO;
					[imageMutableArray removeAllObjects];
					int skipI = [[dic objectForKey:@"value"] intValue];
					skipI -= 2;
					nowPage += skipI;
					if (nowPage >= [completeMutableArray count]) {
						nowPage = (int)[completeMutableArray count];
						nowPage -= 2;
					}
						[self lookahead];
					if ([imageMutableArray count] > 1) {
						if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO) {
							[imageMutableArray removeObjectAtIndex:0];
							nowPage++;
						} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
							[imageMutableArray removeObjectAtIndex:0];
							nowPage++;
						}
					}
						
						[self imageDisplay];
					
					
					break;
				case 20:
					//backskip
					threadStop = YES;
					[lock lock];
					[lock unlock];
					threadStop = NO;
					[imageMutableArray removeAllObjects];
					int bskipI = [[dic objectForKey:@"value"] intValue];
					bskipI += 2;
					nowPage -= bskipI;
					if (nowPage < 0) {
						nowPage = 0;
					}
						[self lookahead];
					[self imageDisplay];
					
					
					break;
				case 21:
					//origRight
					[self co_performOrigRight];
					break;
				case 22:
					//origLeft
					[self co_performOrigLeft];
					break;
				case 23:
					//slideshow	
					[self slideshow:nil];
					[self setPageTextField];
					break;
				case 24:
					//showThumbnail
					[self co_performShowThumbnail];
					break;
				case 25:
					//changeReadMode
					[self co_performChangeReadMode];
					break;
				case 26:
					//showPageBar
					[self co_performShowPageBar];
					break;
				case 27:
					//viewOriginalL/R
					if (left) {
						[self viewAtOriginalSizeSecond:self];
					} else {
						[self viewAtOriginalSizeFirst:self];
					}
					break;
				case 28:
					//showInFinderR
					[self co_performShowInFinderRight];
					break;
				case 29:
					//showInFinderL
					[self co_performShowInFinderLeft];
					break;
				case 30:
					//showInFinderL/R
					if (left) {
						[self showInFinderSecond:self];
					} else {
						[self showInFinderFirst:self];
					}
					break;
				case 31:
					//PageUp
					[self co_performPageUp];
					break;
				case 32:
					//PageDown
					[self co_performPageDown];
					break;
				case 33:
					//PageUp + PrevPage
					[self co_performPageUpAndPrevPage];
					break;
				case 34:
					//PageDown + NextPage
					[self co_performPageDownAndNextPage];
					break;
				case 35:
					//ScrollToTop
					[self co_performScrollToTop];
					break;
				case 36:
					//ScrollToEnd
					[self co_performScrollToEnd];
					break;
				case 37:
					//ScrollUp
					[self co_performScrollWithValue:[[dic objectForKey:@"value"] intValue] dx:0 dy:-1];
					break;
				case 38:
					//ScrollDown
					[self co_performScrollWithValue:[[dic objectForKey:@"value"] intValue] dx:0 dy:1];
					break;
				case 39:
					//ScrollLeft
					[self co_performScrollWithValue:[[dic objectForKey:@"value"] intValue] dx:1 dy:0];
					break;
				case 40:
					//ScrollRight
					[self co_performScrollWithValue:[[dic objectForKey:@"value"] intValue] dx:-1 dy:0];
					break;
				case 41:
					//DragScroll - intentionally a no-op. Selectable in Preferences
					//(see PreferenceController.m's action-name table), but actual
					//click-and-drag scrolling is handled entirely by
					//-[CustomImageView dragScroll:] via real-time mouse tracking,
					//not through this discrete action dispatch. No history exists
					//explaining why this action number is otherwise unimplemented.
					break;
				case 42:
					//PageUp/Down + Prev/NextPage
					if (left) {
						[self co_performPageDownAndNextPage];
					} else {
						[self co_performPageUpAndPrevPage];
					}
					break;
				case 43:
					//loupe
					[imageView setLoupe];
					break;
				case 44:
					//nextSubFolder
					[self nextSubFolder];
					break;
				case 45:
					//prevSubFolder
					[self prevSubFolder];
					break;
				case 46:
					//next/prevSubFolder
					if (left) {
						[self nextSubFolder];
					} else {
						[self prevSubFolder];
					}
					break;
				case 47:
					//loupeRatePlus
					[self co_performLoupeRatePlus:[[dic objectForKey:@"value"] floatValue]];
					break;
				case 48:
					//loupeRateMinus
					[self co_performLoupeRateMinus:[[dic objectForKey:@"value"] floatValue]];
					break;
				
				case 49:
					//rotateRight
					[self rotateRight:nil];
					break;
				case 50:
					//rotateLeft
					[self rotateLeft:nil];
					break;
				case 51:
					//changeViewMode
					[self co_performFitScreenTransition:ViewerFitScreenDirectionCycle];
					break;
				case 63:
					//enlargeViewMode
					[self co_performFitScreenTransition:ViewerFitScreenDirectionEnlarge];
					break;
				case 64:
					//reduceViewMode
					[self co_performFitScreenTransition:ViewerFitScreenDirectionReduce];
					break;
				case 52:
					//trashRight
					[self trashRight];
					break;
				case 53:
					//trashLeft
					[self trashLeft];
					break;
				case 54:
					//trashL/R
					if (left) {
						[self trashLeft];
					} else {
						[self trashRight];
					}
					break;
				case 55:
					//rotateL/R
					if (left) {
						[self rotateLeft:nil];
					} else {
						[self rotateRight:nil];
					}
					break;
				case 56:
					//changeSortMode
					sortMode = [ViewerSortModeTransition nextWithCurrent:sortMode canSortByDate:[imageLoader canSortByDate]];
					[self setSortMode:sortMode page:0];
					break;
				case 57:
					//close
					threadStop = YES;
					[lock lock];
					[lock unlock];
					threadStop = NO;
					[window performClose:self];
					break;	
				case 58:
					//random
					[self setSortMode:1 page:0];
					break;
				case 59:
					//ContextualMenu
					[NSMenu popUpContextMenu:[imageView menu] withEvent:[NSApp currentEvent] forView:imageView];
					break;
				case 60:
					//openTheLastPage
					[Controller co_performMenuActionInMenu:[NSApp mainMenu] parentTitle:NSLocalizedString(@"File", @"") itemTitle:NSLocalizedString(@"Open the last page", @"")];
					break;
				case 61:
					//switchFullScreen
					[Controller co_performMenuActionInMenu:[NSApp mainMenu] parentTitle:NSLocalizedString(@"Window", @"") itemTitle:NSLocalizedString(@"Fullscreen", @"")];
					break;
				case 62:
					//minimizeWindow
					[Controller co_performMenuActionInMenu:[NSApp mainMenu] parentTitle:NSLocalizedString(@"Window", @"") itemTitle:NSLocalizedString(@"Minimize", @"")];
					break;
				default:
					break;
			}
			return YES;
		}
	}
	return NO;
}

- (IBAction)contextAction:(id)sender
{
	if (timerSwitch) {
		[timer invalidate];
		timerSwitch=NO;
	}
	[lock lock];
	[lock unlock];
	if ([[sender title] isEqualToString:NSLocalizedString(@"Add Bookmark", @"")]){
		[self addBookmark];
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Remove Bookmark", @"")]){
		[self removeBookmark];
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Go to LastPage", @"")]){
		[self goToLast];
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Go to FirstPage", @"")]){
		[self goToFirst];
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Next Bookmark", @"")]){
		[self nextBookmark];	
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Previous Bookmark", @"")]){
		[self backBookmark];
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Previous Folder", @"")]){
		[self backFolder];
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Next Folder", @"")]){
		[self nextFolder];
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Show Thumbnail", @"")]){
		[self showThumbnail];
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"View at Original Size", @"")]){
		if ([sender tag] == 0) {
			[self viewAtOriginalSizeFirst:self];
		} else {
			[self viewAtOriginalSizeSecond:self];
		}
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Show in Finder", @"")]){
		if ([sender tag] == 0) {
			[self showInFinderFirst:self];
		} else {
			[self showInFinderSecond:self];
		}
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Start Slideshow", @"")]) {
		[self slideshow:self];
	} else if ([[sender title] isEqualToString:NSLocalizedString(@"Stop Slideshow", @"")]) {
		[self setPageTextField];
		/*既に止まってる*/
	}
}
/*
- (IBAction)nextFolder:(id)sender{
}
- (IBAction)addBookmark:(id)sender{
}
- (IBAction)backFolder:(id)sender{
}
- (IBAction)nextBookmark:(id)sender{
}
- (IBAction)backBookmark:(id)sender{
}
- (IBAction)showThumbnail:(id)sender{
}*/


- (void)wheelAction:(NSEvent*)event
{
	if (timerSwitch) {
		[timer invalidate];
		timerSwitch=NO;
	}

	threadStop = NO;
	if (fitScreenMode > 0) {
		switch (canScrollMode) {
			case 0:
				[imageView scrollTo:NSMakePoint(([event deltaX]*10),([event deltaY]*10*-1))];
				return;
			case 1:
				if (![imageView scrollTo:NSMakePoint(([event deltaX]*10),([event deltaY]*10*-1))]) {
					return;
				} else {
					if ([event deltaY] < 0) {
						[imageView next];
					} else if ([event deltaY] > 0) {
						[imageView prev];
					}
				}
				return;
			case 2:
				if (![imageView scrollTo:NSMakePoint(([event deltaX]*10),([event deltaY]*10*-1))]) {
					return;
				} else {
					if ([event deltaY] < 0) {
						if (![imageView next]) {
							return;
						} else {
							useComposedImage = YES;
							[self imageDisplay];
						}
					} else if ([event deltaY] > 0) {
						if (![imageView prev]) {
							return;
						} else {
							useComposedImage = NO;
							if (prevPageMode == 1) [imageView setStartFromEnd:YES];
							[self prevPage];
						}
					}
				}
				return;
			case 3:
				break;
			default:break;
		}
	}
	
	if (wheelSensitivity == 0.0) {
		return;
	}
	float wheelCount = [event deltaY];
	
	float temp = wheelSensitivity;
	if (wheelCount < 0) {
		temp = -1*wheelSensitivity;
		if (wheelCount <= temp) {
			if (wheelUpTimer) {
				return;
			} else {
				wheelDownTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self
																selector:@selector(wheelDown)
																userInfo:NULL
																 repeats:NO];
			}
		}
	} else {
		if (wheelCount >= temp) {
			if (wheelDownTimer) {
				return;
			} else {
				wheelUpTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self
															  selector:@selector(wheelUp)
															  userInfo:NULL
															   repeats:NO];
			}
		}
	}
}


#pragma mark inAction

- (IBAction)showInFinderSecond:(id)sender
{
	int i = nowPage;
	i--;
	NSString *currentFilePath = [imageLoader itemPathAtIndex:i];
	[[NSWorkspace sharedWorkspace] selectFile:currentFilePath inFileViewerRootedAtPath:@""];
	/*
	if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:[currentFilePath stringByDeletingLastPathComponent]]) {
		[[NSWorkspace sharedWorkspace] selectFile:[currentFilePath stringByDeletingLastPathComponent] inFileViewerRootedAtPath:nil];
	} else {
		[[NSWorkspace sharedWorkspace] selectFile:currentFilePath inFileViewerRootedAtPath:nil];
	}*/
}

- (IBAction)showInFinderFirst:(id)sender
{
	int i = nowPage;
	i--;
	if (secondImage) i--;
	NSString *currentFilePath = [imageLoader itemPathAtIndex:i];
	[[NSWorkspace sharedWorkspace] selectFile:currentFilePath inFileViewerRootedAtPath:@""];
	/*
	if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:[currentFilePath stringByDeletingLastPathComponent]]) {
		[[NSWorkspace sharedWorkspace] selectFile:[currentFilePath stringByDeletingLastPathComponent] inFileViewerRootedAtPath:nil];
	} else {
		[[NSWorkspace sharedWorkspace] selectFile:currentFilePath inFileViewerRootedAtPath:nil];
	}*/
}

- (IBAction)viewAtOriginalSizeFirst:(id)sender
{
	if (timerSwitch) {
		[timer invalidate];
		timerSwitch=NO;
	}
	id scrollView = [fullImageView enclosingScrollView];
	
	[fullImageView setImage:nil];
	[fullImageView setImageScaling:NSImageScaleNone];
	int i;
	if (!secondImage) {
		i = nowPage - 1;
		[fullImageView setImage:firstImage];
	} else {
		i = nowPage - 2;
		[fullImageView setImage:firstImage];
	}
	
    NSSize theScrollViewSize = [NSScrollView
                                frameSizeForContentSize:[fullImageView frame].size
                                horizontalScrollerClass:nil
                                  verticalScrollerClass:nil
                                             borderType:[scrollView borderType]
                                            controlSize:NSControlSizeRegular
                                          scrollerStyle:[scrollView scrollerStyle]
    ];
	[fullImagePanel setContentSize:theScrollViewSize];
	
	NSRect theScrollViewRect;
	theScrollViewRect.origin = NSZeroPoint;
	theScrollViewRect.size = theScrollViewSize;
	NSRect theWindowMaxRect = [ NSWindow
				 frameRectForContentRect:theScrollViewRect
							   styleMask:[ fullImagePanel styleMask]
		];
	NSRect fullscreenRect = [[NSScreen mainScreen] frame];
	if (theWindowMaxRect.size.width > fullscreenRect.size.width) {
		theWindowMaxRect.size.width = fullscreenRect.size.width;
	}
	[fullImagePanel setMaxSize:theWindowMaxRect.size];
	
	[fullImagePanel setTitle:[NSString stringWithFormat:@"original %@",[[completeMutableArray objectAtIndex:i] lastPathComponent]]];
	
	if (readMode == 0 || readMode == 2) {
		[fullImagePanel setFrameOrigin:NSMakePoint(fullscreenRect.size.width - theWindowMaxRect.size.width,0)];
	} else {
		[fullImagePanel setFrameOrigin:NSMakePoint(0,5)];
	}
	
	[fullImagePanel makeKeyAndOrderFront:self];
}

- (IBAction)viewAtOriginalSizeSecond:(id)sender
{
	if (timerSwitch) {
		[timer invalidate];
		timerSwitch=NO;
	}
	id scrollView = [fullImageView enclosingScrollView];
	[fullImageView setImage:nil];
	[fullImageView setImageScaling:NSImageScaleNone];
	int i;
	if (!secondImage) {
		i = nowPage - 1;
		[fullImageView setImage:firstImage];
	} else {
		i = nowPage - 1;
		[fullImageView setImage:secondImage];
	}
    NSSize theScrollViewSize = [NSScrollView
                                frameSizeForContentSize:[fullImageView frame].size
                                horizontalScrollerClass:nil
                                  verticalScrollerClass:nil
                                             borderType:[scrollView borderType]
                                            controlSize:NSControlSizeRegular
                                          scrollerStyle:[scrollView scrollerStyle]
    ];
	[fullImagePanel setContentSize:theScrollViewSize];
	NSRect theScrollViewRect;
	theScrollViewRect.origin = NSZeroPoint;
	theScrollViewRect.size = theScrollViewSize;
	NSRect theWindowMaxRect = [ NSWindow
                     frameRectForContentRect:theScrollViewRect
								   styleMask:[ fullImagePanel styleMask]
		];
	NSRect fullscreenRect = [[NSScreen mainScreen] frame];
	if (theWindowMaxRect.size.width > fullscreenRect.size.width) {
		theWindowMaxRect.size.width = fullscreenRect.size.width;
	}
	[fullImagePanel setMaxSize:theWindowMaxRect.size];
	
	[fullImagePanel setTitle:[NSString stringWithFormat:@"original %@",[[completeMutableArray objectAtIndex:i] lastPathComponent]]];
	
	if (readMode == 0 || readMode == 2) {
		[fullImagePanel setFrameOrigin:NSMakePoint(0,5)];
	} else {
		[fullImagePanel setFrameOrigin:NSMakePoint(fullscreenRect.size.width - theWindowMaxRect.size.width,0)];
	}
	
	[fullImagePanel makeKeyAndOrderFront:self];
}




- (void)changeReadMode:(int)mode
{
	if (readMode == mode) {
		return;
	}
	readMode = mode;
	
	if (secondImage){
		nowPage -= 2;
		[imageMutableArray insertObject:secondImage atIndex:0];
		[imageMutableArray insertObject:firstImage atIndex:0];
	} else if ([imageView image]) {
		nowPage--;
		[imageMutableArray insertObject:firstImage atIndex:0];
	} else {
		return;
	}
	
	
	if (rememberBookSettings) {
		[currentBookSetting setObject:[NSNumber numberWithInt:mode] forKey:@"readMode"];
	}
	
	[self viewSet];
	[self imageDisplay];
	
	
	if (readMode == 1) {
		[imageView setInfoString:[NSString stringWithFormat:@"read:left to right"]];
	} else if (readMode == 2) {
		[imageView setInfoString:[NSString stringWithFormat:@"read:right to left(single)"]];
	} else if (readMode == 3) {
		[imageView setInfoString:[NSString stringWithFormat:@"read:left to right(single)"]];
	} else if (readMode == 0) {
		[imageView setInfoString:[NSString stringWithFormat:@"read:right to left"]];
	}
}
- (void)setSortMode:(int)mode page:(int)p
{
	// Stop any background lookahead thread before mutating completeMutableArray to prevent crashes
	threadStop = YES;
	[lock lock];
	[lock unlock];
	threadStop = NO;

	//if (sortMode != mode) {
	sortMode = mode;
	[completeMutableArray sortUsingSelector:@selector(finderCompareS:)];
	switch (mode) {
		case 0:
			//name
			//[completeMutableArray sortUsingSelector:@selector(finderCompareS:)];
			[imageView setInfoString:[NSString stringWithFormat:@"sort:name%@",sortDescending?@"(desc)":@"(asc)"]];
			break;
		case 1:
			//random - Fisher-Yates shuffle (uniform distribution, unbiased)
			for (NSInteger i = (NSInteger)[completeMutableArray count] - 1; i > 0; i--) {
				NSInteger j = (NSInteger)arc4random_uniform((uint32_t)(i + 1));
				[completeMutableArray exchangeObjectAtIndex:(NSUInteger)i withObjectAtIndex:(NSUInteger)j];
			}
			[imageView setInfoString:[NSString stringWithFormat:@"sort:shuffle"]];
			break;
		case 2:
			//creation
			if ([imageLoader canSortByDate]) {
				[completeMutableArray sortUsingSelector:@selector(fileCreationDateCompare:)];
				[imageView setInfoString:[NSString stringWithFormat:@"sort:Creation Date%@",sortDescending?@"(desc)":@"(asc)"]];
			}
			break;
		case 3:
			//modification
			if ([imageLoader canSortByDate]) {
				[completeMutableArray sortUsingSelector:@selector(fileModificationDateCompare:)];
				[imageView setInfoString:[NSString stringWithFormat:@"sort:Modification Date%@",sortDescending?@"(desc)":@"(asc)"]];
			}
			break;
		default:
			//[completeMutableArray sortUsingSelector:@selector(finderCompareS:)];
			break;
	}
	if ([self co_sortModeSupportsDescending:sortMode] && sortDescending) {
		NSArray *reversedArray = [[completeMutableArray reverseObjectEnumerator] allObjects];
		[completeMutableArray setArray:reversedArray];
	}
	// Never persist shuffle (mode==1) to book settings — shuffle is always started explicitly
	if (rememberBookSettings && p>-1 && mode != 1) {
		[currentBookSetting setObject:[NSNumber numberWithInt:mode] forKey:@"sortMode"];
		[currentBookSetting setObject:[NSNumber numberWithBool:sortDescending] forKey:@"sortDescending"];
	}
	
	if (p >= 0) [self goTo:p array:nil];
	//}
}

- (void)setSortDescending:(BOOL)descending page:(int)p
{
	if (![self co_sortModeSupportsDescending:sortMode]) {
		descending = NO;
	}
	sortDescending = descending;
	[self setSortMode:sortMode page:p];
}



- (void)prevPage
{
	if (readMode > 1) {
		if (nowPage < 2) {
			if (loopCheck == 0) {
				threadStop = YES;
				[lock lock];
				[lock unlock];
				threadStop = NO;
				[imageMutableArray removeAllObjects];
				nowPage = (int)[completeMutableArray count];
				nowPage --;
				[self lookahead];
			} else if (loopCheck == 1) {
				[lock lock];
				[lock unlock];
				[self backFolder];
				return;
			} else if (loopCheck == 2) {
				[lock lock];
				[lock unlock];
				[self backFolderLast];
				return;
			} else {
				return;
			}
		} else {
			threadStop = YES;
			[lock lock];
			[lock unlock];
			threadStop = NO;
			[imageMutableArray removeAllObjects];
			nowPage -= 2;
			[self lookahead];
		}
		[self imageDisplay];
	} else {
		if (!secondImage) {
			if (nowPage < 2) {
				if (loopCheck == 0) {
					threadStop = YES;
					[lock lock];
					[lock unlock];
					threadStop = NO;
					[imageMutableArray removeAllObjects];
					nowPage = (int)[completeMutableArray count];
					nowPage -= 2;
					if (bufferingMode == 0 && screenCache>0) [self imageDisplayIfHasScreenCache];
					[self lookahead];
					if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO) {
						[imageMutableArray removeObjectAtIndex:0];
						nowPage++;
					} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
						[imageMutableArray removeObjectAtIndex:0];
						nowPage++;
					}
					[self imageDisplay];
					return;
				} else if (loopCheck == 1) {
					[lock lock];
					[lock unlock];
					[self backFolder];
					return;
				} else if (loopCheck == 2) {
					[lock lock];
					[lock unlock];
					[self backFolderLast];
					return;
				} else {
					return;
				}
			} else if (nowPage == 2) {
				[lock lock];
				[lock unlock];
				nowPage = 0;
				[imageMutableArray insertObject:[self loadImage:nowPage] atIndex:0];
				//[imageMutableArray insertObject:[imageView image] atIndex:1];
				//[imageMutableArray insertObject:[self loadImage:nowPage+1] atIndex:1];
				nowPage += 2;
				[imageMutableArray insertObject:[self loadImage:nowPage-1] atIndex:1];
				nowPage -= 2;
			} else if (nowPage > 2) {
				threadStop = YES;
				[lock lock];
				[lock unlock];
				threadStop = NO;
				[imageMutableArray removeAllObjects];
				nowPage -= 3;
				if (bufferingMode == 0 && screenCache>0) [self imageDisplayIfHasScreenCache];
				[self lookahead];
				//NSLog(@"1 %@",imageMutableArray);
				//[imageMutableArray addObject:[imageView image]];
				//[imageMutableArray addObject:[self loadImage:nowPage+2]];
				nowPage += 3;
				[imageMutableArray addObject:[self loadImage:nowPage-1]];
				nowPage -= 3;
				//NSLog(@"2 %@",imageMutableArray);
				if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO){
					nowPage++;
					[imageMutableArray removeObjectAtIndex:0];
				} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
					nowPage++;
					[imageMutableArray removeObjectAtIndex:0];
				}
				[self imageDisplay];
				return;
			}
		} else {
			if (nowPage < 3) {
				if (loopCheck == 0) {
					threadStop = YES;
					[lock lock];
					[lock unlock];
					threadStop = NO;
					[imageMutableArray removeAllObjects];
					nowPage = (int)[completeMutableArray count];
					nowPage -= 2;
					if (bufferingMode == 0 && screenCache>0) [self imageDisplayIfHasScreenCache];
					[self lookahead];
					if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO) {
						[imageMutableArray removeObjectAtIndex:0];
						nowPage++;
					} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
						[imageMutableArray removeObjectAtIndex:0];
						nowPage++;
					}
					[self imageDisplay];
					return;
				} else if (loopCheck == 1) {
					[lock lock];
					[lock unlock];
					[self backFolder];
					return;
				} else if (loopCheck == 2) {
					[lock lock];
					[lock unlock];
					[self backFolderLast];
					return;
				} else {
					return;
				}
			} else if (nowPage < 4) {
				threadStop = YES;
				[lock lock];
				[lock unlock];
				threadStop = NO;
				[imageMutableArray removeAllObjects];
				nowPage -= 3;
				if (bufferingMode == 0 && screenCache>0) [self imageDisplayIfHasScreenCache];
				[imageMutableArray addObject:[self loadImage:nowPage]];
				//[imageMutableArray addObject:firstImage];
				//[imageMutableArray addObject:secondImage];
				//[imageMutableArray addObject:[self loadImage:nowPage+1]];
				//[imageMutableArray addObject:[self loadImage:nowPage+2]];
				nowPage += 3;
				[imageMutableArray addObject:[self loadImage:nowPage-2]];
				[imageMutableArray addObject:[self loadImage:nowPage-1]];
				nowPage -= 3;
				[self imageDisplay];
				return;
			} else if (nowPage > 3) {
				threadStop = YES;
				[lock lock];
				[lock unlock];
				threadStop = NO;
				[imageMutableArray removeAllObjects];
				nowPage -= 4;
				if (bufferingMode == 0 && screenCache>0) [self imageDisplayIfHasScreenCache];				
				[self lookahead];
				//[imageMutableArray addObject:firstImage];
				//[imageMutableArray addObject:secondImage];
				//[imageMutableArray addObject:[self loadImage:nowPage+2]];
				//[imageMutableArray addObject:[self loadImage:nowPage+3]];
				nowPage += 4;
				[imageMutableArray addObject:[self loadImage:nowPage-2]];
				[imageMutableArray addObject:[self loadImage:nowPage-1]];
				nowPage -= 4;
				
				if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO){
					nowPage++;
					[imageMutableArray removeObjectAtIndex:0];
				} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
					nowPage++;
					[imageMutableArray removeObjectAtIndex:0];
				}
				[self imageDisplay];
				return;
			}
		}
		[self imageDisplay];
	}
}

- (void)halfprevPage
{
	if (readMode > 1) {
		if (nowPage <2) {
			if (loopCheck == 0) {
				[imageMutableArray removeAllObjects];
				nowPage = (int)[completeMutableArray count];
				nowPage --;
				[self lookahead];
			} else if (loopCheck == 1) {
				[self backFolder];
				return;
			} else if (loopCheck == 2) {
				[self backFolderLast];
				return;
			} else {
				return;
			}
		} else {
			[imageMutableArray removeAllObjects];
			nowPage -= 2;
			[self lookahead];
		}
		[self imageDisplay];
	} else {
		if (!secondImage) {
			if (nowPage <2) {
				if (loopCheck == 0) {
					[imageMutableArray removeAllObjects];
					nowPage = (int)[completeMutableArray count];
					nowPage --;
					[self lookahead];
				} else if (loopCheck == 1) {
					[self backFolder];
					return;
				} else if (loopCheck == 2) {
					[self backFolderLast];
					return;
				} else {
					return;
				}
			} else if (nowPage == 2) {
				nowPage = 0;
				[imageMutableArray insertObject:[self loadImage:nowPage] atIndex:0];
				//[imageMutableArray insertObject:[imageView image] atIndex:1];
				//[imageMutableArray insertObject:[self loadImage:nowPage+1] atIndex:1];
				nowPage += 2;
				[imageMutableArray insertObject:[self loadImage:nowPage-1] atIndex:1];
				nowPage -= 2;
			} else if (nowPage > 2) {
				[imageMutableArray removeAllObjects];
				nowPage -= 3;
				[self lookahead];
				//[imageMutableArray addObject:[imageView image]];
				//[imageMutableArray addObject:[self loadImage:nowPage+2]];
				nowPage += 3;
				[imageMutableArray addObject:[self loadImage:nowPage-1]];
				nowPage -= 3;
				if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO){
					nowPage++;
					[imageMutableArray removeObjectAtIndex:0];
				} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
					nowPage++;
					[imageMutableArray removeObjectAtIndex:0];
				} else {
				}
				
			}
		} else {
			if (nowPage < 3) {
				if (loopCheck == 0) {
					[imageMutableArray removeAllObjects];
					nowPage = (int)[completeMutableArray count];
					nowPage -= 2;
					[self lookahead];
					if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO) {
						[imageMutableArray removeObjectAtIndex:0];
						nowPage++;
					} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
						[imageMutableArray removeObjectAtIndex:0];
						nowPage++;
					}
				} else if (loopCheck == 1) {
					[self backFolder];
					return;
				} else if (loopCheck == 2) {
					[self backFolderLast];
					return;
				} else {
					return;
				}
			} else if (nowPage > 2) {
				[imageMutableArray removeAllObjects];
				nowPage -= 3;
				
				[imageMutableArray addObject:[self loadImage:nowPage]];
				//[imageMutableArray addObject:firstImage];
				//[imageMutableArray addObject:[self loadImage:nowPage+1]];
				nowPage += 3;
				[imageMutableArray addObject:[self loadImage:nowPage-2]];
				nowPage -= 3;
			}
		}	
		[self imageDisplay];
	}
}

-(void)goToLast
{
	if (nowPage < [completeMutableArray count]) {
		useComposedImage = NO;
		[imageMutableArray removeAllObjects];
		nowPage = (int)[completeMutableArray count];
		if (readMode > 1) {
			nowPage--;
			[self lookahead];
		} else {
			nowPage -= 2;
			[self lookahead];
			if ([self isSmallImage:[imageMutableArray objectAtIndex:0] page:nowPage+1] == NO) {
				[imageMutableArray removeObjectAtIndex:0];
				nowPage++;
			} else if ([self isSmallImage:[imageMutableArray objectAtIndex:1] page:nowPage+2] == NO) {
				[imageMutableArray removeObjectAtIndex:0];
				nowPage++;
			}
		}
		[self imageDisplay];
	}
}
-(void)goToFirst
{
	useComposedImage = NO;
	[imageMutableArray removeAllObjects];
	nowPage = 0;
	[self lookahead];
	[self imageDisplay];
}
-(void)showThumbnail
{	
	if (secondImage) {
		int temp = nowPage;
		temp--;
		[thumController showThumbnail:temp];
	} else {
		[thumController showThumbnail:nowPage];
	}
}

- (NSString *)co_bookmarkTitleForPage:(int)page
{
	NSEnumerator *enumerator = [bookmarkArray objectEnumerator];
	id object;
	while (object = [enumerator nextObject]) {
		if ([[object objectForKey:@"page"] intValue] == page) {
			return [object objectForKey:@"name"];
		}
	}
	return nil;
}

- (void)co_jumpToBookmarkPage:(int)page
{
	nowPage = page - 1;
	[imageMutableArray removeAllObjects];
	[self lookahead];
	[self imageDisplay];
	[imageView setInfoString:[self co_bookmarkTitleForPage:page]];
}

-(void)nextBookmark
{
	useComposedImage = NO;
	NSMutableArray *pages = [NSMutableArray array];
	int i;
	for (i = 0; i < [bookmarkArray count]; i++) {
		[pages addObject:[NSNumber numberWithInt:[[[bookmarkArray objectAtIndex:i] objectForKey:@"page"] intValue]]];
	}
	int currentEffectivePage = nowPage;
	if (secondImage) {
		currentEffectivePage--;
	}
	NSNumber *target = [ViewerBookmarkSearch nextBookmarkPageWithBookmarkPages:pages currentEffectivePage:currentEffectivePage];
	if (!target) return;
	[self co_jumpToBookmarkPage:[target intValue]];
}

-(void)backBookmark
{
	useComposedImage = NO;
	NSMutableArray *pages = [NSMutableArray array];
	int i;
	for (i = 0; i < [bookmarkArray count]; i++) {
		[pages addObject:[NSNumber numberWithInt:[[[bookmarkArray objectAtIndex:i] objectForKey:@"page"] intValue]]];
	}
	int currentEffectivePage = nowPage;
	if (secondImage) {
		currentEffectivePage--;
	}
	NSNumber *target = [ViewerBookmarkSearch previousBookmarkPageWithBookmarkPages:pages currentEffectivePage:currentEffectivePage];
	if (!target) return;
	[self co_jumpToBookmarkPage:[target intValue]];
}

-(void)nextFolder
{
	if ([[[openSameFolderMenuItem submenu] itemArray] count] > 0) {
		NSArray *items = [[openSameFolderMenuItem submenu] itemArray];
		NSEnumerator *enumerator = [items objectEnumerator];
		id object;
		while (object = [enumerator nextObject]) {
			if ([object state] == NSControlStateValueOn){
				[object setState:NSControlStateValueOff];
				while (object = [enumerator nextObject]) {
					if ([object isEnabled]) {
						break;
					}
				}
				if (!object) {
					object = [[[openSameFolderMenuItem submenu] itemArray] objectAtIndex:0];
				}
				[object setState:NSControlStateValueOn];
				break;
			}
		}
		if (!object) {
			enumerator = [items objectEnumerator];
			while (object = [enumerator nextObject]) {
				if ([object isEnabled]) {
					[object setState:NSControlStateValueOn];
					break;
				}
			}
		}
		if (!object) return;
		[self openFromSameDir:object];
	}
}

-(void)backFolder
{
	if ([[[openSameFolderMenuItem submenu] itemArray] count] > 0) {
		NSArray *items = [[openSameFolderMenuItem submenu] itemArray];
		NSEnumerator *enumerator = [items reverseObjectEnumerator];
		id object;
		while (object = [enumerator nextObject]) {
			if ([object state] == NSControlStateValueOn){
				[object setState:NSControlStateValueOff];
				while (object = [enumerator nextObject]) {
					if ([object isEnabled]) {
						break;
					}
				}				
				if (!object) {
					object = [[[openSameFolderMenuItem submenu] itemArray] lastObject];
				}
				[object setState:NSControlStateValueOn];
				break;
			}
		}
		if (!object) {
			enumerator = [items reverseObjectEnumerator];
			while (object = [enumerator nextObject]) {
				if ([object isEnabled]) {
					[object setState:NSControlStateValueOn];
					break;
				}
			}
		}
		if (!object) return;
		[self openFromSameDir:object];
	}
}

-(void)backFolderLast
{
	if ([[[openSameFolderMenuItem submenu] itemArray] count] > 0) {
		NSArray *items = [[openSameFolderMenuItem submenu] itemArray];
		NSEnumerator *enumerator = [items reverseObjectEnumerator];
		id object;
		while (object = [enumerator nextObject]) {
			if ([object state] == NSControlStateValueOn){
				[object setState:NSControlStateValueOff];
				while (object = [enumerator nextObject]) {
					if ([object isEnabled]) {
						break;
					}
				}				
				if (!object) {
					object = [[[openSameFolderMenuItem submenu] itemArray] lastObject];
				}
				[object setState:NSControlStateValueOn];
				break;
			}
		}
		if (!object) {
			enumerator = [items reverseObjectEnumerator];
			while (object = [enumerator nextObject]) {
				if ([object isEnabled]) {
					[object setState:NSControlStateValueOn];
					break;
				}
			}
		}
		if (!object) return;
		[self openFromSameDir:object last:YES];
	}
}

- (void)nextSubFolder
{
	[lock lock];
	[lock unlock];
	int nextNow = [imageLoader nextFolder:nowPage];
	[self goTo:nextNow array:nil];
}

- (void)prevSubFolder
{
	[lock lock];
	[lock unlock];
	int prevNow;
	if (secondImage) {
		prevNow = [imageLoader prevFolder:nowPage-1];
	} else {
		prevNow = [imageLoader prevFolder:nowPage];
	}
	[self goTo:prevNow array:nil];
}

-(void)nextOriginal
{
	int i;
	if ([fullImageView image] == secondImage) {
		[self imageDisplay];
		if (secondImage){
			[fullImageView setImage:firstImage];
			i = nowPage;
			i-=2;
		} else {
			[fullImageView setImage:firstImage];
			i = nowPage;
			i--;
		}
	} else {
		if (secondImage){
			[fullImageView setImage:secondImage];
			i = nowPage;
			i--;
		} else {
			[self imageDisplay];
			if (secondImage){
				[fullImageView setImage:firstImage];
				i = nowPage;
				i -=2;
			} else {
				[fullImageView setImage:firstImage];
				i = nowPage;
				i--;
			}
		}
	}
	
	[fullImagePanel setTitle:[NSString stringWithFormat:@"original %@",[[completeMutableArray objectAtIndex:i] lastPathComponent]]];
}

-(void)prevOriginal
{
	int i;
	if ([fullImageView image] == secondImage) {
		[fullImageView setImage:firstImage];
		i = nowPage;
		i-=2;
	} else {
		[self prevPage];
		if (secondImage){
			[fullImageView setImage:secondImage];
			i = nowPage;
			i--;
		} else {
			[fullImageView setImage:firstImage];
			i = nowPage;
			i--;
		}
	}
	[fullImagePanel setTitle:[NSString stringWithFormat:@"original %@",[[completeMutableArray objectAtIndex:i] lastPathComponent]]];
}



- (void)wheelUp
{
	useComposedImage = NO;
	[self prevPage];
	wheelUpTimer = nil;
}
- (void)wheelDown
{
	useComposedImage = YES;
	[self imageDisplay];
	wheelDownTimer = nil;
}

- (void)goTo:(int)page array:(NSArray*)array
{
	//[completeMutableArray autorelease];
	if (array == nil) {
		//[completeMutableArray retain];
	} else {
		//[completeMutableArray removeAllObjects];
		//[completeMutableArray addObjectsFromArray:array];
	}
	[composedImage release];
	composedImage = nil;
	nowPage = page;
	if (nowPage < 0) {
		nowPage = 0;
	} else if (nowPage >= [completeMutableArray count]) {
		nowPage = (int)[completeMutableArray count]-1;
	}
	[imageMutableArray removeAllObjects];
	[self lookahead];
	[self imageDisplay];
}

- (void)addBookmark
{
	if (!secondImage) {
		[self addBookmarkWithPage:nowPage];
	} else {
		[self addBookmarkWithPage:nowPage-1];
	}
	[imageView setInfoString:@"Add bookmark"];
}
- (BOOL)isBookmarkedPage:(int)page
{
	id bookmark;
	int index;
	for (index=0; index<[bookmarkArray count]; index++) {
		bookmark = [bookmarkArray objectAtIndex:index];
		if ([[bookmark objectForKey:@"page"] intValue] == page) {
			return YES;
		}
	}
	return NO;
}
- (BOOL)removeBookmark
{
	BOOL b = NO;
	if (!secondImage) {
		b = [self removeBookmarkWithPage:nowPage];
	} else {
		b = [self removeBookmarkWithPage:nowPage-1];
		if (!b) {
			b = [self removeBookmarkWithPage:nowPage];
		}
	}
	if (b) [imageView setInfoString:[NSString stringWithFormat:@"Remove bookmark"]];
	return b;
}

- (void)goToPar:(float)par
{
	threadStop = YES;
	[lock lock];
	[lock unlock];
	threadStop = NO;
	
	float temp = (int)[completeMutableArray count]*par;
	int page = (int)temp;
	nowPage = page;
	if (nowPage < 0) {
		nowPage = 0;
	}
	[composedImage release];
	composedImage = nil;
	[imageMutableArray removeAllObjects];
	[self lookahead];
	[self imageDisplay];
}


- (IBAction)switchSingle:(id)sender
{
	NSString *string;
	if (secondImage) {
		[imageMutableArray insertObject:secondImage atIndex:0];
		[secondImage release];
		secondImage = nil;
		[imageView setImage:firstImage];
		/*
		NSImage* temp = firstImage;
		firstImage = nil;
		[imageView setImage:temp];
		[temp release];*/
		nowPage--;
		if ([marksArray containsObject:[NSString stringWithFormat:@"%i",nowPage]]) {
			[marksArray removeObject:[NSString stringWithFormat:@"%i",nowPage]];
		}
		if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",nowPage-1,nowPage]]) {
			[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",nowPage-1,nowPage]];
		}
		if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",nowPage,nowPage+1]]) {
			[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",nowPage,nowPage+1]];
		}
		string = [NSString stringWithFormat:@"%i",nowPage];
		[marksArray addObject:string];
		
		if (readMode > 1) {
			[NSThread detachNewThreadSelector:@selector(lookahead) toTarget:self withObject:nil];
		} else {
			[NSThread detachNewThreadSelector:@selector(lookaheadAndCompose) toTarget:self withObject:nil];
		}
	} else {
		if (nowPage == [completeMutableArray count]) {
			if ([self isSmallImage:firstImage page:nowPage]) {
				if ([marksArray containsObject:[NSString stringWithFormat:@"%i",nowPage]]) {
					[marksArray removeObject:[NSString stringWithFormat:@"%i",nowPage]];
				}
				if ([marksArray containsObject:[NSString stringWithFormat:@"%i",nowPage-1]]) {
					[marksArray removeObject:[NSString stringWithFormat:@"%i",nowPage-1]];
				}
				if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",nowPage-1,nowPage]]) {
					[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",nowPage-1,nowPage]];
				}
				if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",nowPage,nowPage+1]]) {
					[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",nowPage,nowPage+1]];
				}
				string = [NSString stringWithFormat:@"%i",nowPage];
				[marksArray addObject:string];
			} else {
				if ([marksArray containsObject:[NSString stringWithFormat:@"%i",nowPage]]) {
					[marksArray removeObject:[NSString stringWithFormat:@"%i",nowPage]];
				}
				if ([marksArray containsObject:[NSString stringWithFormat:@"%i",nowPage-1]]) {
					[marksArray removeObject:[NSString stringWithFormat:@"%i",nowPage-1]];
				}
				if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",nowPage-1,nowPage]]) {
					[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",nowPage-1,nowPage]];
				}
				if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",nowPage,nowPage+1]]) {
					[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",nowPage,nowPage+1]];
				}
				string = [NSString stringWithFormat:@"%i-%i",nowPage,nowPage+1];
				[marksArray addObject:string];
			}
			return;
		}
		//firstImage = [[imageView image] retain];
		secondImage = [[imageMutableArray objectAtIndex:0] retain];
		[imageMutableArray removeObjectAtIndex:0];
		[self composeImage];
		nowPage++;
		if ([marksArray containsObject:[NSString stringWithFormat:@"%i",nowPage]]) {
			[marksArray removeObject:[NSString stringWithFormat:@"%i",nowPage]];
		}
		if ([marksArray containsObject:[NSString stringWithFormat:@"%i",nowPage-1]]) {
			[marksArray removeObject:[NSString stringWithFormat:@"%i",nowPage-1]];
		}
		if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",nowPage-1,nowPage]]) {
			[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",nowPage-1,nowPage]];
		}
		if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",nowPage,nowPage+1]]) {
			[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",nowPage,nowPage+1]];
		}
		string = [NSString stringWithFormat:@"%i-%i",nowPage-1,nowPage];
		[marksArray addObject:string];
		if (readMode > 1) {
			[NSThread detachNewThreadSelector:@selector(lookahead) toTarget:self withObject:nil];
		} else {
			[NSThread detachNewThreadSelector:@selector(lookaheadAndCompose) toTarget:self withObject:nil];
		}
	}
	[self setPageTextField];
	
	if (rememberBookSettings && [marksArray count] > 0) {
		[currentBookSetting setObject:marksArray forKey:@"marks"];
	}
	
}


static NSTimer* dontSleepTimer = nil;

-(IBAction)slideshow:(id)sender
{
	if ([window isVisible]) {		
		[NSCursor setHiddenUntilMouseMoves:YES];
		if (timerSwitch) {
			[dontSleepTimer invalidate];
			dontSleepTimer = nil;
			[timer invalidate];
			timerSwitch=NO;
			[imageView setSlideshow:NO];
		} else {
			timer = [NSTimer scheduledTimerWithTimeInterval:sliderValue
													 target:self
												   selector:@selector(doSlideshow)
												   userInfo:NULL
													repeats:YES];
			timerSwitch=YES;
			if (dontSleepTimer == nil) {
				dontSleepTimer = [NSTimer scheduledTimerWithTimeInterval:25.0
																  target:self
																selector:@selector(dontSleep)
																userInfo:NULL
																 repeats:YES];
			}
			[imageView setSlideshow:YES];
		}
		if ([window respondsToSelector:@selector(refreshCursorAutoHide)]) {
			[(CustomWindow *)window refreshCursorAutoHide];
		}
	}
}

-(void)doSlideshow
{
	[lock lock];
	[lock unlock];
	useComposedImage = YES;
	[self imageDisplay];
}

-(void)dontSleep
{
	UpdateSystemActivity( OverallAct );
	//UpdateSystemActivity( UsrActivity );
}

- (void)switchSingleWithPage:(int)page
{
	//NSLog(@"single %i,%i",page,nowPage);
	if (page == nowPage-1) {
		[self switchSingle:nil];
		return;
	}
	NSString *string;
	if ([marksArray containsObject:[NSString stringWithFormat:@"%i",page]]) {
		[marksArray removeObject:[NSString stringWithFormat:@"%i",page]];
	}
	if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",page-1,page]]) {
		[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",page-1,page]];
	}
	if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",page,page+1]]) {
		[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",page,page+1]];
	}
	string = [NSString stringWithFormat:@"%i",page];
	[marksArray addObject:string];
	
	if (rememberBookSettings && [marksArray count] > 0) {
		[currentBookSetting setObject:marksArray forKey:@"marks"];
	}
}

- (void)switchBindWithPage:(int)page
{
	//NSLog(@"bind %i,%i",page,nowPage);
	if (page == nowPage) {
		[self switchSingle:nil];
		return;
	}
	NSString *string;
	if (page == [completeMutableArray count]) {
		if ([marksArray containsObject:[NSString stringWithFormat:@"%i",page-1]]) {
			[marksArray removeObject:[NSString stringWithFormat:@"%i",page-1]];
		}
		string = [NSString stringWithFormat:@"%i-%i",page-1,page];
	} else {
		string = [NSString stringWithFormat:@"%i-%i",page,page+1];
	}
	if ([marksArray containsObject:[NSString stringWithFormat:@"%i",page]]) {
		[marksArray removeObject:[NSString stringWithFormat:@"%i",page]];
	}
	if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",page-1,page]]) {
		[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",page-1,page]];
	}
	if ([marksArray containsObject:[NSString stringWithFormat:@"%i-%i",page,page+1]]) {
		[marksArray removeObject:[NSString stringWithFormat:@"%i-%i",page,page+1]];
	}
	
	[marksArray addObject:string];
	
	if (rememberBookSettings && [marksArray count] > 0) {
		[currentBookSetting setObject:marksArray forKey:@"marks"];
	}
	
}

- (BOOL)removeBookmarkWithPage:(int)page
{	
	BOOL result = NO;
	if ([self isBookmarkedPage:page]) {
		result = YES;
	}
	
	if (!result) return result;
	
	id bookmark;
	int index;
	for (index=0; index<[bookmarkArray count]; index++) {
		bookmark = [bookmarkArray objectAtIndex:index];
		if ([[bookmark objectForKey:@"page"] intValue] == page) {
			[bookmarkArray removeObject:bookmark];
		}
	}
	
	[self setBookmarkMenu];
	return result;
}

- (void)addBookmarkWithPage:(int)page
{
	int bookmarkCount = (int)[bookmarkArray count];
	NSString *bookmarkCountName = [NSString stringWithFormat:@"bookmark%d",bookmarkCount + 1];
	NSString *bookmarkNowPageString = [NSString stringWithFormat:@"%d",page];
	
	NSDictionary *bookmarkDic = [NSDictionary dictionaryWithObjectsAndKeys:
		bookmarkCountName, @"name",
		bookmarkNowPageString, @"page",
		nil];
	
	
	[bookmarkArray addObject:bookmarkDic];	
	[self setBookmarkMenu];
}
- (void)trashLeft
{
	int i = [ViewerPageGeometry trashIndexWithIsLeft:YES
										readFromLeft:[self readFromLeft]
								 firstImagePageIndex:[self co_firstImagePageIndex]
								secondImagePageIndex:[self co_secondImagePageIndex]];
	[self trashFile:[imageLoader itemPathAtIndex:i]];
}
- (void)trashRight
{
	int i = [ViewerPageGeometry trashIndexWithIsLeft:NO
										readFromLeft:[self readFromLeft]
								 firstImagePageIndex:[self co_firstImagePageIndex]
								secondImagePageIndex:[self co_secondImagePageIndex]];
	[self trashFile:[imageLoader itemPathAtIndex:i]];
}
- (void)trashFile:(NSString*)path
{
	int result = (int)NSRunAlertPanel(NSLocalizedString(@"Move to Trash",@""),
								 NSLocalizedString(@"Do you really want to move %@ to the trash?",@""),
								 NSLocalizedString(@"OK",@""), 
								 NSLocalizedString(@"Cancel",@""), 
								 nil,
                                 [path lastPathComponent]);
	
	if(result == NSAlertDefaultReturn || result == NSAlertFirstButtonReturn) {
		BOOL b = NO;
		b = [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
														 source:[path stringByDeletingLastPathComponent]
													destination: @""
														  files: [NSArray arrayWithObject:[path lastPathComponent]]
															tag: nil];
		if(!b) {
			NSAppleScript*          script;
			NSAppleEventDescriptor* desc;
			NSDictionary*           error;
			NSString *string;
			//string = [NSString stringWithFormat:@"tell application \"Finder\" to delete POSIX file \"%@\"", [path precomposedStringWithCompatibilityMapping]]; 
			string = [NSString stringWithFormat:@"tell application \"Finder\" to delete selection"];
			script = [[NSAppleScript alloc] initWithSource:string];
			[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
			desc = [script executeAndReturnError:&error];
			//NSLog(@"1 %@ %@",desc,error);
			[script release];
			string = [NSString stringWithFormat:@"tell application \"cooViewer\" to activate"]; 
			script = [[NSAppleScript alloc] initWithSource:string];
			desc = [script executeAndReturnError:&error];
			//NSLog(@"2 %@ %@",desc,error);
			[script release];
			
		}
	}
}
@end
