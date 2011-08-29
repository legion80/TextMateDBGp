//
//  TDDebugVariablesOutlineView.m
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

#import "TDDebugVariableOutlineView.h"

#import "TDStackVariable.h"

@implementation TDDebugVariableOutlineView
- (void)copy:(id)sender {
  NSIndexSet* rows = [self selectedRowIndexes];
  NSMutableArray* data = [NSMutableArray array];
  [rows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    id item = [self itemAtRow:idx];
    int level = [self levelForRow:idx];
    if (![item isMemberOfClass:[TDStackVariable class]])
      return;
    TDStackVariable* variable = item;
    [data addObject:[NSString stringWithFormat:@"%@%@\t%@\t%@\t%@",
                     [@"" stringByPaddingToLength:level withString:@"." startingAtIndex:0],
                     variable.name, variable.value == nil ? @"" : variable.value,
                     variable.type, variable.address == nil ? @"" : variable.address]];
  }];
  NSPasteboard* pb = [NSPasteboard generalPasteboard];
  [pb clearContents];
  [pb writeObjects:data];
}
@end
