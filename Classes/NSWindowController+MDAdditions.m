//
//  NSWindowController+MDAdditions.m
//  TextMateDBGp
//
//	Copyright (c) The MissingDrawer authors.
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

#import "NSWindowController+MDAdditions.h"

#import "TextMateDBGp.h"
#import "TDBookmarksView.h"
#import "TDProject.h"
#import "TDProjectNavigatorView.h"
#import "TDSidebar.h"
#import "TDSplitView.h"

@implementation TDTemporaryOwner
- (void)dealloc {
  [sidebar release];
  [super dealloc];
}
@end

@implementation NSWindowController (MDAdditions)

- (void)MD_splitWindowIfNeeded {
	NSWindow *window = [self window];
	if (!window)
    return;
  
  NSView *contentView = [window contentView];  
  if (!contentView || [contentView isKindOfClass:[TDSplitView class]])
    return;
  
  // If a drawer is displayed by TextMate, replace the contentView
  // with one that uses the MissingDrawer.
  NSDrawer *drawer = [[window drawers] objectAtIndex:0];
  if (!drawer)
    return;
  
  NSView *drawerView = [[drawer contentView] retain];
  [contentView retain];
  [drawer setContentView:nil];
  [window setContentView:nil];
  
  TDTemporaryOwner* owner = [[TDTemporaryOwner alloc] init];
  [NSBundle loadNibNamed:@"TDSidebar" owner:owner];
  [owner->sidebar.navigatorView initializeWithDrawer:drawerView];
  
  TDSplitView *splitView = [TextMateDBGp makeSplitViewWithMainView:contentView sideView:owner->sidebar];
  
  [window setContentView:splitView];
  
  [drawerView release];
  [contentView release];
  [splitView restoreLayout];
  
  [owner->sidebar selectView:0];
  [owner release];
  
  [drawer close]; // does no harm if the drawer is already closed
}

- (void)MD_windowDidBecomeMain:(NSNotification *)notification {
	NSDictionary *bindingOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  NSUnarchiveFromDataTransformerName, @"NSValueTransformerName", nil];
	NSString *keyPath = [[NSString alloc] initWithFormat:@"values.%@", kMDSidebarBackgroundColorActiveKey];
	
  
	TDSidebar *sidebar = [(TDSplitView *)[[(NSWindowController *)self window] contentView] sidebar];
  NSOutlineView* navigationOutlineView = sidebar.navigatorView.outlineView;  
  NSOutlineView* bookmarkOutlineView = sidebar.bookmarksView.outlineView;
  
	[navigationOutlineView bind:@"backgroundColor"
                     toObject:[NSUserDefaultsController sharedUserDefaultsController]
                  withKeyPath:keyPath
                      options:bindingOptions];
  [bookmarkOutlineView bind:@"backgroundColor"
                   toObject:[NSUserDefaultsController sharedUserDefaultsController]
                withKeyPath:keyPath
                    options:bindingOptions];
  [sidebar.debugView bind:@"backgroundColor"
                 toObject:[NSUserDefaultsController sharedUserDefaultsController]
              withKeyPath:keyPath
                  options:bindingOptions];
	
	[bindingOptions release];
	[keyPath release];
  
  [bookmarkOutlineView beginUpdates];
  [sidebar.project gatherBookmarks];
  [bookmarkOutlineView endUpdates];
  [bookmarkOutlineView reloadData];
  [bookmarkOutlineView expandItem:nil expandChildren:YES];
}


- (void)MD_windowDidResignMain:(NSNotification *)notification {
	NSDictionary *bindingOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  NSUnarchiveFromDataTransformerName, @"NSValueTransformerName", nil];
	NSString *keyPath = [[NSString alloc] initWithFormat:@"values.%@", kMDSidebarBackgroundColorIdleKey];
	
	TDSidebar *sidebar = [(TDSplitView *)[[(NSWindowController *)self window] contentView] sidebar];
  NSOutlineView* navigationOutlineView = sidebar.navigatorView.outlineView;  
	[navigationOutlineView bind:@"backgroundColor"
                     toObject:[NSUserDefaultsController sharedUserDefaultsController]
                  withKeyPath:keyPath
                      options:bindingOptions];
  [sidebar.bookmarksView.outlineView bind:@"backgroundColor"
                                 toObject:[NSUserDefaultsController sharedUserDefaultsController]
                              withKeyPath:keyPath
                                  options:bindingOptions];
  [sidebar.debugView bind:@"backgroundColor"
                 toObject:[NSUserDefaultsController sharedUserDefaultsController]
              withKeyPath:keyPath
                  options:bindingOptions];
	
	[bindingOptions release];
	[keyPath release];
}

@end

