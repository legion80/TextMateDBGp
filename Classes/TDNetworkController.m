//
//  TDNetworkController.m
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

#import "TDNetworkController.h"

#import "TDBookmark.h"
#import "TDDebugSession.h"
#import "TDProject.h"

static NSMutableData* s_sentinel = nil;
static int s_transactionId = 0;

@implementation TDNetworkController
@synthesize socket = _socket;
@synthesize project = _project;
@synthesize bookmarksEnabled = _bookmarksEnabled;
@synthesize firstLineBreak = _firstLineBreak;

+ (void)load {
  s_sentinel = [[NSMutableData alloc] initWithLength:1];
}

- (id)init {
  if (!(self = [super init]))
    return nil;
  
  _dispatchQueue = dispatch_queue_create("com.github.legion80.textmatedbgp", NULL);
  _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_dispatchQueue];  
  _openSessions = [[NSMutableArray alloc] init];
  return self;
}

- (void)dealloc {
  [_openSessions release];
  
  [_socket setDelegate:nil];
  [_socket disconnect];
  [_socket release];
  dispatch_release(_dispatchQueue);
  [super dealloc];
}

- (TDDebugSession*)currentOpenSession {
  int count = [_openSessions count];
  if (count == 0)
    return nil;
  return [_openSessions objectAtIndex:count - 1];
}

- (void)setBookmarksEnabled:(BOOL)bookmarksEnabled {
  if (bookmarksEnabled == _bookmarksEnabled)
    return;
  [self willChangeValueForKey:@"bookmarksEnabled"];
  _bookmarksEnabled = bookmarksEnabled;
  [self didChangeValueForKey:@"bookmarksEnabled"];
  if ([[self currentOpenSession] state] != WaitingForContact) {
    for (id fileItem in self.project.bookmarkKeys) {
      for (NSArray* bookmarksForFile in [self.project bookmarksForFileItem:fileItem]) {
        for (TDBookmark* bookmark in bookmarksForFile) {
          if (![bookmark bookmarkIdDetermined])
            continue;
          [self session:[self currentOpenSession] updateBreakpointId:bookmark.bookmarkId enabled:_bookmarksEnabled];
        }
      }
    }
  }
}

#pragma mark GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
  TDDebugSession* newSession = [[TDDebugSession alloc] initWithSocket:newSocket controller:self];
  [_openSessions addObject:newSession];
  [newSession release];
  
  [self session:newSession readResponseWithTag:TAG_INITIAL_CONNECTION];
  [[NSNotificationCenter defaultCenter] postNotificationName:TDNetworkControllerDidAcceptNewSocketNotification object:self];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
  if ((tag & TAG_MASK) == TAG_DATA_LENGTH)
    return;
  
  NSString* response = [[[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding] autorelease];
  //MDLog(@"%d %@", tag, response);
  // Test if we can convert it into an NSXMLDocument.
  NSError* error = nil;
  NSXMLDocument* xml = [[NSXMLDocument alloc] initWithXMLString:response
                                                        options:NSXMLDocumentTidyXML
                                                          error:&error];
  // TODO: Remove this assert before stable release. Flush out any possible
  // issues during testing.
  assert(xml);
  
  for (TDDebugSession* session in _openSessions) {
    if (session.socket == sock)
      [session didReadData:xml withTag:tag];
  }
  [xml release];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
  for (TDDebugSession* session in _openSessions) {
    if (session.socket == sock)
      [_openSessions removeObject:session];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:TDNetworkControllerDidDisconnectSocketNotification object:self];
}

#pragma mark -
- (void)startListening {
  if (![_socket isDisconnected])
    return;
  
  NSError* error = nil;
  [_socket acceptOnPort:9000 error:&error];
  if (error) {
    MDLog(@"%@", error);
  }
}
- (void)stopListening {
  if ([self currentOpenSession])
    [[self currentOpenSession] close];
  
  // Don't check to see if it's connected. The master socket won't be.
  [_socket disconnect];
}

#pragma mark Network interface

- (long)session:(TDDebugSession*)session sendRequest:(NSString*)command {
  GCDAsyncSocket* socket = session.socket;
  if (!socket || [socket isDisconnected])
    return NO_TRANSACTION;
  
  long writeTag = s_transactionId + TAG_WRITE;
  command = [command stringByAppendingFormat:@" -i %d", writeTag];
  NSMutableData* data = [NSMutableData dataWithData:[command dataUsingEncoding:NSUTF8StringEncoding]];
  [data appendData:s_sentinel];
  
  [socket writeData:data withTimeout:10 tag:writeTag];
  [self session:session readResponseWithTag:TAG_RESPONSE];
  s_transactionId += TRANSACTION_STEP;
  return writeTag;
}

