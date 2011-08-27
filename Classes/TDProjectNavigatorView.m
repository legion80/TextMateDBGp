//
//  TDProjectNavigatorView.m
//  TextMateDBGp
//
//	Copyright (c) Jon Lee.
//
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
//

#import "TDProjectNavigatorView.h"

#import "JRSwizzle.h"
#import "TextMateDBGp.h"
#import "TDOutlineViewDataSource.h"
#import "TDProject.h"
#import "TDSearchField.h"
#import "TDSidebar.h"

NSComparisonResult compareFrameOriginX(id viewA, id viewB, void *context) {
  float v1 = [viewA frame].origin.x;
  float v2 = [viewB frame].origin.x;
  
	if (v1 < v2) {
    return NSOrderedAscending;
	} else if (v1 > v2) {
    return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

@interface NSOutlineView (TDOakOutlineViewMethodReplacements)
- (void)TD_reloadItem:(id)item reloadChildren:(BOOL)reloadChildren;
@end

@implementation NSOutlineView (TDOakOutlineViewMethodReplacements)
// This method gets called whenever the root directory or its descendants have changed.
// Only root directories that have changed will be reloaded.
// It looks like it only gets called when:
//    The application becomes the main application
//    The user alters a file
- (void)TD_reloadItem:(id)item reloadChildren:(BOOL)reloadChildren {
  // Reload the root directory as intended originally. We will get a fresh copy
  // of the filtered list from this.
  [self TD_reloadItem:item reloadChildren:reloadChildren];
  
  // if item is nil, we called this method ourselves so don't recalculate.
  // if the item is a file, then the user is editing and we get out.
  if (item == nil || [item objectForKey:@"children"] == nil)
    return;
  
  if ([self.dataSource isMemberOfClass:[TDOutlineViewDataSource class]]) {
    MDLog(@"Recalculating filtered tree for item %@", [item objectForKey:@"sourceDirectory"]);
    TDProjectNavigatorView* navigatorView = (TDProjectNavigatorView*)[[[self superview] superview] superview];
    [navigatorView recalculateTree];
  }
}
@end

// ####################################################################

@interface TDProjectNavigatorView (PrivateMethods)
- (void)focusSearchField;
- (NSString*)selectedFilePath;
@end;

@implementation TDProjectNavigatorView
@synthesize toolbar;
@synthesize contentView;
@synthesize outlineView = _outlineView;
@synthesize filterQueue = _filterQueue;
@synthesize project = _project;
@synthesize sidebar = _sidebar;

+ (void)load {
  [OakOutlineView jr_swizzleMethod:@selector(reloadItem:reloadChildren:) withMethod:@selector(TD_reloadItem:reloadChildren:) error:NULL];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  dispatch_release(_filterQueue);
  [_fullOutlineViewExpandedItems release];
  
  [_toolbarButtons release];
  [_searchField release];
  [_outlineViewDataSource release];
  [_outlineScrollContainer release];
  [_outlineView release];
  [_project release];
  [super dealloc];
}

- (void)initializeWithDrawer:(NSView *)drawerView {
  // Gather buttons
  _toolbarButtons = [[NSMutableArray alloc] init];
  NSArray *subviews = [drawerView subviews];
  int count = [subviews count];
  for (int i = 0; i < count; i++) {
    id aView = [subviews objectAtIndex:i];
    if ([aView isKindOfClass:[NSButton class]] && [aView frame].origin.y < 1) {
      [_toolbarButtons addObject:aView];
    }
    else if ([aView isKindOfClass:[NSScrollView class]]) {
      _outlineScrollContainer = [aView retain];
      _outlineView = [[[_outlineScrollContainer contentView] documentView] retain];
    }
  }
  [_toolbarButtons sortUsingFunction:(NSInteger (*)(id, id, void *))compareFrameOriginX context:nil];
  
  // Add buttons to toolbar
  NSRect tmButtonFrame = [[_toolbarButtons lastObject] frame];
  NSRect buttonFrame = NSMakeRect(tmButtonFrame.origin.x + tmButtonFrame.size.width, tmButtonFrame.origin.y,
                                  23.0f, tmButtonFrame.size.height);
  NSButton *terminalButton = [[NSButton alloc] initWithFrame:buttonFrame];
  [_toolbarButtons addObject:terminalButton];
  
  NSImage *buttonImage = [TextMateDBGp bundledImageWithName:@"ButtonTerminal"];
  NSImage *buttonImagePressed = [TextMateDBGp bundledImageWithName:@"ButtonTerminalPressed"]; 
  
  [terminalButton setToolTip:@"Open Terminal window and 'cd' to selected file/folder"];
  [terminalButton setImage:buttonImage];
  [terminalButton setAlternateImage:buttonImagePressed];
  [terminalButton setAction:@selector(terminalButtonPressed:)];
  [terminalButton setTarget:self];
  
  [terminalButton setBordered:NO];
  [terminalButton release];
  
  float leftLoc = 0;
  for (NSView *button in _toolbarButtons) {
		NSRect buttonFrame = [button frame];
		buttonFrame.origin.y = 0;
		buttonFrame.origin.x = leftLoc;
		leftLoc = leftLoc + (buttonFrame.size.width-1);
    button.frame = buttonFrame;
		[button setAutoresizingMask:NSViewMaxXMargin];
		[button removeFromSuperview];
		[toolbar addSubview:button];
  }
  
  // Add search field
  _searchField = [[TDSearchField alloc] initWithFrame:NSMakeRect(leftLoc + SEARCH_FIELD_LEFT_PADDING, 1, 10, 10)];
  NSSearchFieldCell* cell = [_searchField cell];
  [cell setMaximumRecents:0];
  [cell setFont:[NSFont controlContentFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
  [cell setControlSize:NSMiniControlSize];
  [cell setFocusRingType:NSFocusRingTypeNone];
  [cell setScrollable:YES];
  [[cell searchButtonCell] setImage:[TextMateDBGp bundledImageWithName:@"FilterIcon"]];
  
  [_searchField setAutoresizingMask:NSViewWidthSizable];
  [_searchField sizeToFit];
  NSRect frame = _searchField.frame;
  frame.size.width = toolbar.frame.size.width - leftLoc - SEARCH_FIELD_LEFT_PADDING - SEARCH_FIELD_RIGHT_PADDING;
  _searchField.frame = frame;
  [toolbar addSubview:_searchField];
  
  
  // Move the outline out
  [_outlineScrollContainer removeFromSuperview];
  _outlineScrollContainer.borderType = NSNoBorder;
  _outlineScrollContainer.frame = contentView.bounds;
  _outlineScrollContainer.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  [contentView addSubview:_outlineScrollContainer];
  
  NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:12];
  NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init]; 
  [_outlineView setRowHeight:[layoutManager defaultLineHeightForFont:font]];
  [_outlineView setIntercellSpacing:NSMakeSize (4.0, 2.0)];
  _project.originalOutlineView = _outlineView;
  [layoutManager release];
  
  // Swap the original data source with ours
  _outlineViewDataSource = [[TDOutlineViewDataSource alloc] initWithOriginalDataSource:_outlineView.dataSource];
  _outlineView.dataSource = _outlineViewDataSource;
  
  _fullOutlineViewExpandedItems = [[NSMutableArray alloc] init];
  _filterQueue = dispatch_queue_create("com.github.legion80.TextMateDBGp", NULL);
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusSearchField) name:@"MDFilterInDrawerNotification" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterOutlineView:) name:NSControlTextDidChangeNotification object:_searchField];
}

