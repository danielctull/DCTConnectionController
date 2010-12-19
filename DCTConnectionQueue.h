//
//  DTNetworkQueue.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTConnectionController.h"

extern NSString *const DCTConnectionQueueConnectionCountChangedNotification;
extern NSString *const DCTConnectionQueueActiveConnectionCountChangedNotification;

@interface DCTConnectionQueue : NSObject {
    NSMutableArray *activeConnections;
	NSMutableArray *queuedConnections;
	BOOL active;
	NSInteger externalConnectionCount;
	NSInteger connectionCount;
	
	NSArray *externalConnectionCountKeys;
	
	// Needed for multitasking on the iPhone, which is added as a category.	
	NSMutableArray *nonMultitaskingConnections;
	NSUInteger backgroundTaskIdentifier;
	BOOL inBackground;
	BOOL multitaskEnabled;
}

/// @name Queue Settings

/** The maximum number of simultaneous connections allowed at once. */
@property (nonatomic, assign) NSInteger maxConnections;

/// @name Managing the queue

/** Stops the conneciton queue. */
- (void)stop;

/** Pauses the conneciton queue. */
//- (void)pause;

/** Starts the conneciton queue. */
- (void)start;


/// @name Managing Connection Controllers

/**
 Add a connection controller to the queue. This method causes the connection queue to
 find the next connection and run it.
 */
- (DCTConnectionController *)addConnectionController:(DCTConnectionController *)connectionController;

/**
 
 */
- (void)removeConnectionController:(DCTConnectionController *)connectionController;

/** Requeues a connection controller.
 
 This will stop the url connection in progress for the given connection controller and 
 reset its internals back to before it started connecting.
 */
- (void)requeueConnectionController:(DCTConnectionController *)connectionController;

/// @name Accessing Connection Controllers

/** The total amount of connection controllers queued and active. */
@property (nonatomic, readonly) NSInteger connectionCount;

/** The amount of connection controllers currently in progress. */
@property (nonatomic, readonly) NSInteger activeConnectionCount;

/** Returns all the connection controllers currently in progress and queued. */
@property (nonatomic, readonly) NSArray *connectionControllers;

/** Returns all the connection controllers currently in progress. */
@property (nonatomic, readonly) NSArray *activeConnectionControllers;

/** Returns all the connection controllers currently queued. */
@property (nonatomic, readonly) NSArray *queuedConnectionControllers;

/// @name External Connection Counting

/** Increments the external conneciton count */
- (void)incrementExternalConnectionCount;

/** Decrements the external conneciton count */
- (void)decrementExternalConnectionCount;

@end
