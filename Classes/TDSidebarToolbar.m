//
//  TDSidebarToolbar.m
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

#import "TDSidebarToolbar.h"

#import "TextMateDBGp.h"

@interface TDSidebarToolbar (PrivateMethods)
- (void)matrixClicked:(id)sender;
@end

@implementation TDSidebarToolbar

- (id)initWithFrame:(NSRect)frameRect {
  NSImage *image = [TextMateDBGp bundledImageWithName:@"ToolbarBackground"];
  frameRect.origin.y = frameRect.size.height - image.size.height;
  frameRect.size.height = image.size.height;
  self = [super initWithFrame:frameRect];
  if (!self)
    return self;
  
  _matrix = [[NSMatrix alloc] initWithFrame:NSMakeRect((frameRect.size.width-96)/2, 1, 96, 21) mode:NSRadioModeMatrix cellClass:[NSButtonCell class] numberOfRows:1 numberOfColumns:3];
  _matrix.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin;
  [_matrix setCellSize:NSMakeSize(32, 21)];
  [_matrix setIntercellSpacing:NSMakeSize(0, 0)];
  [self addSubview:_matrix];
  [_matrix setTarget:self];
  [_matrix setAction:@selector(matrixClicked:)];
  
  
  NSButtonCell* cell = [_matrix cellAtRow:0 column:0];
  [cell setBordered:NO];
  [cell setButtonType:NSRadioButton];
  [cell setImage:[TextMateDBGp bundledImageWithName:@"ToolbarNavigator"]];
  [cell setAlternateImage:[TextMateDBGp bundledImageWithName:@"ToolbarNavigatorHighlighted"]];

  cell = [_matrix cellAtRow:0 column:1];
  [cell setBordered:NO];
  [cell setButtonType:NSRadioButton];
  [cell setImage:[TextMateDBGp bundledImageWithName:@"ToolbarDebug"]];
  [cell setAlternateImage:[TextMateDBGp bundledImageWithName:@"ToolbarDebugHighlighted"]];
  
  cell = [_matrix cellAtRow:0 column:2];
  [cell setBordered:NO];
  [cell setButtonType:NSRadioButton];
  [cell setImage:[TextMateDBGp bundledImageWithName:@"ToolbarBookmarks"]];
  [cell setAlternateImage:[TextMateDBGp bundledImageWithName:@"ToolbarBookmarksHighlighted"]];
  return self;
}

- (void)dealloc {
  [_matrix release];
  [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
     [[NSColor blueColor] setFill];
   NSRectFill(dirtyRect);

  NSRect fromRect = NSZeroRect;
  NSImage *image = [TextMateDBGp bundledImageWithName:@"ToolbarBackground"];
  fromRect.size = [image size];
	
  [image drawInRect:[self bounds] fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0];
}


- (void)setDelegate:(id)delegate {
  _delegate = delegate;
}

- (void)matrixClicked:(id)sender {
  NSMatrix* matrix = sender;
  int column = [matrix selectedColumn];
  if ([_delegate respondsToSelector:@selector(selectedColumnChanged:)]) {
    [_delegate performSelector:@selector(selectedColumnChanged:) withObject:[NSNumber numberWithInt:column]];
  }
}

- (int)selectedColumn {
  return [_matrix selectedColumn];
}

- (void)selectColumn:(int)column {
  [_matrix selectCellAtRow:0 column:column];
  [self matrixClicked:_matrix];
}
@end
