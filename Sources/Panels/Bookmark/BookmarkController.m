#import "BookmarkController.h"
#import "cooViewer-Swift.h"

@implementation BookmarkController

//const int ITEM_DELETE = 1;
static const int DIALOG_OK		= 128;
static const int DIALOG_CANCEL	= 129;


-(void)awakeFromNib
{
	NSArray *tableRowTypes = [NSArray arrayWithObject:@"row"];
	[bookmarkTableView registerForDraggedTypes:tableRowTypes];
	[allBookmarkTableView registerForDraggedTypes:tableRowTypes];
	
	
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	[bookmarkPanel setFrameAutosaveName:@"Bookmark"];
	[allBookmarkPanel setFrameAutosaveName:@"AllBookmark"];
	if ([defaults stringForKey:@"AllBookmarkSplitPotision"]) {
		[self setSplitViewPosition:allBookmarkSplitView position:[defaults stringForKey:@"AllBookmarkSplitPotision"]];
	}
}

-(void)setPathDic:(NSDictionary*)dic
{
	directoryPath = [dic objectForKey:@"dirPath"];
}

- (NSString *)splitViewPosition:(NSSplitView *)splitView
{
    NSArray *subViews = [splitView subviews];
    int     lenFirst, lenSecond;
	
    lenFirst = [[subViews objectAtIndex: 0] frame].size.width;
    lenSecond = [[subViews objectAtIndex: 1] frame].size.width;
	
	return [NSString stringWithFormat: @"%i %i", lenFirst, lenSecond];
}

- (void)setSplitViewPosition:(NSSplitView *)splitView position:(NSString *)s
{
    NSArray *subViews = [splitView subviews];
    NSRect  newBounds;
    float   dividerWidth = [splitView dividerThickness];
    NSView  *viewZero = [subViews objectAtIndex: 0];
    NSView  *viewOne = [subViews objectAtIndex: 1];
    NSArray *stringComponents = [s componentsSeparatedByString: @" "];
    int     valueZero, valueOne;
	
    valueZero = [[stringComponents objectAtIndex: 0] intValue];
    valueOne = [[stringComponents objectAtIndex: 1] intValue];
	
    int left = valueZero;
    int right = valueOne;
	
    if ((left + right + dividerWidth) != [splitView frame].size.width)
        left = [splitView frame].size.width - dividerWidth - right;
	
    newBounds = [viewZero frame]; 
    newBounds.size.width = left;
    newBounds.origin.x = 0;
    [viewZero setFrame: newBounds];
	
    newBounds = [viewOne frame];
    newBounds.size.width = right;
    newBounds.origin.x = left + dividerWidth;
    [viewOne setFrame: newBounds];
}


#pragma mark editBookmark
-(void)editBookmark:(NSMutableArray*)array
{
	[bookmarkPanel setTarget:self];
    [bookmarkPanel setAction:@selector(keyDown:)];
	bookName = [[directoryPath lastPathComponent] retain];
	//	bookmarkArray = [[defaults objectForKey:bookName] retain];
	// Edit a working copy so Cancel can discard in-progress edits without
	// touching Controller's live bookmarkArray; OK writes the copy back below.
	sourceBookmarkArray = [array retain];
	bookmarkArray = [[NSMutableArray alloc] initWithArray:array];

    [bookmarkTableView setDataSource:(id)self];
    [bookmarkTableView setDelegate:(id)self];
	[bookmarkTableView reloadData];
	
	
	window = [NSApp keyWindow];
    [[NSApplication sharedApplication] beginSheet:bookmarkPanel 
								   modalForWindow:window 
									modalDelegate:self 
								   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
									  contextInfo:nil];	
}


- (void)sheetDidEnd:(NSWindow*)sheet 
		 returnCode:(int)returnCode 
		contextInfo:(void*)contextInfo
{
    [bookmarkPanel orderOut:self];
	[window makeKeyWindow];
    
    if(returnCode == DIALOG_CANCEL) {
		[bookName release];
		[bookmarkArray release];
		bookmarkArray = nil;
		[sourceBookmarkArray release];
		sourceBookmarkArray = nil;
    } else if(returnCode == DIALOG_OK) {
		[bookName release];
		[sourceBookmarkArray setArray:bookmarkArray];
		[bookmarkArray release];
		bookmarkArray = nil;
		[sourceBookmarkArray release];
		sourceBookmarkArray = nil;
		[controller setBookmarkMenu];
    }
}




