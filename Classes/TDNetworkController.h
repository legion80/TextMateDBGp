//
//  TDNetworkController.h
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

#import "GCDAsyncSocket.h"

@class TDDebugSession;
@class TDProject;
@interface TDNetworkController : NSObject <GCDAsyncSocketDelegate> {
  GCDAsyncSocket* _socket;
  dispatch_queue_t _dispatchQueue;
  NSMutableArray* _openSessions;
  TDProject* _project; //weak
  BOOL _bookmarksEnabled;
  BOOL _firstLineBreak;
}

@property (nonatomic,readonly) GCDAsyncSocket* socket;
@property (nonatomic,assign) TDProject* project;
@property (nonatomic,readonly) TDDebugSession* currentOpenSession;
@property (nonatomic,assign) BOOL bookmarksEnabled;
@property (nonatomic,assign) BOOL firstLineBreak;

- (void)startListening;
- (void)stopListening;
- (long)session:(TDDebugSession*)session readResponseWithTag:(long)tag;

- (long)session:(TDDebugSession*)session sendRequest:(NSString*)command;
- (long)session:(TDDebugSession*)session featureGet:(NSString*)featureName;
- (long)session:(TDDebugSession*)session featureSet:(NSString*)featureName value:(NSString*)value;

- (void)sessionRun:(TDDebugSession*)session;
- (void)sessionStepIn:(TDDebugSession*)session;
- (void)sessionStepOut:(TDDebugSession*)session;
- (void)sessionStepOver:(TDDebugSession*)session;
- (void)sessionStop:(TDDebugSession*)session;
///detach

// 6 types of breakpoints (line, call, return, exception, conditional, watch
- (long)session:(TDDebugSession*)session setLineBreakpointInFile:(NSString*)filePath lineNumber:(long)lineNumber temporary:(BOOL)temporary enabled:(BOOL)isEnabled;
//- (void)session:(MDDebugSession*)session getBreakpoint
- (void)session:(TDDebugSession*)session updateBreakpointId:(long)breakpointId enabled:(BOOL)isEnabled;
- (void)session:(TDDebugSession*)session removeBreakpointId:(long)breakpointId;
//- (void)session:(MDDebugSession*)session listBreakpoints

- (void)sessionStackDepth:(TDDebugSession*)session;
- (void)sessionStackGet:(TDDebugSession*)session;
- (void)session:(TDDebugSession*)session stackGet:(int)depth;
- (long)session:(TDDebugSession*)session contextNamesAtDepth:(int)depth;
- (long)session:(TDDebugSession*)session contextGet:(int)context stackDepth:(int)depth;
- (long)session:(TDDebugSession*)session contextGetStackDepth:(int)depth;

- (long)session:(TDDebugSession*)session propertyGet:(NSString*)fullName context:(int)context stackDepth:(int)depth page:(int)page;
@end
