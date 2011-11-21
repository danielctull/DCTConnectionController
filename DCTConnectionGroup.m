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
#import "DCTConnectionController+UsefulChecks.h"
#import "DCTConnectionQueue.h"

@interface DCTConnectionGroup ()
@property (nonatomic, strong, readonly) NSMutableArray *dctInternal_connectionControllers;
@property (nonatomic, strong, readonly) NSMutableArray *dctInternal_completionBlocks;

- (void)dctInternal_checkControllers;

@end

@implementation DCTConnectionGroup

@synthesize dctInternal_connectionControllers;
@synthesize dctInternal_completionBlocks;

- (NSArray *)connectionControllers {
	return [self.dctInternal_connectionControllers copy];
}

- (void)addCompletionHandler:(DCTConnectionGroupCompletionBlock)completionBlock {
	[self.dctInternal_completionBlocks addObject:[completionBlock copy]];
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
	[self.dctInternal_completionBlocks enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
		DCTConnectionGroupCompletionBlock block = object;
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

- (NSMutableArray *)dctInternal_completionBlocks {
	
	if (!dctInternal_completionBlocks) dctInternal_completionBlocks = [NSMutableArray new];
	
	return dctInternal_completionBlocks;	
}

@end
