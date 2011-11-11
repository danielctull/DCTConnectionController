//
//  DCTConnectionController+Depricated.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 11.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"

typedef void (^DCTConnectionControllerFinishBlock) ();

@interface DCTConnectionController (Depricated)

/// @name Depricated

/** Adds a completion block.
 
 DCTConnectionControllerCompletionBlock is defined as such:
 
 `typedef void (^DCTConnectionControllerFinishBlock) ();`
 
 THIS METHOD IS DEPRICATED IN 2.1
 
 @see addCompletionHandler:
 
 @param finishHandler The completion block to add.
 */
- (void)addFinishHandler:(DCTConnectionControllerFinishBlock)finishHandler;

@end
