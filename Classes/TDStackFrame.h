//
//  TDStackFrame.h
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

@class TDPlaceholderVariable;
@class TDStackContext;
@class TDStackVariable;

@interface TDStackFrame : NSObject <NSCopying> {
  NSXMLElement* _xmlElement;
  NSMutableArray* _contexts;
  NSMutableDictionary* _pendingVariableLoads;
  
  int _countOutlineItems;
}

- (id)initWithXMLElement:(NSXMLElement*)stackFrame;

- (int)stackLevel;
- (NSString*)stackFunction;
- (NSString*)fileName;
- (int)lineNumber;
- (int)contextCount;
- (TDStackContext*)contextWithId:(int)contextId;

- (int)outlineViewItemCount;
- (id)outlineViewItemForRow:(int)row;

- (void)addPendingLoad:(TDPlaceholderVariable*)loadData forVariable:(NSString*)fullNameVariable;

- (void)parseContexts:(NSArray*)contexts;
- (void)parseVariables:(NSXMLDocument *)document forContext:(int)contextId;
- (void)parseProperties:(NSXMLDocument *)document forVariable:(TDStackVariable*)variable;
@end
