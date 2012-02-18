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

/// @name Deprecated

/** Requeues a connection controller.
 
 This will stop the url connection in progress for the given connection controller and 
 reset its internals back to before it started connecting.
 
 @param connectionController The connection controller to requeue.
 */
- (void)requeueConnectionController:(DCTConnectionController *)connectionController;

/// @name Managing Connection Groups

/** The total amount of connection controllers queued and active. */
@property (nonatomic, readonly) NSInteger connectionCount;

/** The amount of connection controllers currently in progress. */
@property (nonatomic, readonly) NSInteger activeConnectionCount;

/** The amount of connection controllers currently queued. */
@property (nonatomic, readonly) NSInteger queuedConnectionCount;

@end
