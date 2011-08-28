//
//  MDDefines.m
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

#import "MDDefines.h"

// Sidebar
NSString *const kMDSideViewLeftKey = @"MDSideViewLeft";
NSString *const kMDSideViewFrameKey = @"MDSideViewFrame";
NSString *const kMDMainViewFrameKey = @"MDMainViewFrame";
NSString *const kMDSidebarBackgroundColorActiveKey = @"MDSidebarBackgroundColorActive";
NSString *const kMDSidebarBackgroundColorIdleKey = @"MDSidebarBackgroundColorIdle";

// Network Controller notifications
NSString *const TDNetworkControllerDidAcceptNewSocketNotification = @"TDNetworkControllerDidAcceptNewSocketNotification";
NSString *const TDNetworkControllerDidDisconnectSocketNotification = @"TDNetworkControllerDidDisconnectSocketNotification";
NSString *const TDDebugSessionDidBreakNotification = @"TDDebugSessionDidBreakNotification";
NSString *const TDDebugSessionDidStopNotification = @"TDDebugSessionDidStopNotification";
NSString *const TDDebugSessionDidLoadVariablesNotification = @"TDDebugSessionDidLoadVariablesNotification";
NSString *const TDDebugSessionDidUpdateVariableNotification = @"TDDebugSessionDidUpdateVariableNotification";

NSString *const TDSidebarShowViewNotification = @"TDSidebarShowViewNotification";

// DBGp constants
NSString *const DBGpCommandBreakpointRemove = @"breakpoint_remove";
NSString *const DBGpCommandBreakpointSet = @"breakpoint_set";
NSString *const DBGpCommandBreakpointUpdate = @"breakpoint_update";
NSString *const DBGpCommandContextGet = @"context_get";
NSString *const DBGpCommandContextNames = @"context_names";
NSString *const DBGpCommandFeatureGet = @"feature_get";
NSString *const DBGpCommandFeatureSet = @"feature_set";
NSString *const DBGpCommandPropertyGet = @"property_get";
NSString *const DBGpCommandRun = @"run";
NSString *const DBGpCommandStackDepth = @"stack_depth";
NSString *const DBGpCommandStackGet = @"stack_get";
NSString *const DBGpCommandStepInto = @"step_into";
NSString *const DBGpCommandStepOut = @"step_out";
NSString *const DBGpCommandStepOver = @"step_over";
NSString *const DBGpCommandStop = @"stop";

NSString *const DBGpStatusStarting = @"starting";
NSString *const DBGpStatusStopping = @"stopping";
NSString *const DBGpStatusStopped = @"stopped";
NSString *const DBGpStatusRunning = @"running";
NSString *const DBGpStatusBreak = @"break";
NSString *const DBGpReasonOk = @"ok";
NSString *const DBGpReasonError = @"error";
NSString *const DBGpReasonAborted = @"aborted";
NSString *const DBGpReasonException = @"exception";
