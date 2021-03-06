//
//  TDSplitView.m
//  TextMateDBGp
//
//	Copyright (c) The MissingDrawer authors.
//  Copyright (c) Jon Lee.
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

#import "TDSplitView.h"

#import "MDSettings.h"
#import "TDSidebar.h"

@implementation TDSplitView

@synthesize sidebar = _sidebar;
@synthesize mainView = _mainView;

#pragma mark NSObject

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_sidebar release];
	[_mainView release];
	[super dealloc];
}


#pragma mark NSSplitView

- (void)drawDividerInRect:(NSRect)aRect {
  [[NSColor colorWithDeviceWhite:0.625 alpha:1] setFill];
  [NSBezierPath fillRect:aRect];
}


#pragma mark Initializer

- (id)initWithFrame:(NSRect)frame mainView:(NSView *)aMainView sideView:(TDSidebar *)aSideView {
  if (!(self = [super initWithFrame:frame])) {
    return nil;
  }
  
  [self setDelegate:self];
  
  _mainView = [aMainView retain];
  _sidebar = [aSideView retain];
  [self setVertical:YES];
  
  if([MDSettings defaultSettings].showSideViewOnLeft) {
    [self addSubview:self.sidebar];
    [self addSubview:self.mainView];
  } else {
    [self addSubview:self.mainView];
    [self addSubview:self.sidebar];
  }
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleLayout) name:@"MDSideviewLayoutHasBeenChangedNotification" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusSideView) name:@"MDFocusSideViewPressed" object:nil];
  
  return self;
}

#pragma mark -

- (void)focusSideView {
  if([_sidebar acceptsFirstResponder]){
    [_sidebar becomeFirstResponder];
  } else {
    for(NSView *view in [_sidebar subviews]){
      if([view acceptsFirstResponder]){
        [view becomeFirstResponder];
        break;
      }
    }
  }
}

#pragma mark Drawing

- (void)toggleLayout {
  NSView *leftView = [[[self subviews] objectAtIndex:0] retain];
  [leftView removeFromSuperview];
  [self addSubview:leftView];
  [leftView release];
  [self adjustSubviews];
}

#pragma mark Layout

- (void)windowWillCloseWillCall {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if ([self.sidebar frame].size.width <= 0) {
    NSRect sideViewFrame = [self.sidebar frame];
    sideViewFrame.size.width = MIN_SIDEVIEW_WIDTH;
    [self.sidebar setFrame:sideViewFrame];
    [self adjustSubviews];
  }
  [self saveLayout];
  
  if (self.sidebar){
    NSDrawer *drawer = [[[self window] drawers] objectAtIndex:0];
    [self.sidebar removeFromSuperview];
    [drawer setContentView:self.sidebar];
    [_sidebar release], _sidebar = nil;
  }
}


- (void)applyLayout:(NSRect)layout toView:(NSView *)view {
  NSRect newFrame = layout;
  if(NSIsEmptyRect(newFrame)) {
    newFrame = [view frame];
    if([self isVertical]) {
      newFrame.size.width = 0;
    } else {
      newFrame.size.height = 0;
    }
  }
  [view setFrame:newFrame];
}


- (void)saveLayout {
  MDSettings *settings = [MDSettings defaultSettings];
  settings.sideViewLayout = [self.sidebar frame];
  settings.mainViewLayout = [self.mainView frame];
  [settings save];
}


- (void)restoreLayout {
  MDSettings *settings = [MDSettings defaultSettings];
  [self applyLayout:settings.sideViewLayout toView:self.sidebar];
  [self.sidebar adjustLayout];
  [self applyLayout:settings.mainViewLayout toView:self.mainView];
}


#pragma mark NSSplitView Delegate

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview {
  return NO;
}


- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
  if ([[self subviews] objectAtIndex:offset] == self.sidebar) {
    return MIN_SIDEVIEW_WIDTH;
  } else {
    return [self frame].size.width - MAX_SIDEVIEW_WIDTH;
  }
  
}


- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
  if ([[self subviews] objectAtIndex:offset] == self.sidebar) {
    return MAX_SIDEVIEW_WIDTH;
  } else {
    return [self frame].size.width - MIN_SIDEVIEW_WIDTH;
  }
}


- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
  [self setDividerStyle:NSSplitViewDividerStyleThin];
  
  CGFloat dividerThickness = [self dividerThickness];
  
  NSRect windowFrame = [[NSApp mainWindow] frame];
  windowFrame.size.width = MAX(3 * MIN_SIDEVIEW_WIDTH + dividerThickness, windowFrame.size.width);
  [[NSApp mainWindow] setFrame:windowFrame display:YES];
  
  NSRect splitViewFrame = [self frame];
  splitViewFrame.size.width = MAX(3 * MIN_SIDEVIEW_WIDTH + dividerThickness, splitViewFrame.size.width);
  [splitView setFrame:splitViewFrame];
  
  NSRect sideViewFrame = [self.sidebar frame];
  NSRect mainViewFrame = [self.mainView frame];
  sideViewFrame.size.height = splitViewFrame.size.height;
  mainViewFrame.size.height = splitViewFrame.size.height;
  
  mainViewFrame.size.width = splitViewFrame.size.width - sideViewFrame.size.width - dividerThickness;
  
  if ([MDSettings defaultSettings].showSideViewOnLeft) {
    mainViewFrame.origin.x = sideViewFrame.size.width + dividerThickness;
    sideViewFrame.origin.x = 0;
  } else {
    mainViewFrame.origin.x = 0;
    sideViewFrame.origin.x = mainViewFrame.size.width + dividerThickness;
  }
  
  [self.sidebar setFrame:sideViewFrame];
  [self.mainView setFrame:mainViewFrame];
}

@end
