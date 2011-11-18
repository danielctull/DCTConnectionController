//
//  DCTConnectionGroup.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 18.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionGroup.h"
#import "DCTConnectionController+UsefulChecks.h"
#import "DCTConnectionQueue.h"

typedef DCTConnectionController * (^DCTInternalConnectionControllerWeakBlock) ();

@interface DCTConnectionGroup ()
@property (nonatomic, strong, readonly) NSMutableArray *dctInternal_connectionControllers;
@property (nonatomic, strong, readonly) NSMutableArray *dctInternal_endedBlocks;

- (void)dctInternal_checkControllers;

@end

@implementation DCTConnectionGroup

@synthesize dctInternal_connectionControllers;
@synthesize dctInternal_endedBlocks;

- (NSArray *)connectionControllers {
	return [self.dctInternal_connectionControllers copy];
}

- (void)addEndedHandler:(DCTConnectionGroupEndedBlock)endedBlock {
	[self.dctInternal_endedBlocks addObject:[endedBlock copy]];
}

- (void)addConnectionController:(DCTConnectionController *)connectionController {
	
	[self.dctInternal_connectionControllers addObject:connectionController];
	
	__dct_weak DCTConnectionGroup *weakself = self;
	
	[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		[weakself dctInternal_checkControllers];
	}];
}

- (void)dctInternal_checkControllers {
	
	for (DCTConnectionController *cc in self.dctInternal_connectionControllers)
		if (!cc.ended)
			return;
		
	NSMutableArray *failedCCs = [[NSMutableArray alloc] initWithCapacity:[self.dctInternal_connectionControllers count]];
	NSMutableArray *finishedCCs = [[NSMutableArray alloc] initWithCapacity:[self.dctInternal_connectionControllers count]];
	NSMutableArray *cancelledCCs = [[NSMutableArray alloc] initWithCapacity:[self.dctInternal_connectionControllers count]];
	
	for (DCTConnectionController *cc in self.dctInternal_connectionControllers) {
		
		if (cc.status == DCTConnectionControllerStatusFinished)
			[finishedCCs addObject:cc];
		
		else if (cc.status == DCTConnectionControllerStatusFailed)
			[failedCCs addObject:cc];
		
		else if (cc.status == DCTConnectionControllerStatusCancelled)
			[cancelledCCs addObject:cc];
		
	}
	
	//typedef void (^DCTConnectionGroupEndedBlock) (NSArray *finishedConnectionControllers, NSArray *failedConnectionControllers, NSArray *cancelledConnectionControllers);
	[self.dctInternal_endedBlocks enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
		DCTConnectionGroupEndedBlock block = object;
		block(finishedCCs, failedCCs, cancelledCCs);
	}];
}
					 
- (void)connectOnQueue:(DCTConnectionQueue *)queue {
	[queue addConnectionGroup:self];
}

#pragma mark - Internal

- (NSMutableArray *)dctInternal_connectionControllers {
	
	if (!dctInternal_connectionControllers) dctInternal_connectionControllers = [NSMutableArray new];
	
	return dctInternal_connectionControllers;	
}

- (NSMutableArray *)dctInternal_endedBlocks {
	
	if (!dctInternal_endedBlocks) dctInternal_endedBlocks = [NSMutableArray new];
	
	return dctInternal_endedBlocks;	
}

@end
