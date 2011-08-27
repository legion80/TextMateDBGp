//
//  TDStackFrame.m
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

#import "TDStackFrame.h"

#import "TDPlaceholderVariable.h"
#import "TDStackContext.h"
#import "TDStackVariable.h"
#import "NSWindowController+MDAdditions.h"

@interface TDStackFrame (PrivateMethods)
- (void)recalculateOutlineItemCount;
@end

@implementation TDStackFrame
- (id)initWithXMLElement:(NSXMLElement *)stackFrame {
  if (!(self = [super init]))
    return nil;
  _contexts = [[NSMutableArray alloc] init];
  _xmlElement = [stackFrame retain];
  _countOutlineItems = 0;
  _pendingVariableLoads = [[NSMutableDictionary alloc] init];
  return self;
}
- (id)copyWithZone:(NSZone *)zone {
  TDStackFrame* copy = [[TDStackFrame allocWithZone:zone] init];
  copy->_contexts = [_contexts retain];
  copy->_xmlElement = [_xmlElement retain];
  copy->_pendingVariableLoads = [_pendingVariableLoads retain];
  return copy;
}
- (void)dealloc {
  [_pendingVariableLoads release];
  [_xmlElement release];
  [_contexts release];
  [super dealloc];
}
- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: 0x%x, level: %d, function: %@:%d, fileName: %@, contexts: %@", [[self class] description], (long)self, [self stackLevel], [self stackFunction], [self lineNumber], [self fileName], _contexts];
}
- (int)stackLevel {
  return [[[_xmlElement attributeForName:@"level"] stringValue] intValue];
}
- (NSString *)stackFunction {
  return [[_xmlElement attributeForName:@"where"] stringValue];
}
- (NSString *)fileName {
  return [[_xmlElement attributeForName:@"filename"] stringValue];
}
- (int)lineNumber {
  return [[[_xmlElement attributeForName:@"lineno"] stringValue] intValue];
}
- (int)contextCount {
  return [_contexts count];
}
- (TDStackContext*)contextWithId:(int)contextId {
  if ([_contexts count] <= contextId)
    return nil;
  return [_contexts objectAtIndex:contextId];
}
- (int)outlineViewItemCount {
  return _countOutlineItems;
}
- (void)recalculateOutlineItemCount {
  _countOutlineItems = 0;
  for (TDStackContext* context in _contexts) {
    // Count one item for the name of the context
    ++_countOutlineItems;
    if (context.variables != nil)
      _countOutlineItems += [context.variables count];
  }
}
- (id)outlineViewItemForRow:(int)row {
  int soFar = 0;
  for (TDStackContext* context in _contexts) {
    if (row == soFar)
      return context;
    NSArray* variables = context.variables;
    int variableCount = [variables count];
    if (row < soFar + variableCount + 1)
      return [variables objectAtIndex:row - (soFar + 1)];
    soFar += variableCount + 1;
  }
  return nil;
}

- (void)addPendingLoad:(TDPlaceholderVariable*)loadData forVariable:(NSString*)fullNameVariable {
  [_pendingVariableLoads setObject:loadData forKey:fullNameVariable];
}


- (void)parseContexts:(NSArray *)contexts {
  for (NSXMLElement* xmlContext in contexts) {
    TDStackContext* context = [[TDStackContext alloc] init];
    NSAssert([[[xmlContext attributeForName:@"id"] stringValue] intValue] == [_contexts count], @"Mismatch");
    [_contexts addObject:context];
    [context release];
    
    context.stackFrame = self;
    context.name = [[xmlContext attributeForName:@"name"] stringValue];
    context.contextId = [[[xmlContext attributeForName:@"id"] stringValue] intValue];
  }
}

- (void)parseVariables:(NSXMLDocument *)document forContext:(int)contextId {
  NSXMLElement* rootElement = [document rootElement];
  NSArray* variables = [rootElement children];
  TDStackContext* context = [self contextWithId:contextId];
  [context parseProperties:variables];
  [self recalculateOutlineItemCount];
}

- (void)parseProperties:(NSXMLDocument *)document forVariable:(TDStackVariable*)variable {
  NSXMLElement* rootElement = [document rootElement];
  NSAssert([[[rootElement attributeForName:@"command"] stringValue] isEqualToString:DBGpCommandPropertyGet], @"Wrong command");
  NSAssert([[rootElement children] count] == 1, @"More children than expected");
  NSXMLElement* varElement = [[rootElement children] objectAtIndex:0];
  NSAssert([[variable.variables lastObject] isMemberOfClass:[TDPlaceholderVariable class]], @"Not a placeholder");
  [variable parsePropertyAttributes:varElement];
  [variable appendSubProperties:[varElement children]];
}
@end
