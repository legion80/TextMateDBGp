//
//  TDDebugSession.h
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

@class GCDAsyncSocket;
@class TDBookmark;
@class TDNetworkController;
@class TDPlaceholderVariable;

typedef enum {
  WaitingForContact,
  SettingInitialParameters,
  Running,
  Paused,
  LoadingVariables,
  Stopped,
} SessionState;

@interface TDDebugSession : NSObject {
  GCDAsyncSocket* _socket;
  TDNetworkController* _controller; // weak
  SessionState _state;
  long _waitForTag;
  
  NSMutableArray* _stackFrames;
  NSString* _lastStatus;
  NSString* _lastReason;
  NSString* _lastCommand;
  int _lastTransactionId; // last requested transaction id, not the read transaction.
  NSMutableDictionary* _transactionData;
}

- (id)initWithSocket:(GCDAsyncSocket*)socket controller:(TDNetworkController*)networkController;

@property (nonatomic,readonly) GCDAsyncSocket* socket;
@property (nonatomic,assign,readonly) SessionState state;
@property (nonatomic,readonly) NSArray* stackFrames;

@property (nonatomic,retain,readonly) NSString* lastStatus;
@property (nonatomic,retain,readonly) NSString* lastReason;
@property (nonatomic,retain,readonly) NSString* lastCommand;

- (void)startHandshake;
- (void)didReadData:(NSXMLDocument*)data withTag:(long)tag;
- (void)close;

- (void)continueDebugSession;
- (void)stepIn;
- (void)stepOut;
- (void)stepOver;

- (void)loadVariablesAtStackLevel:(int)level;
- (void)updatePendingVariable:(TDPlaceholderVariable*)pendingVariable;
- (void)addBookmark:(TDBookmark*)bookmark;
- (void)removeBookmark:(TDBookmark*)bookmark;
@end
