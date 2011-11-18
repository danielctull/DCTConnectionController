//
//  DCTConnectionGroup.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 18.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTConnectionController.h"


/** DCTConnectionGroup is experiemental code at the moment.
 
 */
@interface DCTConnectionGroup : NSObject

- (void)addConnectionController:(DCTConnectionController *)connectionController;
- (void)addFinishHandler:(DCTConnectionControllerFinishBlock)finishBlock;
- (void)connect;
- (void)connectOnQueue:(DCTConnectionQueue *)queue;

@end
