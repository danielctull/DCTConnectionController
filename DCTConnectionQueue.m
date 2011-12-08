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
#import "NSObject+DCTKVOExtras.h"
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

NSString *const DCTConnectionQueueActiveConnectionCountKey = @"activeConnectionCount";
NSString *const DCTConnectionQueueConnectionCountKey = @"connectionCount";

NSString *const DCTConnectionQueueActiveConnectionCountIncreasedNotification = @"DCTConnectionQueueActiveConnectionCountIncreasedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountDecreasedNotification = @"DCTConnectionQueueActiveConnectionCountDecreasedNotification";



@interface DCTConnectionController (DCTConnectionQueue)
- (void)dctConnectionQueue_start;
@end

@interface DCTConnectionQueue (DCTConnectionController)
- (void)dctConnectionController_addConnectionController:(DCTConnectionController *)connectionController;
- (void)dctConnectionController_removeConnectionController:(DCTConnectionController *)connectionController;
@end


@interface DCTConnectionQueue ()

- (void)dctInternal_runNextConnection;
- (BOOL)dctInternal_tryToRunConnection:(DCTConnectionController *)connection;

- (DCTConnectionController *)dctInternal_nextConnection;
- (DCTConnectionController *)dctInternal_nextConnectionIterator:(DCTConnectionController *)connection;

- (void)dctInternal_addConnectionController:(DCTConnectionController *)connectionController;

- (void)dctInternal_removeConnectionController:(DCTConnectionController *)connectionController;
- (void)dctInternal_removeQueuedConnectionController:(DCTConnectionController *)connectionController;
- (void)dctInternal_removeActiveConnectionController:(DCTConnectionController *)connectionController;

- (void)dctInternal_dequeueAndStartConnection:(DCTConnectionController *)connectionController;

- (void)uikit_dealloc;
- (void)uikit_init;
@end

@implementation DCTConnectionQueue {
    __strong NSMutableArray *activeConnections;
	__strong NSMutableArray *queuedConnections;
	BOOL active;
	
	dispatch_queue_t queue;
}

@synthesize maxConnections;

#pragma mark - NSObject

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	activeConnections = [[NSMutableArray alloc] init];
	queuedConnections = [[NSMutableArray alloc] init];
	active = YES;
	self.maxConnections = 5;
	
	queue = dispatch_get_current_queue();
	
	[self uikit_init];
	
	return self;	
}

- (void)uikit_init {}

- (void)dealloc {
	[self uikit_dealloc];
}

- (void)uikit_dealloc {}

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
	return [NSArray arrayWithArray:activeConnections];
}


- (NSArray *)queuedConnectionControllers {
	return [NSArray arrayWithArray:queuedConnections];
}

- (NSArray *)connectionControllers {
	return [activeConnections arrayByAddingObjectsFromArray:queuedConnections];
}

- (NSInteger)activeConnectionCount {
	return [activeConnections count];
}

- (NSInteger)queuedConnectionCount {
	return [queuedConnections count];
}

- (NSInteger)connectionCount {
	return self.activeConnectionCount + [queuedConnections count] + [nonMultitaskingConnectionControllers count];
}

#pragma mark - Internals

- (void)dctInternal_runNextConnection {
	
	if ([activeConnections count] >= self.maxConnections) return;
	
	if (!active) return;
	
	if ([queuedConnections count] == 0) return;
	
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
	
	for (DCTConnectionController *connection in queuedConnections) {
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

- (BOOL)dctInternal_tryToRunConnection:(DCTConnectionController *)connection {
	
	if ([connection.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];		
	
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusQueued)
				return [self dctInternal_tryToRunConnection:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusStarted || c.status == DCTConnectionControllerStatusResponded)
				return NO;
	}	
	
	// There are no dependencies left to be run on this connection, so we can safely run it.
	[self dctInternal_dequeueAndStartConnection:connection];
	
	return YES;
}

- (void)dctInternal_addConnectionController:(DCTConnectionController *)connectionController {
	
	__dct_weak DCTConnectionController *weakConnectionController = connectionController;
	
	[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		if (weakConnectionController.ended)
			[self dctInternal_removeConnectionController:weakConnectionController];
	}];
	
	[self dct_changeValueForKey:DCTConnectionQueueConnectionCountKey withChange:^{
		[queuedConnections addObject:connectionController];
	}];
	
	[queuedConnections sortUsingComparator:compareConnections];
	
	if (active) [self dctInternal_runNextConnection];
}

- (void)dctInternal_removeConnectionController:(DCTConnectionController *)connectionController {
	
	if ([activeConnections containsObject:connectionController])
		[self dctInternal_removeActiveConnectionController:connectionController];
	
	else if ([queuedConnections containsObject:connectionController]) 
		[self dctInternal_removeQueuedConnectionController:connectionController];
}

- (void)dctInternal_removeQueuedConnectionController:(DCTConnectionController *)connectionController {
	[self dct_changeValueForKey:DCTConnectionQueueConnectionCountKey withChange:^{
		[queuedConnections removeObject:connectionController];
	}];
}
	
- (void)dctInternal_removeActiveConnectionController:(DCTConnectionController *)connection {
	
	NSArray *changedKeys = [NSArray arrayWithObjects:DCTConnectionQueueActiveConnectionCountKey, DCTConnectionQueueConnectionCountKey, nil];
	[self dct_changeValueForKeys:changedKeys withChange:^{
		[activeConnections removeObject:connection];
	}];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountDecreasedNotification 
														object:self];
	
	[self dctInternal_runNextConnection];
}

- (void)dctInternal_dequeueAndStartConnection:(DCTConnectionController *)connectionController {
	
	[self dct_changeValueForKey:DCTConnectionQueueActiveConnectionCountKey withChange:^{
		[activeConnections addObject:connectionController];
		[queuedConnections removeObject:connectionController];
	}];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountIncreasedNotification object:self];
	
	[connectionController dctConnectionQueue_start];
}

@end


#pragma mark - Internal access for DCTConnectionController

@implementation DCTConnectionQueue (DCTConnectionController)

- (void)dctConnectionController_addConnectionController:(DCTConnectionController *)connectionController {
	[self dctInternal_addConnectionController:connectionController];
}

- (void)dctConnectionController_removeConnectionController:(DCTConnectionController *)connectionController {
	[self dctInternal_removeConnectionController:connectionController];
}
		 
@end
