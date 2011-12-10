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

/** Adds a response block.
 
 DCTConnectionControllerResponseBlock is defined as such:
 
 `typedef void (^DCTConnectionControllerResponseBlock) (NSURLResponse *response);`
 
 @param responseHandler The response block to add.
 */
- (void)addResponseHandler:(DCTConnectionControllerResponseBlock)responseHandler;

/** Adds a finish block.
 
 DCTConnectionControllerFinishBlock is defined as such:
 
 `typedef void (^DCTConnectionControllerFinishBlock) ();`
 
 @param finishHandler The completion block to add.
 */
- (void)addFinishHandler:(DCTConnectionControllerFinishBlock)finishHandler;



/** Adds a failure block.
 
 DCTConnectionControllerFailureBlock is defined as such:
 
 `typedef void (^DCTConnectionControllerFailureBlock) (NSError *error);`
 
 @param failureHandler The failure block to add.
 */
- (void)addFailureHandler:(DCTConnectionControllerFailureBlock)failureHandler;

/** Adds a completion block.
 
 DCTConnectionControllerCancelationBlock is defined as such:
 
 `typedef void (^DCTConnectionControllerCancelationBlock) ();`
 
 @param cancelationHandler The cancelation block to add.
 */
- (void)addCancelationHandler:(DCTConnectionControllerCancelationBlock)cancelationHandler;



@end
