//
//  DCTConnectionGroup.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 18.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTConnectionController.h"

typedef void (^DCTConnectionGroupEndedBlock) (NSArray *finishedConnectionControllers, NSArray *failedConnectionControllers, NSArray *cancelledConnectionControllers);

/** DCTConnectionGroup is experiemental code at the moment.
 
 */
@interface DCTConnectionGroup : NSObject

@property (nonatomic, readonly) NSArray *connectionControllers;

- (void)addConnectionController:(DCTConnectionController *)connectionController;

- (void)addEndedHandler:(DCTConnectionGroupEndedBlock)endedBlock;

- (void)connectOnQueue:(DCTConnectionQueue *)queue;

@end
