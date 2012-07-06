/*
 DCTConnectionGroup.m
 DCTConnectionController
 
 Created by Daniel Tull on 18.11.2011.
 
 
 
 Copyright (c) 2011 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DCTConnectionGroup.h"
#import "DCTConnectionQueue.h"
#import <objc/runtime.h>

@interface DCTConnectionQueue (DCTConnectionGroupInternal)
- (void)dctConnectionGroupInternal_addConnectionGroup:(DCTConnectionGroup *)connectionGroup;
- (NSMutableArray *)dctConnectionGroupInternal_groups;
@end

@interface DCTConnectionGroup ()
@property (nonatomic, readonly) NSMutableArray *dctInternal_connectionControllers;
@property (nonatomic, readonly) NSMutableArray *dctInternal_completionBlocks;

- (void)dctInternal_checkControllers;
- (void)dctInternal_callCompletionBlocksWithFinishedConnectionControllers:(NSArray *)finishedCCs
											  failedConnectionControllers:(NSArray *)failedCCs
										   cancelledConnectionControllers:(NSArray *)cancelledCCs;
@end

@implementation DCTConnectionGroup {
	__strong NSMutableArray *dctInternal_connectionControllers;
	__strong NSMutableArray *dctInternal_completionBlocks;
	BOOL hasStarted;
	BOOL hasFinished;
	__weak DCTConnectionQueue *queue;
}

- (NSArray *)connectionControllers {
	return [self.dctInternal_connectionControllers copy];
}

- (void)addCompletionHandler:(DCTConnectionGroupCompletionBlock)completionBlock {
	[self.dctInternal_completionBlocks addObject:[completionBlock copy]];
}

- (void)addConnectionController:(DCTConnectionController *)connectionController {
	
	[self.dctInternal_connectionControllers addObject:connectionController];
	
	__unsafe_unretained DCTConnectionGroup *weakself = self;
	
	[connectionController addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
		[weakself dctInternal_checkControllers];
	}];
	
	if (hasStarted) [connectionController connectOnQueue:queue];
}

- (void)connectOnQueue:(DCTConnectionQueue *)q {
	
	queue = q;
	
	if ([self.connectionControllers count] == 0) {
		[self dctInternal_callCompletionBlocksWithFinishedConnectionControllers:nil
													failedConnectionControllers:nil
												 cancelledConnectionControllers:nil];
		return;
	}
	
	[queue dctConnectionGroupInternal_addConnectionGroup:self];
}

#pragma mark - Internal

- (void)dctInternal_checkControllers {
	
	for (DCTConnectionController *cc in self.dctInternal_connectionControllers)
		if (cc.status <= DCTConnectionControllerStatusResponded)
			return;
	
	hasFinished = YES;
	
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
	
	[self dctInternal_callCompletionBlocksWithFinishedConnectionControllers:[finishedCCs copy]
												failedConnectionControllers:[failedCCs copy]
											 cancelledConnectionControllers:[cancelledCCs copy]];
}

- (void)dctInternal_callCompletionBlocksWithFinishedConnectionControllers:(NSArray *)finishedCCs
											  failedConnectionControllers:(NSArray *)failedCCs
										   cancelledConnectionControllers:(NSArray *)cancelledCCs {
	
	//typedef void (^DCTConnectionGroupEndedBlock) (NSArray *finishedConnectionControllers, NSArray *failedConnectionControllers, NSArray *cancelledConnectionControllers);
	[self.dctInternal_completionBlocks enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
		DCTConnectionGroupCompletionBlock block = object;
		block(finishedCCs, failedCCs, cancelledCCs);
	}];
}

- (NSMutableArray *)dctInternal_connectionControllers {
	
	if (!dctInternal_connectionControllers) dctInternal_connectionControllers = [NSMutableArray new];
	
	return dctInternal_connectionControllers;	
}

- (NSMutableArray *)dctInternal_completionBlocks {
	
	if (!dctInternal_completionBlocks) dctInternal_completionBlocks = [NSMutableArray new];
	
	return dctInternal_completionBlocks;	
}

@end

@implementation DCTConnectionQueue (DCTConnectionGroup)

- (NSArray *)connectionGroups {
	return [self.dctConnectionGroupInternal_groups copy];
}

- (void)addConnectionGroup:(DCTConnectionGroup *)connectionGroup {
	[connectionGroup connectOnQueue:self];
}

@end

@implementation DCTConnectionQueue (DCTConnectionGroupInternal)

- (NSMutableArray *)dctConnectionGroupInternal_groups {
	
	NSMutableArray *array = objc_getAssociatedObject(self, _cmd);
	
	if (!array) {
		array = [[NSMutableArray alloc] initWithCapacity:1];
		objc_setAssociatedObject(self, _cmd, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	return array;
}

- (void)dctConnectionGroupInternal_addConnectionGroup:(DCTConnectionGroup *)connectionGroup {
	
	NSMutableArray *groups = [self dctConnectionGroupInternal_groups];
	
	[groups addObject:connectionGroup];
	
	__unsafe_unretained DCTConnectionGroup *group = connectionGroup;
	
	[connectionGroup addCompletionHandler:^(NSArray *finishedConnectionControllers, NSArray *failedConnectionControllers, NSArray *cancelledConnectionControllers) {
		[groups removeObject:group];
	}];
	
	[connectionGroup.connectionControllers enumerateObjectsUsingBlock:^(DCTConnectionController *cc, NSUInteger idx, BOOL *stop) {
		[cc connectOnQueue:self];
	}];
}

@end
