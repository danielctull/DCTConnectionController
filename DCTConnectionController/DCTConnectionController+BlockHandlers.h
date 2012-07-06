//
//  DCTConnectionController+BlockHandlers.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 09.12.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"

@interface DCTConnectionController (BlockHandlers)

/// @name Event Blocks

/** Adds a block that is called when the connection controller receives a response.
 
 If the connection controller has already received a response, this block is called 
 straight away.
 
 @param responseHandler The response block to add.
 */
- (void)addResponseHandler:(void(^)(NSURLResponse *response))responseHandler;

/** Adds a block that is called when the connection controller successfully finishes.
 
 If the connection controller has already finished, this block is called
 straight away.
 
 @param finishHandler The completion block to add.
 */
- (void)addFinishHandler:(void(^)())finishHandler;

/** Adds a block that is called when the connection controller fails.
 
 If the connection controller has already failed, this block is called
 straight away.
 
 @param failureHandler The failure block to add.
 */
- (void)addFailureHandler:(void(^)(NSError *error))failureHandler;

/** Adds a block that is called when the connection controller is cancelled.
 
 If the connection controller has already been cancelled, this block is called
 straight away.
 
 @param cancelationHandler The cancelation block to add.
 */
- (void)addCancelationHandler:(void(^)())cancelationHandler;

@end
