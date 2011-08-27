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
  
  NSRect contentRect = contentView.bounds;
  [NSBundle loadNibNamed:@"TDProjectNavigatorView" owner:self];
  _navigatorView.frame = contentRect;
  _navigatorView.project = _project;
  _navigatorView.sidebar = self;
  [contentView addSubview:_navigatorView];
  return _navigatorView;
}

- (TDDebugView *)debugView {
  if (_debugView)
    return _debugView;
  
  NSRect contentRect = contentView.bounds;
  [NSBundle loadNibNamed:@"TDDebugView" owner:self];
  _debugView.frame = contentRect;
  _debugView.project = _project;
  [contentView addSubview:_debugView];
  
  _project.networkController.bookmarksEnabled = [(NSCell*)_debugView.bookmarksButton.cell state] == NSOnState;
  _project.networkController.firstLineBreak = [(NSCell*)_debugView.firstLineButton.cell state] == NSOnState;
  return _debugView;
}

- (TDBookmarksView *)bookmarksView {
  if (_bookmarksView)
    return _bookmarksView;
  
  NSRect contentRect = contentView.bounds;
  [NSBundle loadNibNamed:@"TDBookmarksView" owner:self];
  _bookmarksView.frame = contentRect;
  _bookmarksView.project = _project;
  [contentView addSubview:_bookmarksView];

  return _bookmarksView;
}

- (void)toolbarClicked:(id)sender {
  int column = [toolbar selectedColumn];

  switch (column) {
    case 0:
      [self addSubview:self.navigatorView positioned:NSWindowAbove relativeTo:nil];
      break;
    case 1:
      [self addSubview:self.debugView positioned:NSWindowAbove relativeTo:nil];
      break;
    case 2:
      [self addSubview:self.bookmarksView positioned:NSWindowAbove relativeTo:nil];
      break;
  }
}

- (int)selectedView {
  return [toolbar selectedColumn];
}

- (void)selectView:(int)viewIndex {
  [toolbar selectCellAtRow:0 column:viewIndex];
  [self toolbarClicked:toolbar];
}
@end
