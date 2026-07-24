#import "BookmarkController.h"
#import "cooViewer-Swift.h"

@implementation BookmarkController

//const int ITEM_DELETE = 1;
static const int DIALOG_OK		= 128;
static const int DIALOG_CANCEL	= 129;

// -removingBookmarks:atIndices: (Swift) takes the same NSArray<NSNumber*>
// shape -selectedRowIndexes already needs converting to for any multi-row
// operation.
static NSArray<NSNumber *> *co_numbersFromIndexSet(NSIndexSet *indexSet)
{
	NSMutableArray<NSNumber *> *numbers = [NSMutableArray arrayWithCapacity:[indexSet count]];
	[indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[numbers addObject:@(idx)];
	}];
	return numbers;
}


-(void)awakeFromNib
{
	NSArray *tableRowTypes = [NSArray arrayWithObject:@"row"];
	[allBookmarkTableView registerForDraggedTypes:tableRowTypes];

	defaults = [NSUserDefaults standardUserDefaults];

	[allBookmarkPanel setFrameAutosaveName:@"AllBookmark"];
	if ([defaults stringForKey:@"AllBookmarkSplitPotision"]) {
		[self setSplitViewPosition:allBookmarkSplitView position:[defaults stringForKey:@"AllBookmarkSplitPotision"]];
	}
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


- (IBAction)ok:(id)sender;
{
	[[NSApplication sharedApplication] stopModalWithCode:DIALOG_OK];
}


- (IBAction)cancel:(id)sender;
{
	[[NSApplication sharedApplication] stopModalWithCode:DIALOG_CANCEL];
}

#pragma mark editAllBookmark
-(void)editAllBookmark:(NSString*)currentBookPath
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
	// allBookNameTableView is a long-lived instance shared across every open
	// of this screen -- without an explicit deselect, whichever book was
	// selected last time stays selected (misleadingly, since none of the
	// action buttons below reflect that: they're always reset to disabled),
	// so always start from a clean "nothing selected" state.
	[allBookNameTableView deselectAll:nil];
	[allBookmarkTableView deselectAll:nil];
	[deleteAllBookmarkButton setEnabled:NO];
	[addAllBookmarkButton setEnabled:NO];
	[openInSelfButton setEnabled:NO];

	if (currentBookPath) {
		// Pre-select the book that's actually open so its bookmarks show
		// immediately, instead of leaving the user to find it themselves in
		// a (possibly long) name list -- see -tableViewSelectionDidChange:
		// for how this drives the rest of the initial button/table state.
		NSString *key = nil;
		[controller searchFromBookSettings:currentBookPath key:&key];
		if (key) {
			NSUInteger row = [bookNameArray indexOfObject:key];
			if (row != NSNotFound) {
				[allBookNameTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
				[allBookNameTableView scrollRowToVisible:row];
			}
		}
	}

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
	// Delete only ever removes a bookmark here -- deleting a whole book is a
	// separate, more deliberate action reachable only via the "Unregister..."
	// context menu on allBookNameTableView (see -deleteBookRow:), never via
	// this key/button.
	if ([allBookmarkTableView selectedRow] > -1) {
		[self deleteRow:theEvent];
	} else {
		NSBeep();
	}
}

- (IBAction)deleteBookRow:(id)sender
{
	int selectedRow = (int)[allBookNameTableView selectedRow];
	if (selectedRow == -1) {
		NSBeep();
		return;
	}

	int result = (int)NSRunAlertPanel(NSLocalizedString(@"Unregister Book", @""),
									   NSLocalizedString(@"Unregistering will delete all of its bookmarks.", @""),
									   NSLocalizedString(@"Cancel", @""),
									   NSLocalizedString(@"Unregister", @""),
									   nil);
	if (result != NSAlertAlternateReturn && result != NSAlertSecondButtonReturn) {
		return;
	}

	ViewerBookmarkBookListResult *bookListResult = [ViewerBookmarkBookList removingBookNames:bookNameArray books:allBookmark atIndex:selectedRow];
	[bookNameArray setArray:bookListResult.names];
	[allBookmark setDictionary:bookListResult.books];

	[allBookNameTableView reloadData];
	[allBookmarkTableView reloadData];
}

#pragma mark -
- (IBAction)deleteRow:(id)sender;
{
	NSIndexSet *selectedRows = [allBookmarkTableView selectedRowIndexes];
	if (allBookmark && [allBookNameTableView selectedRow] > -1 && [selectedRows count] > 0) {
		id dic = [allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
		NSMutableDictionary *cDic = [NSMutableDictionary dictionaryWithDictionary:dic];
		NSArray *array = [cDic objectForKey:@"bookmarks"];

		[cDic setObject:[ViewerBookmarkList bookmarksByRemovingBookmarks:array atIndices:co_numbersFromIndexSet(selectedRows)] forKey:@"bookmarks"];
		[allBookmark setObject:cDic forKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];

		[allBookmarkTableView reloadData];
	}
}

// New bookmarks no longer take a manually-entered page number up front --
// they start at this placeholder and the newly added row is immediately put
// into edit mode on its Page cell (see -co_beginEditingPageAtRow:tableView:),
// so the user types the real page directly into the list rather than a
// separate text field.
static const int kNewBookmarkPlaceholderPage = 1;

-(IBAction)addNewBookmark:(id)sender
{
	if (allBookmark && [allBookNameTableView selectedRow] > -1) {
		id dic = [allBookmark objectForKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];
		NSMutableDictionary *cDic = [NSMutableDictionary dictionaryWithDictionary:dic];
		NSArray *array = [cDic objectForKey:@"bookmarks"];

		NSArray<NSDictionary *> *updated = [ViewerBookmarkList appendingBookmarks:array page:kNewBookmarkPlaceholderPage];
		if (!updated) {
			NSBeep();
			return;
		}
		[cDic setObject:updated forKey:@"bookmarks"];
		[allBookmark setObject:cDic forKey:[bookNameArray objectAtIndex:[allBookNameTableView selectedRow]]];

		[self co_beginEditingPageAtRow:(int)[updated count] - 1 tableView:allBookmarkTableView];
	} else {
		NSBeep();
	}
}

// Selects the newly added row and puts its Page cell straight into edit
// mode, so the user types the real page directly rather than needing a
// separate "add" step followed by a second edit step.
-(void)co_beginEditingPageAtRow:(int)row tableView:(NSTableView *)tableView
{
	[tableView reloadData];

	NSInteger column = [tableView columnWithIdentifier:@"page"];
	if (column == -1) {
		return;
	}
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[tableView editColumn:column row:row withEvent:nil select:YES];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    if( [[anItem title] isEqualToString:NSLocalizedString(@"Delete this Bookmark", @"")] == YES){
		return [allBookmarkTableView selectedRow] > -1;
    } else if ([[anItem title] isEqualToString:NSLocalizedString(@"Unregister...", @"")] == YES) {
		return [allBookNameTableView selectedRow] > -1;
	} else if ([[anItem title] isEqualToString:NSLocalizedString(@"Show in Finder", @"")] == YES) {
		return [allBookNameTableView selectedRow] > -1;
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
	NSTableView *table = [aNotification object];
	if (table == allBookNameTableView) {
		[allBookmarkTableView deselectAll:nil];
		[allBookmarkTableView reloadData];

		BOOL bookSelected = ([allBookNameTableView selectedRow] > -1);
		[addAllBookmarkButton setEnabled:bookSelected];
		[openInSelfButton setEnabled:bookSelected];
	}

	if (table == allBookmarkTableView || table == allBookNameTableView) {
		BOOL bookmarkSelected = ([allBookmarkTableView selectedRow] > -1);
		[deleteAllBookmarkButton setEnabled:bookmarkSelected];
		// -openInSelf: jumps straight to the selected bookmark's page instead
		// of just opening the book when one is selected -- reflect that
		// distinction in the button's own label rather than overloading "Open".
		[openInSelfButton setTitle:bookmarkSelected ? NSLocalizedString(@"Move to Bookmark", @"") : NSLocalizedString(@"Open", @"")];
	}
}

#pragma mark Table Delegate

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (aTableView == allBookNameTableView) {
		// A book's name here is just this dictionary's lookup key, not the
		// underlying file's name -- renaming it from the bookmark editor is
		// a mismatched concern for this screen, so editing is disallowed.
		return NO;
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
	if (aTableView == allBookmarkTableView) {
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
    if (nil == info) {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineBreakMode:NSLineBreakByTruncatingMiddle];
        info = [[NSDictionary alloc] initWithObjectsAndKeys:style, NSParagraphStyleAttributeName, nil];
        [style release];
    }
	// The "page" column's cell has its own numberFormatter and right alignment
	// declared in MainMenu.xib -- wrapping its value in a custom NSAttributedString
	// (as the other columns do for line-break/alignment styling) fights that
	// formatter and renders the value permanently dimmed, no matter what color is
	// stated explicitly. Returning the plain string lets the cell's own formatter
	// and declared textColor render it normally.

	if (aTableView == allBookmarkTableView) {
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
				return [[[dic objectForKey:@"bookmarks"] objectAtIndex:rowIndex] objectForKey:@"page"];
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
	if (aTableView == allBookmarkTableView) {
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
	}
	// allBookNameTableView's "folder" column is not editable (see
	// -tableView:shouldEditTableColumn:row:), so it never reaches here.
}


#pragma mark tableDataSource_drag&drop

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    if (tv == allBookmarkTableView) {
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

	if (tv == allBookmarkTableView) {
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
