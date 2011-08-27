//
//  TDSidebar.m
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

#import "TDSidebar.h"

#import "TDBookmarksView.h"
#import "TDDebugView.h"
#import "TDNetworkController.h"
#import "TDProject.h"
#import "TDProjectNavigatorView.h"

@implementation TDSidebar
@synthesize project = _project;
@synthesize toolbar;
@synthesize contentView;
@synthesize navigatorView = _navigatorView;
@synthesize debugView = _debugView;
@synthesize bookmarksView = _bookmarksView;

- (id)initWithFrame:(NSRect)frameRect {
  if (!(self = [super initWithFrame:frameRect]))
    return nil;
  _project = [[TDProject alloc] init];
  return self;
}

- (void)awakeFromNib {
  /*
  */
}

- (void)dealloc {
  self.navigatorView = nil;
  self.debugView = nil;
  self.bookmarksView = nil;
  [_project release];
  [super dealloc];
}

- (TDProjectNavigatorView *)navigatorView {
  if (_navigatorView)
    return _navigatorView;
  
  [NSBundle loadNibNamed:@"TDProjectNavigatorView" owner:self];
  _navigatorView.project = _project;
  _navigatorView.sidebar = self;
  return _navigatorView;
}

- (TDDebugView *)debugView {
  if (_debugView)
    return _debugView;
  
  [NSBundle loadNibNamed:@"TDDebugView" owner:self];
  _debugView.project = _project;
  
  _project.networkController.bookmarksEnabled = [(NSCell*)_debugView.bookmarksButton.cell state] == NSOnState;
  _project.networkController.firstLineBreak = [(NSCell*)_debugView.firstLineButton.cell state] == NSOnState;
  return _debugView;
}

- (TDBookmarksView *)bookmarksView {
  if (_bookmarksView)
    return _bookmarksView;
  
  [NSBundle loadNibNamed:@"TDBookmarksView" owner:self];
  _bookmarksView.project = _project;

  return _bookmarksView;
}

- (void)toolbarClicked:(id)sender {
  int column = [toolbar selectedColumn];

  if ([[contentView subviews] count] > 0)
    [[[contentView subviews] objectAtIndex:0] removeFromSuperview];
  
  NSView* panel = nil;
  switch (column) {
    case SidebarTabNavigator:
      panel = self.navigatorView;
      break;
    case SidebarTabDebugger:
      panel = self.debugView;
      break;
    case SidebarTabBreakpoint:
      panel = self.bookmarksView;
      break;
  }
  panel.frame = contentView.bounds;
  [contentView addSubview:panel];
}

- (SidebarTab)selectedTab {
  return [toolbar selectedColumn];
}

- (void)selectTab:(SidebarTab)tab {
  [toolbar selectCellAtRow:0 column:tab];
  [self toolbarClicked:toolbar];
}
@end