#pragma mark Actions
- (void)terminalButtonPressed:(id)sender {
	NSString *path = [self selectedFilePath];
	if (!path) {
		return;
	}
	
	path = [path stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\\\\\""];
  NSString* appleScriptCommand = [NSString stringWithFormat:@"activate application \"Terminal\"\n\ttell application \"System Events\"\n\tkeystroke \"t\" using {command down}\n\tend tell\n\ttell application \"Terminal\"\n\trepeat with win in windows\n\ttry\n\tif get frontmost of win is true then\n\tdo script \"cd \\\"%@\\\"; clear\" in (selected tab of win)\n\tend if\n\tend try\n\tend repeat\n\tend tell", path];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource: appleScriptCommand];
	[as executeAndReturnError:nil];
	[as release];
	return;
}


- (NSString *)selectedFilePath {
	NSArray *selectedItems = nil;
	if (_outlineView && 
      [_outlineView respondsToSelector:@selector(selectedItems)]) {
		selectedItems = [_outlineView performSelector:@selector(selectedItems)];
		if (!selectedItems || ![selectedItems isKindOfClass:[NSArray class]] || [selectedItems count] == 0) {
			selectedItems = [NSArray arrayWithObject:[_outlineView itemAtRow:0]];
		}
	}
	
	for (NSDictionary *item in selectedItems) {
		NSString *path = [item objectForKey:@"sourceDirectory"];
		if (!path) {
			path = [[item objectForKey:@"filename"] stringByDeletingLastPathComponent];
		}
		
		if (path) {
			return path;
		}
	}
	
	return nil;
}