- (IBAction)ok:(id)sender;
{
	if ([bookmarkPanel isVisible]) {
		[[NSApplication sharedApplication] endSheet:bookmarkPanel returnCode:DIALOG_OK];
	} else {
		[[NSApplication sharedApplication] stopModalWithCode:DIALOG_OK];
	}
}


- (IBAction)cancel:(id)sender;
{
	if ([bookmarkPanel isVisible]) {
		[[NSApplication sharedApplication] endSheet:bookmarkPanel returnCode:DIALOG_CANCEL];
	} else {
		[[NSApplication sharedApplication] stopModalWithCode:DIALOG_CANCEL];
	}
}


- (void)keyDown:(NSEvent *)theEvent
{
	int selectedRow;
	selectedRow = (int)[bookmarkTableView selectedRow];
	if (0 <= selectedRow) {
		[bookmarkArray setArray:[ViewerBookmarkList bookmarksByRemovingBookmarks:bookmarkArray atIndex:selectedRow]];
		[bookmarkTableView reloadData];

	} else {
		NSBeep();
	}
}

#pragma mark editAllBookmark
-(void)editAllBookmark:(NSMutableArray*)array
{
	[allBookmarkPanel setTarget:self];
    [allBookmarkPanel setAction:@selector(keyDownAll:)];
	
    [allBookmarkTableView setDataSource:(id)self];
    [allBookmarkTableView setDelegate:(id)self];
    [allBookmarkTableView setMenu:contextMenuItem];

    [allBookNameTableView setDataSource:(id)self];
    [allBookNameTableView setDelegate:(id)self];

	if (![defaults dictionaryForKey:@"BookSettings"]) {
		allBookmark = [[NSMutableDictionary dictionary] retain];
	} else {
		allBookmark = [[NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"BookSettings"]] retain];
	}
	
	bookNameArray = [[NSMutableArray array] retain];
	NSEnumerator *enu = [allBookmark keyEnumerator];
	id object;
	while (object = [enu nextObject]) {
		if ([[[allBookmark objectForKey:object] allKeys] containsObject:@"bookmarks"]) {
			[bookNameArray addObject:object];
		}
	}
	[bookNameArray sortUsingSelector:@selector(finderCompareS:)];
	
	[allBookmarkTableView reloadData];
	[allBookNameTableView reloadData];
	int result;
	result = (int)[[NSApplication sharedApplication] runModalForWindow:allBookmarkPanel];
	[allBookmarkPanel orderOut:self];
	
	
	[defaults setObject:[self splitViewPosition:allBookmarkSplitView] forKey:@"AllBookmarkSplitPotision"];
	if(result == DIALOG_OK) {
		[defaults setObject:allBookmark forKey:@"BookSettings"];
		[defaults synchronize];
		[allBookmark release];
		allBookmark = nil;
		[bookNameArray release];
		bookNameArray = nil;
		[controller strongSetBookmark];
		return;
	} else if(result == DIALOG_CANCEL) {
		[allBookmark release];
		allBookmark = nil;
		[bookNameArray release];
		bookNameArray = nil;
        return;
    } else {
		return;
	}
}

- (void)keyDownAll:(NSEvent *)theEvent
{
	// Which table has keyboard focus right now decides whether Delete
	// removes a whole book or a single bookmark. This used to be inferred
	// from selectedView (the table last reported by
	// -tableViewSelectionDidChange:), which could go stale and made Delete
	// remove the wrong thing (#106) -- asking the panel who its current
	// first responder is reflects the actual focus at key-press time.
	id responder = [allBookmarkPanel firstResponder];
	if (responder == allBookNameTableView) {
		int selectedRow = (int)[allBookNameTableView selectedRow];
		if (selectedRow > -1) {
			ViewerBookmarkBookListResult *result = [ViewerBookmarkBookList removingBookNames:bookNameArray books:allBookmark atIndex:selectedRow];
			[bookNameArray setArray:result.names];
			[allBookmark setDictionary:result.books];

			[allBookNameTableView reloadData];
			[allBookmarkTableView reloadData];
		} else {
			NSBeep();
		}
	} else if (responder == allBookmarkTableView) {
		if ([allBookmarkTableView selectedRow] > -1) {
			[self deleteRow:theEvent];
		} else {
			NSBeep();
		}
	} else {
		NSBeep();
	}
}

