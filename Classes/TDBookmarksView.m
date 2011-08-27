//
//  TDBookmarksView.m
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

#import "TDBookmarksView.h"

#import "JRSwizzle.h"
#import "TDBookmark.h"
#import "TDBookmarkFileCellView.h"
#import "TDDebugSession.h"
#import "TDNetworkController.h"
#import "TDOutlineViewDataSource.h"
#import "TDProject.h"
#import "TDSidebar.h"
#import "TDSplitView.h"

@interface NSView (TDBookmarks)
- (void)TD_toggleCurrentBookmark:(id)a;
- (void)TD_mouseDown:(id)a;
@end

@implementation NSView (TDBookmarks)
- (void)TD_toggleCurrentBookmark:(id)menuItem {
  [self TD_toggleCurrentBookmark:menuItem];
  
  TDSplitView* splitView = [[self window] contentView];
  [splitView.sidebar.bookmarksView refreshBookmarks:nil];
}

- (void)TD_mouseDown:(NSEvent*)event {
  [self TD_mouseDown:event];
  if (![self isMemberOfClass:OakTextView])
    return;
  
  NSPoint pt = [[self valueForKey:@"mouseDownPoint"] pointValue];
  float bookmarksOffset = [[self valueForKey:@"bookmarksOffset"] floatValue];
  float lineNumbersOffset = [[self valueForKey:@"lineNumbersOffset"] floatValue];
  // [OakTextView stringAttributes] is about the text view itself
  // [OakTextView metaData] holds the caret position and first visible column and line.
  
  // line numbers offset seems to be off by 1 pixel. line number offset is 13. click at 12 does not change bookmark.
  if (bookmarksOffset <= pt.x && pt.x < lineNumbersOffset - 1) {
    TDSplitView* splitView = [[self window] contentView];
    [splitView.sidebar.bookmarksView refreshBookmarks:nil];
  }
}
@end

/*******************/
@implementation TDBookmarksView
@synthesize outlineView = _outlineView;
@synthesize project = _project;

+ (void)load {
  [OakTextView jr_swizzleMethod:@selector(toggleCurrentBookmark:) withMethod:@selector(TD_toggleCurrentBookmark:) error:NULL];
  [OakTextView jr_swizzleMethod:@selector(mouseDown:) withMethod:@selector(TD_mouseDown:) error:NULL];
}

- (void)dealloc {
  self.outlineView = nil;
  self.project = nil;
  [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
  [[_outlineView backgroundColor] setFill];
  NSRectFill(dirtyRect);
}

- (void)refreshBookmarks:(id)sender {
  // toggled bookmark
  NSWindowController* oakProjectController = [_project projectController];
  NSView* tabbarView = [oakProjectController valueForKey:@"tabBarView"];
  NSView* oakTextView = [oakProjectController valueForKey:@"textView"];
  NSString* filename = [[oakProjectController valueForKey:@"currentDocument"] objectForKey:@"filename"];
  
  // Move the caret to the center of the view, so that when we close/reopen the file it's in the same approximate location
  [oakTextView performSelector:@selector(centerCaretInDisplay:) withObject:self];
  // Close the tab to save the bookmark
  [tabbarView performSelector:@selector(closeSelectedTab)];
  [_outlineView beginUpdates];
  NSArray* operations = [_project gatherBookmarks];
  [_outlineView endUpdates];
  [_outlineView reloadData];
  [_outlineView expandItem:nil expandChildren:YES];
  // Reopen it
  [_project openFile:filename atLineNumber:-1];
  
  TDNetworkController* nc = [_project networkController];
  if ([nc currentOpenSession]) {
    for (NSDictionary* op in operations) {
      TDBookmark* bookmark = [op objectForKey:@"bookmark"];
      if ([[op objectForKey:@"op"] isEqualToString:@"add"])
        [[nc currentOpenSession] addBookmark:bookmark];
      else //@"remove"
        [[nc currentOpenSession] removeBookmark:bookmark];
    }
  }
}

#pragma mark NSOutlineViewDataSource protocol
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (!item)
    return [_project.bookmarkKeys objectAtIndex:index];
  
  if ([item isMemberOfClass:[TDBookmark class]])
    return nil;
  
  return [[_project bookmarksForFileItem:item] objectAtIndex:index];
}
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (!item)
    return [_project.bookmarkKeys count];
  
  if (![item isMemberOfClass:[TDBookmark class]])
    return [[_project bookmarksForFileItem:item] count];
  return 0;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return ![item isMemberOfClass:[TDBookmark class]];
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if ([item isMemberOfClass:[TDBookmark class]])
    return item;
  
  return [item objectForKey:@"filename"];
}
- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
  if ([item isMemberOfClass:[TDBookmark class]])
    return 17;
  return 31;
}

/*
 - (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
 if ([item objectForKey:@"filename"])
 return [tableColumn dataCell];
 static TDBookmarkCell* s_bookmarkCell = nil;
 if (!s_bookmarkCell) {
 s_bookmarkCell = [[TDBookmarkCell alloc] initTextCell:@"a"];
 }
 return s_bookmarkCell;
 }*/
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
  id item = [_outlineView itemAtRow:[_outlineView selectedRow]];
  if ([item isMemberOfClass:[TDBookmark class]]) {
    TDBookmark* bookmark = item;
    [_project openFile:bookmark.source atLineNumber:bookmark.lineNumber + 1];
    return;
  }
  
  [_project openFile:item atLineNumber:0];
}

#pragma mark NSOutlineViewDelegate
- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  if ([item isMemberOfClass:[TDBookmark class]]) {
    NSTableCellView* cell = [outlineView makeViewWithIdentifier:@"BookmarkCell" owner:self];
    cell.textField.stringValue = [NSString stringWithFormat:@"line %d", [(TDBookmark*)item lineNumber] + 1];
    return cell;
  }
  
  TDBookmarkFileCellView* cellView = [outlineView makeViewWithIdentifier:@"FileCell" owner:self];
  NSString* filename = [item objectForKey:@"filename"];
  cellView.textField.stringValue = [filename lastPathComponent];
  cellView.folderTextField.stringValue = [filename stringByDeletingLastPathComponent];
  return cellView;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
  return ![item isMemberOfClass:[TDBookmark class]];
}
@end
