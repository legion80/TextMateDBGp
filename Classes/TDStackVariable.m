//
//  TDStackVariable.m
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

#import "TDStackVariable.h"

#import "TDStackContext.h"
#import "TDStackFrame.h"
#import "TDPlaceholderVariable.h"

@interface NSData (Base64)
+ (NSData *)decodeBase64WithString:(NSString *)strBase64;
@end


static const short _base64DecodingTable[256] = {
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
	-2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
	-2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};

@implementation NSData (Base64)

+ (NSData *)decodeBase64WithString:(NSString *)strBase64 {
	const char * objPointer = [strBase64 cStringUsingEncoding:NSASCIIStringEncoding];
	if (objPointer == NULL)  return nil;
	size_t intLength = strlen(objPointer);
	int intCurrent;
	int i = 0, j = 0, k;
  
	unsigned char * objResult;
	objResult = calloc(intLength, sizeof(char));
  
	// Run through the whole string, converting as we go
	while ( ((intCurrent = *objPointer++) != '\0') && (intLength-- > 0) ) {
		if (intCurrent == '=') {
			if (*objPointer != '=' && ((i % 4) == 1)) {// || (intLength > 0)) {
				// the padding character is invalid at this point -- so this entire string is invalid
				free(objResult);
				return nil;
			}
			continue;
		}
    
		intCurrent = _base64DecodingTable[intCurrent];
		if (intCurrent == -1) {
			// we're at a whitespace -- simply skip over
			continue;
		} else if (intCurrent == -2) {
			// we're at an invalid character
			free(objResult);
			return nil;
		}
    
		switch (i % 4) {
			case 0:
				objResult[j] = intCurrent << 2;
				break;
        
			case 1:
				objResult[j++] |= intCurrent >> 4;
				objResult[j] = (intCurrent & 0x0f) << 4;
				break;
        
			case 2:
				objResult[j++] |= intCurrent >>2;
				objResult[j] = (intCurrent & 0x03) << 6;
				break;
        
			case 3:
				objResult[j++] |= intCurrent;
				break;
		}
		i++;
	}
  
	// mop things up if we ended on a boundary
	k = j;
	if (intCurrent == '=') {
		switch (i % 4) {
			case 1:
				// Invalid state
				free(objResult);
				return nil;
        
			case 2:
				k++;
				// flow through
			case 3:
				objResult[k] = 0;
		}
	}
  
	// Cleanup and setup the return NSData
	return [[[NSData alloc] initWithBytesNoCopy:objResult length:j freeWhenDone:YES] autorelease];
}

@end


@interface TDStackVariable ()
@property (nonatomic,readwrite,retain) NSString* address;
@property (nonatomic,readwrite,retain) NSString* name;
@property (nonatomic,readwrite,retain) NSString* fullName;
@property (nonatomic,readwrite,retain) NSString* facet;
@property (nonatomic,readwrite,retain) NSString* type;
@property (nonatomic,readwrite,retain) NSString* className;
@property (nonatomic,readwrite,retain) NSString* value;
@end

@implementation TDStackVariable
@synthesize address = _address;
@synthesize name = _name;
@synthesize fullName = _fullName;
@synthesize className = _className;
@synthesize type = _type;
@synthesize facet = _facet;
@synthesize size = _size;
@synthesize key = _key;
@synthesize page = _page;
@synthesize pageSize = _pageSize;
@synthesize hasChildren = _hasChildren;
@synthesize numChildren = _numChildren;
@synthesize variables = _variables;
@synthesize value = _value;
@synthesize stackContext = _stackContext;

- (id)init {
  if (!(self = [super init]))
    return nil;
  _variables = [[NSMutableArray alloc] init];
  _page = -1;
  _pageSize = 0;
  _hasChildren = NO;
  _numChildren = 0;
  _isBase64Encoding = NO;
  return self;
}

- (void)dealloc {
  self.address = nil;
  self.name = nil;
  self.fullName = nil;
  self.className = nil;
  self.type = nil;
  self.facet = nil;
  [_size release];
  [_key release];
  [_variables release];
  [_cachedAttrString release];
  self.value = nil;
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@ (%@) %@", _name, _address, _value != nil ? _value : _variables];
}