- (void)focusSearchField {
  if ([_sidebar selectedView] != 0)
    [_sidebar selectView:0];
  
  if ([_searchField acceptsFirstResponder])
    [_searchField becomeFirstResponder];
}

#pragma mark Outline view filtering
- (void)filterOutlineView:(NSNotification *)notification {
  NSSearchField* searchField = [notification object];
  
  NSString* desiredFilter = [searchField stringValue];
  // We are about to switch from an unfiltered to filtered tree.
  // Go through the rows of the outline view and keep track of
  // the items that have been expanded.
  if (_outlineViewDataSource.currentFilter == nil || [_outlineViewDataSource.currentFilter isEqualToString:[NSString string]]) {
    [_fullOutlineViewExpandedItems removeAllObjects];
    int numRows = [_outlineView numberOfRows];
    for (int i = 0; i < numRows; ++i) {
      id item = [_outlineView itemAtRow:i];
      if ([_outlineView isItemExpanded:item]) {
        [_fullOutlineViewExpandedItems addObject:item];
      }
    }
  }
  
  dispatch_async(_filterQueue, ^() {
    // If the project has a particularly extensive directory structure,
    // the user might have typed a few characters while the queue
    // was processing one of the events. We do a sanity check against
    // the string currently entered in the search field. If it's not
    // the same, we can throw away this one, since we can assume that
    // eventually we will get a queue task that does have the right
    // desired filter string. This essentially coalesces the filter
    // events.
    if (![[searchField stringValue] isEqualToString:desiredFilter])
      return;
    
    _outlineViewDataSource.currentFilter = desiredFilter;
    [_outlineViewDataSource recalculateTreeFilter];
    
    dispatch_async(dispatch_get_main_queue(), ^() {
      [_outlineView reloadItem:nil reloadChildren:YES];
      BOOL enableToolButtons = YES;
      if (![desiredFilter isEqualToString:[NSString string]]) {
        [_outlineView expandItem:nil expandChildren:YES];
        enableToolButtons = NO;
      }
      else {
        // We switched from a filtered to an unfiltered tree. We
        // restore the expanded state of the items.
        for (id item in _fullOutlineViewExpandedItems) {
          [_outlineView expandItem:item];
        }
      }
      
      // disable/enable the "Add file", "Add folder", and "Settings" buttons
      for (int i = 0; i < 3; ++i) {
        [[_toolbarButtons objectAtIndex:i] setEnabled:enableToolButtons];
      }
    });
  });
}

- (void)recalculateTree {
  // FIXME: this is inefficient because it recalculates the filtered outline for all
  // root directories, not just the one that has changed. Also, if multiple root
  // directories have changed, we will recalculate the filter tree for all of the root
  // directories multiple times.
  dispatch_async(_filterQueue, ^() {
    [_outlineViewDataSource recalculateTreeFilter];
    dispatch_async(dispatch_get_main_queue(), ^() {
      if (![_outlineViewDataSource.currentFilter isEqualToString:[NSString string]]) {
        [_outlineView reloadItem:nil reloadChildren:YES];
        [_outlineView expandItem:nil expandChildren:YES];
      }
      // If the filter is empty we should just leave it alone.
    });
  });
}
@end
