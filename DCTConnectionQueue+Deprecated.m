//
//  DCTConnectionQueue+Deprecated.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 07.12.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueue+Deprecated.h"
#import "DCTConnectionGroup.h"
#import "DCTConnectionController.h"

@implementation DCTConnectionQueue (Deprecated)

- (void)addConnectionController:(DCTConnectionController *)connectionController {
	[connectionController connectOnQueue:self];
}

- (void)removeConnectionController:(DCTConnectionController *)connectionController {
	[connectionController cancel];
}

- (void)requeueConnectionController:(DCTConnectionController *)connectionController {
	[connectionController requeue];
}

- (void)addConnectionGroup:(DCTConnectionGroup *)connectionGroup {
	[connectionGroup connectOnQueue:self];
}

@end