- (void)parsePropertyAttributes:(NSXMLElement *)xmlProperty {
  if ([xmlProperty attributeForName:@"name"] && _name == nil)
    self.name = [[xmlProperty attributeForName:@"name"] stringValue];
  if ([xmlProperty attributeForName:@"fullname"])
    self.fullName = [[xmlProperty attributeForName:@"fullname"] stringValue];
  if ([xmlProperty attributeForName:@"classname"])
    self.className = [[xmlProperty attributeForName:@"classname"] stringValue];
  if ([xmlProperty attributeForName:@"address"])  
    self.address = [NSString stringWithFormat:@"0x%llx", [[[xmlProperty attributeForName:@"address"] stringValue] longLongValue]];
  
  if ([xmlProperty attributeForName:@"page"])
    _page = [[[xmlProperty attributeForName:@"page"] stringValue] intValue];
  if ([xmlProperty attributeForName:@"pagesize"])
    _pageSize = [[[xmlProperty attributeForName:@"pagesize"] stringValue] intValue];
  
  if ([xmlProperty attributeForName:@"type"])
    self.type = [[xmlProperty attributeForName:@"type"] stringValue];
  if ([xmlProperty attributeForName:@"facet"])
    self.facet = [[xmlProperty attributeForName:@"facet"] stringValue];
  if ([xmlProperty attributeForName:@"size"])
    _size = [[[xmlProperty attributeForName:@"size"] stringValue] retain];
  if ([xmlProperty attributeForName:@"key"])
    _key = [[[xmlProperty attributeForName:@"key"] stringValue] retain];
  
  if ([xmlProperty attributeForName:@"children"])
    _hasChildren = [[[xmlProperty attributeForName:@"children"] stringValue] isEqualToString:@"1"];
  if ([xmlProperty attributeForName:@"numchildren"])
    _numChildren = [[[xmlProperty attributeForName:@"numchildren"] stringValue] intValue];
  
  if ([xmlProperty attributeForName:@"encoding"])
    _isBase64Encoding = [[[xmlProperty attributeForName:@"encoding"] stringValue] isEqualToString:@"base64"];
  
  [_cachedAttrString release];
  _cachedAttrString = nil;
}

- (void)appendSubProperties:(NSArray *)xmlProperties {
  if ([[_variables lastObject] isMemberOfClass:[TDPlaceholderVariable class]]) {
    NSAssert([(TDPlaceholderVariable*)[_variables lastObject] pageToLoad] == _page, @"Pages don't match");
    [_variables removeLastObject];
  }
  
  for (NSXMLElement* xmlProperty in xmlProperties) {
    if ([[[xmlProperty attributeForName:@"name"] stringValue] isEqualToString:@"CLASSNAME"])
      continue;
    
    TDStackVariable* variable = [[TDStackVariable alloc] init];
    [_variables addObject:variable];
    [variable release];
    
    variable.stackContext = _stackContext;
    [variable parsePropertyAttributes:xmlProperty];
    if (variable.hasChildren)
      [variable appendSubProperties:[xmlProperty children]];
    else
      [variable parseValue:[xmlProperty stringValue]];
  }
  
  if ([_variables count] == _numChildren) {
    return;
  }
  
  TDPlaceholderVariable* placeholder = [[TDPlaceholderVariable alloc] init];
  placeholder.pageToLoad = _page + 1;
  placeholder.stackContext = _stackContext;
  placeholder.stackVariable = self;
  [_variables addObject:placeholder];
  [_stackContext.stackFrame addPendingLoad:placeholder
                               forVariable:_fullName];
  [placeholder release];
}

- (void)parseValue:(NSString*)xmlValue {
  if (!xmlValue || [xmlValue length] == 0)
    return;
  
  if (!_isBase64Encoding) {
    self.value = xmlValue;
    return;
  }
  NSData* decodedData = [[NSData decodeBase64WithString:xmlValue] retain];
  self.value = [NSString stringWithCString:decodedData.bytes encoding:NSUTF8StringEncoding];
  [decodedData release];
}

- (NSAttributedString *)attributedStringWithDefaultFont:(NSFont*)font {
  if (_cachedAttrString)
    return _cachedAttrString;
  
  int fontSize = font.pointSize;
  NSMutableString* s = [NSMutableString stringWithFormat:@"<span style=\"font-family:'%@';font-size:%dpx\"><b>%@</b> <font color=\"#999\">=</font>",font.fontName, fontSize,self.name];
  if (self.value) {
    [s appendFormat:@" %@", self.value];
  }
  [s appendFormat:@"</span><span style=\"font-family:'Arial'; font-size:%dpx; font-style:italic\">", fontSize - 1];
  if (self.className) {
    [s appendFormat:@"<span style=\"color:blue;\"> %@</span>", self.className];
  }
  if (self.type) {
    [s appendFormat:@"<span style=\"color:green\"> %@</span>", self.type];
  }
  if (self.address)
    [s appendFormat:@"<span style=\"color:#888\"> (%@)</span>", self.address];
  [s appendString:@"</span>"];
  _cachedAttrString = [[NSMutableAttributedString alloc] initWithHTML:[s dataUsingEncoding:NSUTF8StringEncoding]
                                                   documentAttributes:NULL];
  //[_cachedAttrString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [_cachedAttrString length])];
  return _cachedAttrString;
}
@end
