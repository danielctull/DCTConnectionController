//
//  DCTConnectionController+UsefulChecks.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 06.08.2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"

@interface DCTConnectionController (UsefulChecks)

/** Returns yes if the receiver has received a response from the connection.
 */
@property (nonatomic, readonly) BOOL didReceiveResponse;

/** Returns yes if the receiver has been successful.
 */
@property (nonatomic, readonly, getter = isFinished) BOOL finished;

/** Returns yes if the receiver failed.
 */
@property (nonatomic, readonly, getter = isFailed) BOOL failed;

/** Returns yes if the receiver has been cancelled.
 */
@property (nonatomic, readonly, getter = isCancelled) BOOL cancelled;

/** Returns yes if the receiver is active.
 */
@property (nonatomic, readonly, getter = isActive) BOOL active;

/** Returns yes if the receiver has ended, either successfully or not.
 */
@property (nonatomic, readonly, getter = isEnded) BOOL ended;

/** Returns yes if the receiver has started its connection.
 */
@property (nonatomic, readonly, getter = isStarted) BOOL started;
@end
