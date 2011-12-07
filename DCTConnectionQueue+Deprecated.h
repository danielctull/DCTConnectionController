//
//  DCTConnectionQueue+Deprecated.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 07.12.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueue.h"
@class DCTConnectionGroup;
@class DCTConnectionController;

@interface DCTConnectionQueue (Deprecated)

/// @name Managing Connection Controllers

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

/** Requeues a connection controller.
 
 This will stop the url connection in progress for the given connection controller and 
 reset its internals back to before it started connecting.
 
 @param connectionController The connection controller to requeue.
 */
- (void)requeueConnectionController:(DCTConnectionController *)connectionController;

/// @name Managing Connection Groups

- (void)addConnectionGroup:(DCTConnectionGroup *)connectionGroup;

@end
