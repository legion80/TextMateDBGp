//
//  MDProject.m
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

#import "TDProject.h"

#import "TDBookmark.h"
#import "TDNetworkController.h"
#import <sys/xattr.h>
#import "vector"
#include <zlib.h>

@interface TDProject ()
- (void)gatherBookmarks:(NSDictionary*)item trackDifference:(NSMutableArray*)diff;
@end

@implementation TDProject
@synthesize originalOutlineView = _outlineView;
@synthesize bookmarkKeys = _bookmarkKeys;
@synthesize networkController = _networkController;
@synthesize projectController = _projectController;

- (id)init {
  if (!(self = [super init]))
    return nil;
  _bookmarks = [[NSMutableDictionary alloc] init];
  _bookmarkKeys = [[NSMutableArray alloc] init];
  _networkController = [[TDNetworkController alloc] init];
  _networkController.project = self;
  return self;
}

- (void)dealloc {
  [_networkController release];
  [_bookmarks release];
  [_bookmarkKeys release];
  self.originalOutlineView = nil;
  self.projectController = nil;
  [super dealloc];
}

- (void)openFile:(id)item atLineNumber:(int)lineNumber {
  NSWindowController* wc = [self projectController];
  if ([item respondsToSelector:@selector(substringToIndex:)]) {
    NSString* filename = item;
    if ([[filename substringToIndex:7] isEqualToString:@"file://"])
      filename = [filename substringFromIndex:7];
    item = [wc performSelector:@selector(itemWithPath:) withObject:filename];
    if (!item) {
      NSString* rootDir = [wc valueForKey:@"projectDirectory"];
      if ([filename hasPrefix:rootDir]) {
        filename = [filename substringFromIndex:[rootDir length]];
      }
      item = [wc performSelector:@selector(itemWithPath:) withObject:filename];
    }
  }
  
  if (!item)
    return;
  
  [wc performSelector:@selector(selectItem:) withObject:item];
  if (lineNumber >= 0) {
    NSTextView* textView = [wc valueForKey:@"textView"];
    [textView performSelector:@selector(goToLineNumber:) withObject:[NSNumber numberWithInt:lineNumber]];
  }
}

