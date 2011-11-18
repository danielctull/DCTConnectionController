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
@property (nonatomic, strong, readonly) NSMutableArray *dctInternal_finishBlocks;
@property (nonatomic, strong, readonly) NSMutableArray *dctInternal_endedBlocks;
@end

@implementation DCTConnectionGroup

@synthesize dctInternal_connectionControllers;
@synthesize dctInternal_finishBlocks;
@synthesize dctInternal_endedBlocks;

- (NSArray *)connectionControllers {
	return [self.dctInternal_connectionControllers copy];
}

- (void)addFinishHandler:(DCTConnectionControllerFinishBlock)finishBlock {
	[self.dctInternal_finishBlocks addObject:[finishBlock copy]];
}

- (void)addEndedHandler:(DCTConnectionGroupEndedBlock)endedBlock {
	[self.dctInternal_endedBlocks addObject:[endedBlock copy]];
}

- (void)addConnectionController:(DCTConnectionController *)connectionController {
	
	[self.dctInternal_connectionControllers addObject:connectionController];
	
	__dct_weak DCTConnectionGroup *weakself = self;
	
	[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		
		BOOL success = YES;
		
		for (DCTConnectionController *cc in weakself.dctInternal_connectionControllers) {
			if (!cc.ended)
				return;
			
			if (!cc.finished)
				success = NO;
		}
		
		for (DCTConnectionGroupEndedBlock block in weakself.dctInternal_endedBlocks)
			block();
		
		if (!success) return;
		
		for (DCTConnectionGroupFinishBlock block in weakself.dctInternal_finishBlocks) {
			block();
		}
		
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

- (NSMutableArray *)dctInternal_finishBlocks {
	
	if (!dctInternal_finishBlocks) dctInternal_finishBlocks = [NSMutableArray new];
	
	return dctInternal_finishBlocks;	
}

- (NSMutableArray *)dctInternal_endedBlocks {
	
	if (!dctInternal_endedBlocks) dctInternal_endedBlocks = [NSMutableArray new];
	
	return dctInternal_endedBlocks;	
}

@end