#pragma mark -
- (IBAction)deleteRow:(id)sender;
{
	if ([bookmarkPanel isVisible]) {
		int selectedRow = (int)[bookmarkTableView selectedRow];
		if (0 <= selectedRow) {
			[bookmarkArray setArray:[ViewerBookmarkList bookmarksByRemovingBookmarks:bookmarkArray atIndex:selectedRow]];
			[bookmarkTableView reloadData];
		}
	} else {
		int selectedRow = (int)[allBookmarkTableView selectedRow];
		if (allBookmark && [allBookNameTableView selectedRow] > -1 && selectedRow > -1) {
			id dic = [allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
			NSMutableDictionary *cDic = [NSMutableDictionary dictionaryWithDictionary:dic];
			NSArray *array = [cDic objectForKey:@"bookmarks"];

			[cDic setObject:[ViewerBookmarkList bookmarksByRemovingBookmarks:array atIndex:selectedRow] forKey:@"bookmarks"];
			[allBookmark setObject:cDic forKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];

			[allBookmarkTableView reloadData];
		}
	}
}

-(IBAction)addNewBookmark:(id)sender
{
	if ([bookmarkPanel isVisible]) {
		NSArray<NSDictionary *> *updated = [ViewerBookmarkList appendingBookmarks:bookmarkArray page:[newBookmarkTextField intValue]];
		if (!updated) {
			NSBeep();
			return;
		}
		[bookmarkArray setArray:updated];
		[bookmarkTableView reloadData];
	} else {
		if (allBookmark && [allBookNameTableView selectedRow] > -1) {
			id dic = [allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
			NSMutableDictionary *cDic = [NSMutableDictionary dictionaryWithDictionary:dic];
			NSArray *array = [cDic objectForKey:@"bookmarks"];

			NSArray<NSDictionary *> *updated = [ViewerBookmarkList appendingBookmarks:array page:[newBookmarkTextField intValue]];
			if (!updated) {
				NSBeep();
				return;
			}
			[cDic setObject:updated forKey:@"bookmarks"];
			[allBookmark setObject:cDic forKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];

			[allBookmarkTableView reloadData];
		} else {
			NSBeep();
		}
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    if( [[anItem title] isEqualToString:NSLocalizedString(@"Delete this Bookmark", @"")] == YES){
		if ([bookmarkPanel isVisible]) {
			return [bookmarkTableView selectedRow] > -1;
		} else {
			return [allBookmarkTableView selectedRow] > -1;
		}
    }
	return NO;

}


- (IBAction)openInFinder:(id)sender
{
	if ([allBookNameTableView selectedRow] > -1) {
		NSData *alias = [[allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]] objectForKey:@"alias"];
		[[NSWorkspace sharedWorkspace] selectFile:[controller pathFromAliasData:alias]
						 inFileViewerRootedAtPath:@""];
	} else {
		NSBeep();
	}

}

- (IBAction)openInSelf:(id)sender
{
	if ([allBookNameTableView selectedRow] > -1) {
		NSDictionary *bookDic = [allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
		NSString *path = [controller pathFromAliasData:[bookDic objectForKey:@"alias"]];

		int selectedBookmarkRow = (int)[allBookmarkTableView selectedRow];
		if (selectedBookmarkRow > -1) {
			// Bookmark "page" values are the 1-based page shown to the user
			// (same convention -goBookmark: converts with "-1" when jumping
			// within the already-open book); -openPage:last: takes the
			// 0-based internal page number.
			int page = [[[[bookDic objectForKey:@"bookmarks"] objectAtIndex:selectedBookmarkRow] objectForKey:@"page"] intValue] - 1;
			[controller setCurrentBookPathAndOldBookPath:path];
			[controller openPage:page last:NO];
		} else {
			[controller application:NSApp openFile:path];
		}
		[allBookmarkPanel makeKeyAndOrderFront:self];
	} else {
		NSBeep();
	}

}

#pragma mark -
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == allBookNameTableView) {
		[allBookmarkTableView reloadData];
	}
}

#pragma mark Table Delegate

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (aTableView == allBookNameTableView) {
		//[self openInSelf:self];
		return YES;
	}
    return YES;
}


- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	return YES;
}

