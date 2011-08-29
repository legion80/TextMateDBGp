//
//  TDDebugView.h
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

#import "GCDAsyncSocket.h"

@class TDProject;
@class TDSidebar;

@interface TDDebugView : NSView <GCDAsyncSocketDelegate, NSTableViewDataSource, NSTableViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate> {
@private
  IBOutlet NSButton* connectButton;
  IBOutlet NSButton* firstLineButton;
  IBOutlet NSTextField* connectionLabel;
  IBOutlet NSTextField* statusLabel;

  IBOutlet NSButton* debugPlayButton;
  IBOutlet NSButton* debugStepOverButton;
  IBOutlet NSButton* debugStepInButton;
  IBOutlet NSButton* debugStepOutButton;
  IBOutlet NSButton* bookmarksButton;
  
  IBOutlet NSTableView* stackTableView;
  IBOutlet NSOutlineView* variableOutlineView;

  TDProject* _project;
  TDSidebar* _sidebar; //weak
  NSColor* _backgroundColor;
}

@property (nonatomic,retain) TDProject* project;
@property (nonatomic,assign) TDSidebar* sidebar;
@property (nonatomic,retain) NSColor* backgroundColor;
@property (assign) NSButton* connectButton;
@property (assign) NSButton* firstLineButton;
@property (assign) NSTextField* statusLabel;
@property (assign) NSTextField* connectionLabel;

@property (assign) NSButton* debugPlayButton;
@property (assign) NSButton* debugStepOverButton;
@property (assign) NSButton* debugStepInButton;
@property (assign) NSButton* debugStepOutButton;
@property (assign) NSButton* bookmarksButton;

@property (assign) NSTableView* stackTableView;
@property (assign) NSOutlineView* variableOutlineView;

- (IBAction)toggleListener:(id)sender;
- (IBAction)debugButtonPressed:(id)sender;
- (IBAction)toggleEnableBookmarks:(id)sender;
- (IBAction)toggleFirstLine:(id)sender;
@end
