//
//  TDDebugSession.m
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

#import "TDDebugSession.h"

#import "GCDAsyncSocket.h"
#import "TDBookmark.h"
#import "TDNetworkController.h"
#import "TDPlaceholderVariable.h"
#import "TDProject.h"
#import "TDStackContext.h"
#import "TDStackFrame.h"
#import "TDStackVariable.h"

@interface TDDebugSession ()
@property (nonatomic,assign,readwrite) SessionState state;
@property (nonatomic,retain,readwrite) NSString* lastStatus;
@property (nonatomic,retain,readwrite) NSString* lastReason;
@property (nonatomic,retain,readwrite) NSString* lastCommand;

- (void)processResponse:(NSXMLDocument*)xmlResponse;
@end

@implementation TDDebugSession
@synthesize socket = _socket;
@synthesize state = _state;
@synthesize stackFrames = _stackFrames;
@synthesize lastStatus = _lastStatus;
@synthesize lastReason = _lastReason;
@synthesize lastCommand = _lastCommand;

- (id)initWithSocket:(GCDAsyncSocket *)socket controller:(TDNetworkController *)networkController {
  if (!(self = [super init]))
    return nil;
  
  _socket = [socket retain];
  _controller = networkController;
  _state = WaitingForContact;
  _stackFrames = [[NSMutableArray alloc] init];
  _transactionData = [[NSMutableDictionary alloc] init];
  return self;
}

- (void)dealloc {
  [_socket setDelegate:nil];
  if ([_socket isConnected])
    [_socket disconnect];
  [_socket release];
  
  [_stackFrames release];
  self.lastStatus = nil;
  self.lastReason = nil;
  self.lastCommand = nil;
  [_transactionData release];
  [super dealloc];
}

- (void)startHandshake {
  self.state = SettingInitialParameters;
  [_controller session:self featureGet:@"max_children"];
  [_controller session:self featureGet:@"max_data"];
  _waitForTag = [_controller session:self featureGet:@"max_depth"];
  for (NSDictionary* fileItem in _controller.project.bookmarkKeys) {
    for (TDBookmark* bookmark in [_controller.project bookmarksForFileItem:fileItem]) {
      long lineNumber = bookmark.lineNumber + 1;
      _waitForTag = [_controller session:self setLineBreakpointInFile:[NSString stringWithFormat:@"file:/%@", bookmark.source] lineNumber:lineNumber temporary:NO enabled:YES];
      [_transactionData setObject:bookmark forKey:[NSNumber numberWithInt:_waitForTag]];
    }
  }
}

- (void)close {
  [_controller sessionStop:self];
}

- (void)processResponse:(NSXMLDocument*)xmlResponse {
  NSXMLElement* rootElement = [xmlResponse rootElement];
  if ([rootElement attributeForName:@"status"])
    self.lastStatus = [[rootElement attributeForName:@"status"] stringValue];
  if ([rootElement attributeForName:@"reason"])
    self.lastReason = [[rootElement attributeForName:@"reason"] stringValue];
  if ([rootElement attributeForName:@"command"])
    self.lastCommand = [[rootElement attributeForName:@"command"] stringValue];
  _lastTransactionId = [[[rootElement attributeForName:@"transaction_id"] stringValue] intValue];
}

