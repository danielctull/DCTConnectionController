/*
 DCTConnectionQueue.h
 DCTConnectionController
 
 Created by Daniel Tull on 9.6.2010.
 
 
 
 Copyright (c) 2010 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import "DCTConnectionController.h"

extern NSString *const DCTConnectionQueueConnectionCountChangedNotification;
extern NSString *const DCTConnectionQueueActiveConnectionCountChangedNotification;

extern NSString *const DCTConnectionQueueActiveConnectionCountIncreasedNotification;
extern NSString *const DCTConnectionQueueActiveConnectionCountDecreasedNotification;

@interface DCTConnectionQueue : NSObject

/// @name Queue Settings

/** The maximum number of simultaneous connections allowed at once. */
@property (nonatomic, assign) NSUInteger maxConnections;

/// @name Managing the queue

/** Stops the conneciton queue. */
- (void)stop;

/** Starts the conneciton queue. */
- (void)start;


/// @name Accessing Connection Controllers

/** Returns all the connection controllers currently in progress and queued. */
@property (nonatomic, readonly) NSArray *connectionControllers;

/** Returns all the connection controllers currently in progress. */
@property (nonatomic, readonly) NSArray *activeConnectionControllers;

/** Returns all the connection controllers currently queued. */
@property (nonatomic, readonly) NSArray *queuedConnectionControllers;

/** The priority threshold to archive connections at. This will archive connections on 
 this queue with a priority of this value or higher and resume them on relaunch.
 
 Default value is DCTConnectionControllerPriorityVeryHigh.
 */
@property (nonatomic, assign) DCTConnectionControllerPriority archivePriorityThreshold;

#ifdef TARGET_OS_IPHONE
/** The priority threshold to run a connection in the background. This will run connections
 on this queue with a priority of this value or higher when the app moves to the background.
 
 For instance, setting this to DCTConnectionControllerPriorityVeryLow will cause every 
 connection controller to continue to run when the app is put in the background.
 
 Default value is DCTConnectionControllerPriorityHigh.
 
 */
@property (nonatomic, assign) DCTConnectionControllerPriority backgroundPriorityThreshold;
#endif

/**
 Add a connection controller to the queue. This method causes the connection queue to
 find the next connection and run it.
 
 @param connectionController The connection controller to add to the queue.
 */
- (void)addConnectionController:(DCTConnectionController *)connectionController;

/**
 Remove the given connection controller from the queue.
 
 @param connectionController The connection controller to remove.
 */
- (void)removeConnectionController:(DCTConnectionController *)connectionController;

@end

#import "DCTConnectionQueue+Deprecated.h"