- (long)session:(TDDebugSession*)session readResponseWithTag:(long)tag {
  GCDAsyncSocket* socket = session.socket;
  [socket readDataToData:s_sentinel withTimeout:10 tag:s_transactionId + TAG_DATA_LENGTH];
  [socket readDataToData:s_sentinel withTimeout:10 tag:s_transactionId + tag];
  return s_transactionId + tag;
}


- (long)session:(TDDebugSession*)session featureGet:(NSString*)featureName {
  return [self session:session sendRequest:[NSString stringWithFormat:@"%@ -n %@", DBGpCommandFeatureGet, featureName]];
}
- (long)session:(TDDebugSession *)session featureSet:(NSString *)featureName value:(NSString *)value {
  return [self session:session sendRequest:[NSString stringWithFormat:@"%@ -n %@ -v %@", DBGpCommandFeatureSet, featureName, value]];
}
- (void)sessionRun:(TDDebugSession *)session {
  [self session:session sendRequest:DBGpCommandRun];
}
- (void)sessionStepIn:(TDDebugSession *)session {
  [self session:session sendRequest:DBGpCommandStepInto];
}
- (void)sessionStepOut:(TDDebugSession *)session {
  [self session:session sendRequest:DBGpCommandStepOut];
}
- (void)sessionStepOver:(TDDebugSession *)session {
  [self session:session sendRequest:DBGpCommandStepOver];
}
- (void)sessionStop:(TDDebugSession *)session {
  [self session:session sendRequest:DBGpCommandStop];
}

- (long)session:(TDDebugSession *)session setLineBreakpointInFile:(NSString *)filePath lineNumber:(long)lineNumber temporary:(BOOL)temporary enabled:(BOOL)isEnabled {
  return [self session:session sendRequest:[NSString stringWithFormat:@"%@ -t line -s %@ -f \"%@\" -n %d -r %d", DBGpCommandBreakpointSet, isEnabled && _bookmarksEnabled ? @"enabled" : @"disabled", filePath, lineNumber, temporary]];
}
- (void)session:(TDDebugSession*)session updateBreakpointId:(long)breakpointId enabled:(BOOL)isEnabled {
  [self session:session sendRequest:[NSString stringWithFormat:@"%@ -d %d -s %@", DBGpCommandBreakpointUpdate, breakpointId, isEnabled && _bookmarksEnabled ? @"enabled" : @"disabled"]];
}
- (void)session:(TDDebugSession *)session removeBreakpointId:(long)breakpointId {
  [self session:session sendRequest:[NSString stringWithFormat:@"%@ -d %d", DBGpCommandBreakpointRemove, breakpointId]];
}

- (void)sessionStackDepth:(TDDebugSession *)session {
  [self session:session sendRequest:DBGpCommandStackDepth];
}
- (void)sessionStackGet:(TDDebugSession *)session {
  [self session:session sendRequest:DBGpCommandStackGet];
}
- (void)session:(TDDebugSession *)session stackGet:(int)depth {
  [self session:session sendRequest:[NSString stringWithFormat:@"%@ -d %d", DBGpCommandStackGet, depth]];
}

- (long)session:(TDDebugSession *)session contextNamesAtDepth:(int)depth {
  return [self session:session sendRequest:[NSString stringWithFormat:@"%@ -d %d", DBGpCommandContextNames, depth]];
}
- (long)session:(TDDebugSession *)session contextGet:(int)context stackDepth:(int)depth {
  return [self session:session sendRequest:[NSString stringWithFormat:@"%@ -d %d -c %d", DBGpCommandContextGet, depth, context]];
}
- (long)session:(TDDebugSession *)session contextGetStackDepth:(int)depth {
  return [self session:session sendRequest:[NSString stringWithFormat:@"%@ -d %d", DBGpCommandContextGet, depth]];
}

- (long)session:(TDDebugSession *)session propertyGet:(NSString *)fullName context:(int)context stackDepth:(int)depth page:(int)page {
  return [self session:session sendRequest:[NSString stringWithFormat:@"%@ -n %@ -d %d -c %d -p %d", DBGpCommandPropertyGet, fullName, depth, context, page]];
}
@end