#pragma mark tableDataSource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == bookmarkTableView) {
		return (int)[bookmarkArray count];
	} else if (aTableView == allBookmarkTableView) {
		if (allBookmark && [allBookNameTableView selectedRow] > -1) {
			id dic = [allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
			
			//NSLog(@"%i,%i",[allBookNameTableView selectedRow],[[dic objectForKey:@"bookmarks"] count]);
			return (int)[[dic objectForKey:@"bookmarks"] count];
		} else {
			return 0;
		}
	} else if (aTableView == allBookNameTableView) {
		return (int)[bookNameArray count];
	}
	return 0;
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(int)rowIndex
{
	[[aTableColumn dataCell] setWraps:YES];
	static NSDictionary *info = nil;
	static NSDictionary *pageInfo = nil;
    if (nil == info) {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineBreakMode:NSLineBreakByTruncatingMiddle];
        info = [[NSDictionary alloc] initWithObjectsAndKeys:style, NSParagraphStyleAttributeName, nil];
        [style release];
    }
    if (nil == pageInfo) {
        NSMutableParagraphStyle *pageStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [pageStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [pageStyle setAlignment:NSTextAlignmentRight];
        pageInfo = [[NSDictionary alloc] initWithObjectsAndKeys:pageStyle, NSParagraphStyleAttributeName, nil];
        [pageStyle release];
    }
	
	if (aTableView == bookmarkTableView) {
		if([[aTableColumn identifier] isEqualToString:@"name"]) {
			if (bookmarkArray) {
				//return [[bookmarkArray objectAtIndex:rowIndex] objectForKey:@"name"];
				return [[[NSAttributedString alloc] initWithString:[[bookmarkArray objectAtIndex:rowIndex] objectForKey:@"name"]
														attributes:info] autorelease];
			} else {
				return nil;
			}
		} else if([[aTableColumn identifier] isEqualToString:@"page"]) {
			
			if (bookmarkArray) {
				//return [[bookmarkArray objectAtIndex:rowIndex] objectForKey:@"page"];
				return [[[NSAttributedString alloc] initWithString:[[bookmarkArray objectAtIndex:rowIndex] objectForKey:@"page"]
														attributes:pageInfo] autorelease];
			} else {
				return nil;
			}
		}
	} else if (aTableView == allBookmarkTableView) {
		if([[aTableColumn identifier] isEqualToString:@"name"]) {
			if (allBookmark && rowIndex > -1 && [allBookNameTableView selectedRow] > -1) {
				id dic = [allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
				//return [[[dic objectForKey:@"bookmarks"] objectAtIndex:rowIndex] objectForKey:@"name"];
				
				
				//NSLog(@"%i",rowIndex);
				//NSLog(@"%@",dic);
				if (rowIndex >= [[dic objectForKey:@"bookmarks"] count]) {
					return nil;
				}
				return [[[NSAttributedString alloc] initWithString:[[[dic objectForKey:@"bookmarks"] objectAtIndex:rowIndex] objectForKey:@"name"]
														attributes:info] autorelease];
			} else {
				return nil;
			}
		} else if([[aTableColumn identifier] isEqualToString:@"page"]) {
			
			if (allBookmark && rowIndex > -1 && [allBookNameTableView selectedRow] > -1) {
				id dic = [allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
				//return [[[dic objectForKey:@"bookmarks"] objectAtIndex:rowIndex] objectForKey:@"page"];
				
				if (rowIndex >= [[dic objectForKey:@"bookmarks"] count]) {
					return nil;
				}
				return [[[NSAttributedString alloc] initWithString:[[[dic objectForKey:@"bookmarks"] objectAtIndex:rowIndex] objectForKey:@"page"]
														attributes:pageInfo] autorelease];
			} else {
				return nil;
			}
		}		
	} else if (aTableView == allBookNameTableView) {
		if([[aTableColumn identifier] isEqualToString:@"folder"]) {
			if (bookNameArray) {
				//return [bookNameArray objectAtIndex:rowIndex];
				return [[[NSAttributedString alloc] initWithString:[bookNameArray objectAtIndex:rowIndex]
														attributes:info] autorelease];
			} else {
				return nil;
			}
		}	
//		return [booknameArray objectAtIndex:rowIndex];
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(int)rowIndex
{
	if (!anObject) {
		return;
	}
	if (aTableView == bookmarkTableView) {
		if (bookmarkArray) {
			if([[aTableColumn identifier] isEqualToString:@"name"]) {
				[bookmarkArray setArray:[ViewerBookmarkList bookmarksWithNameBookmarks:bookmarkArray atIndex:rowIndex updatedTo:anObject]];
			} else if([[aTableColumn identifier] isEqualToString:@"page"]) {
				[bookmarkArray setArray:[ViewerBookmarkList bookmarksWithPageBookmarks:bookmarkArray atIndex:rowIndex updatedTo:[NSString stringWithFormat:@"%@",anObject]]];
			}
		}
	} else if (aTableView == allBookmarkTableView) {
		id dic = [allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
		NSMutableDictionary *cDic = [NSMutableDictionary dictionaryWithDictionary:dic];
		NSArray *array = [cDic objectForKey:@"bookmarks"];

		if([[aTableColumn identifier] isEqualToString:@"name"]) {
			[cDic setObject:[ViewerBookmarkList bookmarksWithNameBookmarks:array atIndex:rowIndex updatedTo:anObject] forKey:@"bookmarks"];
			[allBookmark setObject:cDic forKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
		} else if([[aTableColumn identifier] isEqualToString:@"page"]) {
			[cDic setObject:[ViewerBookmarkList bookmarksWithPageBookmarks:array atIndex:rowIndex updatedTo:[NSString stringWithFormat:@"%@",anObject]] forKey:@"bookmarks"];
			[allBookmark setObject:cDic forKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
		}
	} else if (aTableView == allBookNameTableView) {
		if([[aTableColumn identifier] isEqualToString:@"folder"]) {
			ViewerBookmarkBookListResult *result = [ViewerBookmarkBookList renamingBookNames:bookNameArray books:allBookmark atIndex:rowIndex to:anObject];
			if (!result) {
				NSBeep();
				return;
			}
			[bookNameArray setArray:result.names];
			[allBookmark setDictionary:result.books];
		}
	}
}


#pragma mark tableDataSource_drag&drop

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    if (tv == allBookmarkTableView || tv == bookmarkTableView) {
        NSMutableArray *rows=[NSMutableArray array];
            [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [rows addObject:[NSNumber numberWithInteger:idx]];
            }];
        
        [pboard declareTypes:[NSArray arrayWithObject:@"row"] owner:self];
        [pboard setPropertyList:rows forType:@"row"];
        return YES;
    }
    return NO;
}

-(NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
	NSPasteboard *pboard=[info draggingPasteboard];
	
	if (op == NSTableViewDropAbove && [pboard availableTypeFromArray:[NSArray arrayWithObject:@"row"]] != nil) {
		return NSDragOperationGeneric;
	} else {
		return NSDragOperationNone;
	}
}
#pragma mark -
// Splices the rows named in pboard's "row" property list out of array and reinserts them
// starting at row, then reflects the new order in tv's selection. Shared by both drag-drop
// destinations below, which differ only in where their backing array lives.
-(BOOL)co_reorderArray:(NSMutableArray*)array toRow:(int)row dropOperation:(NSTableViewDropOperation)op pasteboard:(NSPasteboard*)pboard tableView:(NSTableView*)tv
{
	if (op != NSTableViewDropAbove || [pboard availableTypeFromArray:[NSArray arrayWithObject:@"row"]] == nil) {
		return NO;
	}

	NSArray<NSNumber *> *draggedIndices = [pboard propertyListForType:@"row"];
	ViewerBookmarkMoveResult *result = [ViewerBookmarkList bookmarksByMovingBookmarks:array atIndices:draggedIndices toRow:row];
	[array setArray:result.bookmarks];

	[tv reloadData];
	[tv deselectAll:nil];

	NSUInteger i;
	for (i = result.selectedRange.location; i < NSMaxRange(result.selectedRange); i++) {
		[tv selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:[tv allowsMultipleSelection]];
	}

	return YES;
}

-(BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
	NSPasteboard *pboard=[info draggingPasteboard];

	if (tv == bookmarkTableView) {
		if (!bookmarkArray) {
			return NO;
		}
		return [self co_reorderArray:bookmarkArray toRow:row dropOperation:op pasteboard:pboard tableView:tv];
	} else if (tv == allBookmarkTableView) {
		id dic = [allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
		NSMutableDictionary *cDic = [NSMutableDictionary dictionaryWithDictionary:dic];
		id array = [cDic objectForKey:@"bookmarks"];
		NSMutableArray *newArray = [NSMutableArray arrayWithArray:array];

		// Wire newArray into the backing store *before* reordering it: allBookmarkTableView's
		// data source reads straight from allBookmark/cDic, and -co_reorderArray:...  reloads
		// tv as part of the splice, so the backing store has to already hold this same array
		// object by the time that reload happens. removeAllObjects/addObjectsFromArray: below
		// mutate newArray in place, so cDic/allBookmark automatically pick up the new order -
		// no need to write them again afterward.
		[cDic setObject:newArray forKey:@"bookmarks"];
		[allBookmark setObject:cDic forKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];

		return [self co_reorderArray:newArray toRow:row dropOperation:op pasteboard:pboard tableView:tv];
	}
	return NO;
}
@end