- (void)gatherBookmarks:(NSDictionary*)item trackDifference:(NSMutableArray*)diff {
  NSString* path = [item objectForKey:@"filename"];
  if (path) {
    const char* filePath = [path cStringUsingEncoding:NSASCIIStringEncoding];
    const char* key = "com.macromates.bookmarked_lines";
    ssize_t dataSize = getxattr(filePath, key, NULL, 0, 0, 0);
    if (dataSize <= 0)
      return;
    
    std::vector<char> v(dataSize);
    if(getxattr(filePath, key, &v[0], v.size(), 0, 0) == -1)
      return;
    
    uLongf destLen = 5 * v.size();
    std::vector<char> dest;
    int zlib_res = Z_BUF_ERROR;
    while(zlib_res == Z_BUF_ERROR && destLen < 1024*1024)
    {
      destLen <<= 2;
      dest = std::vector<char>(destLen);
      zlib_res = uncompress((Bytef*)&dest[0], &destLen, (Bytef*)&v[0], v.size()); 
    }
    
    if(zlib_res == Z_OK)
    {
      dest.resize(destLen);
      dest.swap(v);
    }
    
    NSArray* lines = [NSPropertyListSerialization propertyListFromData: [NSData dataWithBytes:&v[0] length:v.size()] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:NULL];
    
    NSMutableArray* bookmarks = [NSMutableArray array];
    NSNumber* pathHash = [NSNumber numberWithUnsignedInt:[path hash]];
    NSSet* correspondingItemSet = [_bookmarks keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
      if ([[obj objectForKey:@"hash"] isEqual:pathHash]) {
        *stop = YES;
        return YES;
      }
      return NO;
    }];
    if ([correspondingItemSet count] == 1) {
      id oldItem = [correspondingItemSet anyObject];
      if (oldItem != item) {
        id itemData = [[_bookmarks objectForKey:oldItem] retain];
        [_bookmarks removeObjectForKey:oldItem];
        [_bookmarks setObject:itemData forKey:item];
        [itemData release];
        bookmarks = [itemData objectForKey:@"bookmarks"];
        [_bookmarkKeys removeObject:oldItem];
      }
    }
    else {
      [_bookmarks setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                             pathHash, @"hash",
                             bookmarks, @"bookmarks", nil]
                     forKey:item];
    }
    // We assume that the line numbers listed in the extended attributes is sorted
    int currentBookmarkIndex = 0;
    TDBookmark* currentBookmark = [bookmarks count] > 0 ? [bookmarks objectAtIndex:currentBookmarkIndex] : nil;
    for (NSObject* line in lines) {
      int lineNumber = [(NSString*)line intValue];
      
      TDBookmark* bookmark = nil;
      if (currentBookmark == nil) {
        bookmark = [[TDBookmark alloc] init];
        [bookmarks addObject:bookmark];
        [bookmark release];
        [diff addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                         @"add", @"op",
                         bookmark, @"bookmark", nil]];
      }
      else {
        while (currentBookmark != nil && lineNumber > currentBookmark.lineNumber) {
          // add a new bookmark
          [diff addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"remove", @"op",
                           currentBookmark, @"bookmark", nil]];
          [bookmarks removeObjectAtIndex:currentBookmarkIndex];
          
          currentBookmark = currentBookmarkIndex < [bookmarks count] ? [bookmarks objectAtIndex:currentBookmarkIndex] : nil;
        }
        
        if (lineNumber < currentBookmark.lineNumber) {
          // add a new bookmark
          bookmark = [[TDBookmark alloc] init];
          [bookmarks insertObject:bookmark atIndex:currentBookmarkIndex];
          [bookmark release];
          ++currentBookmarkIndex;
          [diff addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"add", @"op",
                           bookmark, @"bookmark", nil]];
        }
        else if (lineNumber == currentBookmark.lineNumber) {
          // replace
          bookmark = currentBookmark;
          ++currentBookmarkIndex;
          currentBookmark = currentBookmarkIndex < [bookmarks count] ? [bookmarks objectAtIndex:currentBookmarkIndex] : nil;
        }
      }
      
      bookmark.source = path;
      // line is either __NSCFConstantString or __NSCFString
      bookmark.lineNumber = lineNumber;
    }
    // any leftover bookmarks in the array do not exist
    while (currentBookmark != nil) {
      [diff addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                       @"remove", @"op",
                       [bookmarks objectAtIndex:currentBookmarkIndex], @"bookmark",
                       nil]];
      [bookmarks removeObjectAtIndex:currentBookmarkIndex];
      currentBookmark = currentBookmarkIndex < [bookmarks count] ? [bookmarks objectAtIndex:currentBookmarkIndex] : nil;
    }
    return;
  }
  
  NSArray* children = [item objectForKey:@"children"];
  if (children) {
    for (NSDictionary* subitem in children) {
      [self gatherBookmarks:subitem trackDifference:diff];
    }
  }
}

- (NSArray*)gatherBookmarks {
  NSArray* rootItems = [[self projectController] valueForKey:@"rootItems"];
  NSMutableArray* diff = [NSMutableArray array];
  for (NSDictionary* item in rootItems) {
    [self gatherBookmarks:item trackDifference:diff];
  }
  // whatever is leftover in _bookmarkKeys are files that have no bookmarks
  [_bookmarks removeObjectsForKeys:_bookmarkKeys];
  [_bookmarkKeys removeAllObjects];
  [_bookmarkKeys addObjectsFromArray:[_bookmarks allKeys]];
  [_bookmarkKeys sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    NSString* fileName1 = [[obj1 objectForKey:@"filename"] lastPathComponent];
    NSString* fileName2 = [[obj2 objectForKey:@"filename"] lastPathComponent];
    return [fileName1 compare:fileName2];
  }];
  return diff;
}

- (NSArray *)bookmarksForFileItem:(id)item {
  return [[_bookmarks objectForKey:item] objectForKey:@"bookmarks"];
}
@end
