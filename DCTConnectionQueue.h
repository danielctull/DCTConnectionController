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
	NSMutableArray *nonMultitaskingConnectionControllers;
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



/// @name Connection Counts

/** The total amount of connection controllers queued and active. */
@property (nonatomic, readonly) NSInteger connectionCount;

/** The amount of connection controllers currently in progress. */
@property (nonatomic, readonly) NSInteger activeConnectionCount;

/// @name Accessing Connection Controllers

/** Returns all the connection controllers currently in progress and queued. */
@property (nonatomic, readonly) NSArray *connectionControllers;

/** Returns all the connection controllers currently in progress. */
@property (nonatomic, readonly) NSArray *activeConnectionControllers;

/** Returns all the connection controllers currently queued. */
@property (nonatomic, readonly) NSArray *queuedConnectionControllers;

/// @name Managing Connection Controllers

/**
 Add a connection controller to the queue. This method causes the connection queue to
 find the next connection and run it.
 
 @param connectionController The connection controller to add to the queue.
 */
- (DCTConnectionController *)addConnectionController:(DCTConnectionController *)connectionController;

/**
 Remove the given connection controller from the queue.
 
 @param connectionController The connection controller to remove.
 */
- (void)removeConnectionController:(DCTConnectionController *)connectionController;

/** Requeues a connection controller.
 
 This will stop the url connection in progress for the given connection controller and 
 reset its internals back to before it started connecting.
 
 @param connectionController The connection controller to requeue.
 */
- (void)requeueConnectionController:(DCTConnectionController *)connectionController;

/// @name External Connection Counting

/** Increments the external conneciton count.
 */
- (void)incrementExternalConnectionCount;

/** Decrements the external conneciton count */
- (void)decrementExternalConnectionCount;

@end
