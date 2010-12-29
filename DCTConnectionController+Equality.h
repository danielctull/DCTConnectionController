//
//  DCTConnectionController+Equality.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09/11/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTConnectionController.h"

@interface DCTConnectionController (Equality)

/// @name Checking for Equality

/** Determines whether the given connection controller is equal to the receiver. 
 
 Connection controllers are determined equal by checking the URL , the type and
 their properties for equality.
 
 @param connectionController The connection controller to check equality with.
 @return YES if the connection controllers are equal.
 */
- (BOOL)isEqualToConnectionController:(DCTConnectionController *)connectionController;
@end
