//
//  MDDefines.h
//  TextMateDBGp
//
//	Copyright (c) The MissingDrawer authors.
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

#ifndef MDDEFINES
#define MDDEFINES

// Sidebar
extern NSString *const kMDSideViewLeftKey;
extern NSString *const kMDSideViewFrameKey;
extern NSString *const kMDMainViewFrameKey;
extern NSString *const kMDSidebarBackgroundColorActiveKey;
extern NSString *const kMDSidebarBackgroundColorIdleKey;

// Network controller notifications
extern NSString *const TDNetworkControllerDidAcceptNewSocketNotification;
extern NSString *const TDNetworkControllerDidDisconnectSocketNotification;
extern NSString *const TDDebugSessionDidBreakNotification;
extern NSString *const TDDebugSessionDidStopNotification;
extern NSString *const TDDebugSessionDidLoadVariablesNotification;
extern NSString *const TDDebugSessionDidUpdateVariableNotification;

// Tags for socket transactions
#define TAG_DATA_LENGTH 0
#define TAG_INITIAL_CONNECTION 1
#define TAG_WRITE 2
#define TAG_RESPONSE 3
#define TAG_MASK 0x3
#define TRANSACTION_STEP 0x4
#define NO_TRANSACTION -1

#define CONTEXT_LOCAL 0

// DBGp constants
extern NSString *const DBGpCommandBreakpointRemove;
extern NSString *const DBGpCommandBreakpointSet;
extern NSString *const DBGpCommandBreakpointUpdate;
extern NSString *const DBGpCommandContextGet;
extern NSString *const DBGpCommandContextNames;
extern NSString *const DBGpCommandFeatureGet;
extern NSString *const DBGpCommandFeatureSet;
extern NSString *const DBGpCommandPropertyGet;
extern NSString *const DBGpCommandRun;
extern NSString *const DBGpCommandStackDepth;
extern NSString *const DBGpCommandStackGet;
extern NSString *const DBGpCommandStepInto;
extern NSString *const DBGpCommandStepOut;
extern NSString *const DBGpCommandStepOver;
extern NSString *const DBGpCommandStop;

extern NSString *const DBGpStatusStarting;
extern NSString *const DBGpStatusStopping;
extern NSString *const DBGpStatusStopped;
extern NSString *const DBGpStatusRunning;
extern NSString *const DBGpStatusBreak;
extern NSString *const DBGpReasonOk;
extern NSString *const DBGpReasonError;
extern NSString *const DBGpReasonAborted;
extern NSString *const DBGpReasonException;

// Class definitions
#define OakOutlineView NSClassFromString(@"OakOutlineView")
#define OakPreferencesManager NSClassFromString(@"OakPreferencesManager")
#define OakProjectController NSClassFromString(@"OakProjectController")
#define OakTextView NSClassFromString(@"OakTextView")

// UI
#define MIN_SIDEVIEW_WIDTH 170.0
#define MAX_SIDEVIEW_WIDTH 450.0
#define SEARCH_FIELD_LEFT_PADDING 5
#define SEARCH_FIELD_RIGHT_PADDING 9

#endif