- (void)didReadData:(NSXMLDocument *)xmlResponse withTag:(long)tag {
  [self processResponse:xmlResponse];
  if ([_lastCommand isEqualToString:DBGpCommandStop] || [_lastStatus isEqualToString:DBGpStatusStopping]) {
    self.state = Stopped;
  }
  else if ([_lastCommand isEqualToString:DBGpCommandBreakpointSet]) {
    NSNumber* transactionId = [NSNumber numberWithInt:_lastTransactionId];
    TDBookmark* bookmark = [_transactionData objectForKey:transactionId];
    /// Always override the bookmark ID because xdebug increments the #s.
    bookmark.bookmarkId = [[[[xmlResponse rootElement] attributeForName:@"id"] stringValue] intValue];
    [_transactionData removeObjectForKey:transactionId];
  }
  
  switch (self.state) {
    case WaitingForContact:
      if ((tag & TAG_MASK) == TAG_INITIAL_CONNECTION)
        [self startHandshake];
      break;
    case SettingInitialParameters:
      if (_lastTransactionId == _waitForTag) {
        self.state = Running;
        if (_controller.firstLineBreak)
          [_controller sessionStepIn:self];
        else
          [_controller sessionRun:self];
      }
      break;
    case Running: {
      if ([_lastStatus isEqualToString:DBGpStatusBreak]) {
        self.state = Paused;
        [_controller sessionStackGet:self];
      }
      break;
    }
    case Paused: {
      if ([_lastCommand isEqualToString:DBGpCommandStackGet]) {
        [_stackFrames removeAllObjects];
        for (NSXMLElement* frame in [[xmlResponse rootElement] children]) {
          TDStackFrame* sf = [[TDStackFrame alloc] initWithXMLElement:frame];
          [_stackFrames addObject:sf];
          [sf release];
        }
        dispatch_async(dispatch_get_main_queue(), ^() {
          [[NSNotificationCenter defaultCenter] postNotificationName:TDDebugSessionDidBreakNotification object:self];
        });
      }
      else if ([_lastCommand isEqualToString:DBGpCommandPropertyGet]) {
        NSNumber* lastTransactionId = [NSNumber numberWithInt:_lastTransactionId];
        TDPlaceholderVariable* placeholder = [_transactionData objectForKey:lastTransactionId];
        [placeholder.stackContext.stackFrame parseProperties:xmlResponse forVariable:placeholder.stackVariable];
        dispatch_async(dispatch_get_main_queue(), ^() {
          [[NSNotificationCenter defaultCenter] postNotificationName:TDDebugSessionDidUpdateVariableNotification object:placeholder.stackVariable];
        });
        
        [_transactionData removeObjectForKey:lastTransactionId];
      }
      break;
    }
    case LoadingVariables: {
      if ([_lastCommand isEqualToString:DBGpCommandContextNames]) {
        NSNumber* lastTransactionId = [NSNumber numberWithInt:_lastTransactionId];
        TDStackFrame* frame = [_transactionData objectForKey:lastTransactionId];
        [frame parseContexts:[[xmlResponse rootElement] children]];
        
        for (int contextId = 0; contextId < [frame contextCount]; ++contextId) {
          _waitForTag = [_controller session:self contextGet:contextId stackDepth:[frame stackLevel]];
          [_transactionData setObject:frame forKey:[NSNumber numberWithInt:_waitForTag]];
        }
        
        [_transactionData removeObjectForKey:lastTransactionId];
      }
      else if ([_lastCommand isEqualToString:DBGpCommandContextGet]) {
        NSNumber* lastTransactionId = [NSNumber numberWithInt:_lastTransactionId];
        TDStackFrame* frame = [_transactionData objectForKey:lastTransactionId];
        [frame parseVariables:xmlResponse forContext:[[[[xmlResponse rootElement] attributeForName:@"context"] stringValue] intValue]];
        
        if (_waitForTag == _lastTransactionId) {
          dispatch_async(dispatch_get_main_queue(), ^() {
            [[NSNotificationCenter defaultCenter] postNotificationName:TDDebugSessionDidLoadVariablesNotification object:self];
          });
          self.state = Paused;
        }
        
        [_transactionData removeObjectForKey:lastTransactionId];
      }
      break;
    }
    case Stopped: {
      [_socket disconnect];
      
      [_stackFrames removeAllObjects];
      dispatch_async(dispatch_get_main_queue(), ^() {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDDebugSessionDidStopNotification object:self];
      });
      break;
    }
  }
}

- (void)continueDebugSession {
  [_controller sessionRun:self];
  self.state = Running;
}
- (void)stepIn {
  [_controller sessionStepIn:self];
  self.state = Running;
}
- (void)stepOut {
  [_controller sessionStepOut:self];
  self.state = Running;
}
- (void)stepOver {
  [_controller sessionStepOver:self];
  self.state = Running;
}
- (void)loadVariablesAtStackLevel:(int)level {
  if ([_stackFrames count] < level)
    return;
  TDStackFrame* stackFrame = [_stackFrames objectAtIndex:level];
  if ([[stackFrame contextWithId:CONTEXT_LOCAL] variablesLoaded]) {
    dispatch_async(dispatch_get_main_queue(), ^() {
      [[NSNotificationCenter defaultCenter] postNotificationName:TDDebugSessionDidLoadVariablesNotification object:self];
    });
    return;
  }
  
  self.state = LoadingVariables;
  int transactionId = [_controller session:self contextNamesAtDepth:level];
  [_transactionData setObject:stackFrame
                       forKey:[NSNumber numberWithInt:transactionId]];
}
- (void)updatePendingVariable:(TDPlaceholderVariable*)pendingVariable {
  if (pendingVariable.requestMade)
    return;
  
  pendingVariable.requestMade = YES;
  int transactionId = [_controller session:self
                               propertyGet:pendingVariable.stackVariable.fullName
                                   context:pendingVariable.stackContext.contextId
                                stackDepth:pendingVariable.stackContext.stackFrame.stackLevel
                                      page:pendingVariable.pageToLoad];
  [_transactionData setObject:pendingVariable
                       forKey:[NSNumber numberWithInt:transactionId]];
}
- (void)addBookmark:(TDBookmark *)bookmark {
  NSAssert1(![bookmark bookmarkIdDetermined], @"Bookmark not determined: %@", bookmark);
  int transactionId = [_controller session:self setLineBreakpointInFile:[NSString stringWithFormat:@"file:/%@", bookmark.source] lineNumber:bookmark.lineNumber + 1 temporary:NO enabled:YES];
  [_transactionData setObject:bookmark forKey:[NSNumber numberWithInt:transactionId]];
}
- (void)removeBookmark:(TDBookmark *)bookmark {
  NSAssert1([bookmark bookmarkIdDetermined], @"Bookmark not determined: %@", bookmark);
  [_controller session:self removeBreakpointId:bookmark.bookmarkId];
}
@end
