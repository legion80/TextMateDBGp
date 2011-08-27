//
//  TDStackContext.m
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

#import "TDStackContext.h"

#import "TDStackVariable.h"

@implementation TDStackContext
@synthesize name = _name;
@synthesize contextId = _id;
@synthesize variables = _variables;
@synthesize stackFrame = _stackFrame;

- (id)init {
  if (!(self = [super init]))
    return nil;
  return self;
}

- (void)dealloc {
  self.name = nil;
  [_variables release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Context: %@ (%d), Variables: %@", _name, _id, _variables];
}

- (BOOL)variablesLoaded {
  return _variables != nil;
}

- (void)parseProperties:(NSArray *)xmlProperties {
  if (_variables == nil) {
    _variables = [[NSMutableArray alloc] init];
  }
  
  for (NSXMLElement* xmlProperty in xmlProperties) {
    if ([[[xmlProperty attributeForName:@"name"] stringValue] isEqualToString:@"CLASSNAME"])
      continue;
    
    TDStackVariable* variable = [[TDStackVariable alloc] init];
    [_variables addObject:variable];
    [variable release];
    
    variable.stackContext = self;
    [variable parsePropertyAttributes:xmlProperty];
    if (variable.hasChildren)
      [variable appendSubProperties:[xmlProperty children]];
    else
      [variable parseValue:[xmlProperty stringValue]];
  }
}
@end
