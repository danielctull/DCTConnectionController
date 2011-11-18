//
//  DCTConnectionGroup.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 18.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionGroup.h"
#import "DCTConnectionQueue+Singleton.h"
#import "DCTConnectionController+UsefulChecks.h"

typedef DCTConnectionController * (^DCTInternalConnectionControllerWeakBlock) ();

@implementation DCTConnectionGroup {
	__strong NSMutableArray *connectionControllers;
	__strong NSMutableArray *finishBlocks;
}

- (void)addFinishHandler:(DCTConnectionControllerFinishBlock)finishBlock {
	
	if (!finishBlocks) finishBlocks = [[NSMutableArray alloc] initWithCapacity:1];
	
	[finishBlocks addObject:[finishBlock copy]];
}

- (void)addConnectionController:(DCTConnectionController *)connectionController {
	
	if (!connectionControllers) connectionControllers = [[NSMutableArray alloc] initWithCapacity:1];
	
	__dct_weak DCTConnectionController *cc = connectionController;
	
	[connectionControllers addObject:connectionController];
	
	[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		if (cc.ended) [connectionControllers removeObject:cc];
		
		if ([connectionControllers count] > 0) return;
		
		[finishBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			DCTConnectionControllerFinishBlock block = obj;
			block();
		}];
	}];
}
			
- (void)connect {
	[self connectOnQueue:[DCTConnectionQueue sharedConnectionQueue]];
}

- (void)connectOnQueue:(DCTConnectionQueue *)queue {
	[connectionControllers enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
		DCTInternalConnectionControllerWeakBlock block = object;
		DCTConnectionController *cc = block();
		[cc connectOnQueue:queue];
	}];
}

@end
