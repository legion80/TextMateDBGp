//
//  TDStackVariable.h
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

@class TDStackContext;

@interface TDStackVariable : NSObject {
  NSMutableArray* _variables;
  
  NSString* _address;
  NSString* _name;
  NSString* _fullName;
  NSString* _className;
  NSString* _type;
  NSString* _facet;
  NSString* _size;
  NSString* _key;
  
  int _page;
  int _pageSize;
  
  BOOL _hasChildren;
  int _numChildren;
  
  BOOL _isBase64Encoding;
  NSString* _value;
  
  TDStackContext* _stackContext; // weak
}

@property (nonatomic,readonly,retain) NSString* address;
@property (nonatomic,readonly,retain) NSString* name;
@property (nonatomic,readonly,retain) NSString* fullName;
@property (nonatomic,readonly,retain) NSString* className;
@property (nonatomic,readonly,retain) NSString* type;
@property (nonatomic,readonly,retain) NSString* facet;
@property (nonatomic,readonly) NSString* size;
@property (nonatomic,readonly) NSString* key;
@property (nonatomic,readonly) int page;
@property (nonatomic,readonly) int pageSize;
@property (nonatomic,readonly) BOOL hasChildren;
@property (nonatomic,readonly) int numChildren;
@property (nonatomic,assign) TDStackContext* stackContext;
@property (nonatomic,readonly,retain) NSString* value;
@property (nonatomic,retain) NSArray* variables;

- (void)parsePropertyAttributes:(NSXMLElement*)xmlProperty;
- (void)appendSubProperties:(NSArray*)xmlProperties;
- (void)parseValue:(NSString*)xmlValue;
@end
