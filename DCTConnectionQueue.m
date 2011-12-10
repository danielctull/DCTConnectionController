/*
 DCTConnectionQueue.m
 DCTConnectionController
 
 Created by Daniel Tull on 9.6.2010.
 
 
 
 Copyright (c) 2010 Daniel Tull. All rights reserved.
 
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

#import "DCTConnectionQueue.h"
#import "DCTConnectionController+UsefulChecks.h"
#import "DCTConnectionGroup.h"

NSComparisonResult (^compareConnections)(id obj1, id obj2) = ^(id obj1, id obj2) {
	
	if (![obj1 isKindOfClass:[DCTConnectionController class]] || ![obj2 isKindOfClass:[DCTConnectionController class]]) return (NSComparisonResult)NSOrderedSame;
	
	DCTConnectionController *con1 = (DCTConnectionController *)obj1;
	DCTConnectionController *con2 = (DCTConnectionController *)obj2;
	
	if (con1.priority > con2.priority) return (NSComparisonResult)NSOrderedDescending;
	
	if (con1.priority < con2.priority) return (NSComparisonResult)NSOrderedAscending;
	
	return (NSComparisonResult)NSOrderedSame;
};

NSString *const DCTConnectionQueueConnectionCountChangedNotification = @"DCTConnectionQueueConnectionCountChangedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountChangedNotification = @"DCTConnectionQueueActiveConnectionCountChangedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountIncreasedNotification = @"DCTConnectionQueueActiveConnectionCountIncreasedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountDecreasedNotification = @"DCTConnectionQueueActiveConnectionCountDecreasedNotification";

@interface DCTConnectionQueue ()

- (void)dctInternal_runNextConnection;
- (BOOL)dctInternal_tryToRunConnection:(DCTConnectionController *)connection;

- (DCTConnectionController *)dctInternal_nextConnection;
- (DCTConnectionController *)dctInternal_nextConnectionIterator:(DCTConnectionController *)connection;

- (void)dctInternal_dequeueAndStartConnection:(DCTConnectionController *)connectionController;


@property (nonatomic, strong) NSMutableArray *dctInternal_activeConnectionControllers;
@property (nonatomic, strong) NSMutableArray *dctInternal_queuedConnectionControllers;

@end

@implementation DCTConnectionQueue {
	BOOL active;
	BOOL addSwitch;
	dispatch_queue_t queue;
}

@synthesize maxConnections;
@synthesize dctInternal_activeConnectionControllers;
@synthesize dctInternal_queuedConnectionControllers;

static NSMutableArray *initBlocks = nil;
static NSMutableArray *deallocBlocks = nil;
static NSMutableArray *removalBlocks = nil;

+ (void)addInitBlock:(void(^)(DCTConnectionQueue *))block {
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		initBlocks = [[NSMutableArray alloc] initWithCapacity:1];
	});
	[initBlocks addObject:[block copy]];
}

+ (void)addDeallocBlock:(void(^)(DCTConnectionQueue *))block {
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		deallocBlocks = [[NSMutableArray alloc] initWithCapacity:1];
	});
	[deallocBlocks addObject:[block copy]];
}

+ (void)addRemovalBlock:(void(^)(DCTConnectionQueue *, DCTConnectionController *))block {
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		removalBlocks = [[NSMutableArray alloc] initWithCapacity:1];
	});
	[removalBlocks addObject:[block copy]];
}

+ (void)load {
	
	[self addRemovalBlock:^(DCTConnectionQueue *queue, DCTConnectionController *connectionController) {
		
		if (![queue.dctInternal_queuedConnectionControllers containsObject:connectionController]) return;
		
		[queue.dctInternal_queuedConnectionControllers removeObject:connectionController];
	}];
	
	[self addRemovalBlock:^(DCTConnectionQueue *queue, DCTConnectionController *connectionController) {
		
		if (![queue.dctInternal_activeConnectionControllers containsObject:connectionController]) return;
		
		[queue.dctInternal_activeConnectionControllers removeObject:connectionController];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountDecreasedNotification 
															object:queue];
		
		[queue dctInternal_runNextConnection];
	}];
	
	
	
	
}

#pragma mark - NSObject

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	self.dctInternal_activeConnectionControllers = [[NSMutableArray alloc] init];
	self.dctInternal_queuedConnectionControllers = [[NSMutableArray alloc] init];
	active = YES;
	self.maxConnections = 5;
	
	queue = dispatch_get_current_queue();
	
	for (void(^block)(DCTConnectionQueue *) in initBlocks)
		block(self);
	
	return self;	
}

- (void)dealloc {
	for (void(^block)(DCTConnectionQueue *) in deallocBlocks)
		block(self);
}

#pragma mark - DCTConnectionQueue

- (void)start {
	active = YES;
	[self dctInternal_runNextConnection];
}

- (void)stop {
	active = NO;
	
	[self.activeConnectionControllers makeObjectsPerformSelector:@selector(requeue)];
}

#pragma mark - DCTConnectionQueue Accessors

- (NSArray *)activeConnectionControllers {
	return [self.dctInternal_activeConnectionControllers copy];
}


- (NSArray *)queuedConnectionControllers {
	return [self.dctInternal_queuedConnectionControllers copy];
}

- (NSArray *)connectionControllers {
	return [self.dctInternal_activeConnectionControllers arrayByAddingObjectsFromArray:self.dctInternal_queuedConnectionControllers];
}

#pragma mark - Managing the Queue

- (void)addConnectionController:(DCTConnectionController *)connectionController {
	
	NSString *previousSymbol = [[NSThread callStackSymbols] objectAtIndex:1];
	SEL connectOnQueue = @selector(connectOnQueue:);
	if ([previousSymbol rangeOfString:NSStringFromSelector(connectOnQueue)].location == NSNotFound) {
		[connectionController connectOnQueue:self];
		return;
	}
		
	__dct_weak DCTConnectionController *weakConnectionController = connectionController;
	
	[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		if (weakConnectionController.ended) {
			[self removeConnectionController:weakConnectionController];
			if (active) [self dctInternal_runNextConnection];
		}
	}];
	
	[self.dctInternal_queuedConnectionControllers addObject:connectionController];
	[self.dctInternal_queuedConnectionControllers sortUsingComparator:compareConnections];
	
	if (active) [self dctInternal_runNextConnection];
}

- (void)removeConnectionController:(DCTConnectionController *)connectionController {
	
	for (void(^block)(DCTConnectionQueue *, DCTConnectionController *) in removalBlocks)
		block(self, connectionController);
}

#pragma mark - Internals

- (void)dctInternal_runNextConnection {
	
	if ([self.dctInternal_activeConnectionControllers count] >= self.maxConnections) return;
	
	if (!active) return;
	
	if ([self.dctInternal_queuedConnectionControllers count] == 0) return;
	
	// Loop through the queue and try to run the top-most connection.
	// If it can't be run (eg waiting for dependencies), run the next one down.
		
	DCTConnectionController *connection = [self dctInternal_nextConnection];
	
	if (!connection) return;
	
	[self dctInternal_dequeueAndStartConnection:connection];
	
	// In the case that connections are added but the queue is not active, such as
	// returning from background in multitasking, we should repeatedly call this method.
	// It will return out when the max connections has been hit or when there are 
	// no more connections to run.
	[self dctInternal_runNextConnection];
}

- (DCTConnectionController *)dctInternal_nextConnection {
	
	for (DCTConnectionController *connection in self.dctInternal_queuedConnectionControllers) {
		DCTConnectionController *c = [self dctInternal_nextConnectionIterator:connection];
		if (c)
			return c;
	}
	return nil;
}

- (DCTConnectionController *)dctInternal_nextConnectionIterator:(DCTConnectionController *)connection {
	if ([connection.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];		
		
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusQueued)
				return [self dctInternal_nextConnectionIterator:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusStarted || c.status == DCTConnectionControllerStatusResponded)
				return nil;
	}	
	
	return connection;
}

- (BOOL)dctInternal_tryToRunConnection:(DCTConnectionController *)connectionController {
	
	if ([connectionController.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connectionController.dependencies sortedArrayUsingComparator:compareConnections];		
	
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusQueued)
				return [self dctInternal_tryToRunConnection:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusStarted || c.status == DCTConnectionControllerStatusResponded)
				return NO;
	}	
	
	// There are no dependencies left to be run on this connection controller, so we can safely run it.
	[self dctInternal_dequeueAndStartConnection:connectionController];
	
	return YES;
}

- (void)dctInternal_dequeueAndStartConnection:(DCTConnectionController *)connectionController {
	
	[self removeConnectionController:connectionController];
	[self.dctInternal_activeConnectionControllers addObject:connectionController];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountIncreasedNotification object:self];
	
	[connectionController start];
}

@end
