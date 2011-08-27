//
//  TDProjectNavigatorView.h
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

@class TDOutlineViewDataSource;
@class TDProject;
@class TDSearchField;
@class TDSidebar;

@interface TDProjectNavigatorView : NSView {
@private
  IBOutlet NSView* toolbar;
  IBOutlet NSView* contentView;

  NSMutableArray* _toolbarButtons;
  TDSidebar* _sidebar; // weak
  NSOutlineView* _outlineView;
  TDOutlineViewDataSource* _outlineViewDataSource;
  NSScrollView* _outlineScrollContainer;
  dispatch_queue_t _filterQueue;
  NSMutableArray *_fullOutlineViewExpandedItems;
  TDProject* _project;
  TDSearchField* _searchField;
}

@property (assign) NSView* toolbar;
@property (assign) NSView* contentView;
@property (assign) TDSidebar* sidebar;
@property (nonatomic,retain) TDProject* project;
@property (nonatomic,readonly) NSOutlineView* outlineView;
@property (readonly) dispatch_queue_t filterQueue;

- (void)initializeWithDrawer:(NSView*)drawerView;
- (void)filterOutlineView:(NSNotification*)notification;
- (void)recalculateTree;
- (void)terminalButtonPressed:(id)sender;
@end
