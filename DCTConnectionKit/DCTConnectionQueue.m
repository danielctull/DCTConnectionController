//
//  DCTConnectionQueue.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueue.h"

NSComparisonResult (^compareConnections)(id obj1, id obj2) = ^(id obj1, id obj2) {
	
	if (![obj1 isKindOfClass:[DCTConnectionController class]] || ![obj2 isKindOfClass:[DCTConnectionController class]]) return (NSComparisonResult)NSOrderedSame;
	
	DCTConnectionController *con1 = (DCTConnectionController *)obj1;
	DCTConnectionController *con2 = (DCTConnectionController *)obj2;
	
	if (con1.priority > con2.priority) return (NSComparisonResult)NSOrderedDescending;
	
	if (con1.priority < con2.priority) return (NSComparisonResult)NSOrderedAscending;
	
	return (NSComparisonResult)NSOrderedSame;
};

NSString *const DCTConnectionQueueConnectionCountChangedNotification = @"DCTConnectionQueueConnectionCountChangedNotification";

@interface DCTConnectionQueue ()

- (NSMutableArray *)dctInternal_currentConnectionQueue;
- (void)dctInternal_checkConnectionCount;
- (void)dctInternal_runNextConnection;
- (BOOL)dctInternal_tryToRunConnection:(DCTConnectionController *)connection;
- (void)dctInternal_removeActiveConnection:(DCTConnectionController *)connection;

- (DCTConnectionController *)dctInternal_nextConnection;
- (DCTConnectionController *)dctInternal_nextConnectionIterator:(DCTConnectionController *)connection;

- (void)dctInternal_addConnectionControllerToQueue:(DCTConnectionController *)connectionController;
- (void)dctInternal_removeConnectionFromQueue:(DCTConnectionController *)connectionController;
@end

@implementation DCTConnectionQueue

@synthesize maxConnections;

- (void)start {
	active = YES;
	[self dctInternal_runNextConnection];
}

- (void)pause {
	active = NO;
}

- (void)stop {
	active = NO;
}

#pragma mark -
#pragma mark NSObject

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	activeConnections = [[NSMutableArray alloc] init];
	queuedConnections = [[NSMutableArray alloc] init];
	active = YES;
	self.maxConnections = 5;
	
	return self;	
}

- (void)dealloc {
	[activeConnections release]; activeConnections = nil;
	[queuedConnections release]; queuedConnections = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark DCTConnection Queue

- (void)addConnectionController:(DCTConnectionController *)connectionController {
	
	[connectionController addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	
	[self dctInternal_addConnectionControllerToQueue:connectionController];
	[connectionController setQueued];
		
	if (!active) return;
	
	[self dctInternal_runNextConnection];
}

- (void)removeConnectionController:(DCTConnectionController *)connectionController {
	
	if ([activeConnections containsObject:connectionController])
		[self dctInternal_removeActiveConnection:connectionController];
		
	else if ([queuedConnections containsObject:connectionController]) 
		[self dctInternal_removeConnectionFromQueue:connectionController];
	
	[connectionController reset];
	[connectionController removeObserver:self forKeyPath:@"status"];
}

- (void)requeueConnectionController:(DCTConnectionController *)connectionController {
	[connectionController retain];
	[self dctInternal_removeActiveConnection:connectionController];
	[connectionController reset];
	[self dctInternal_addConnectionControllerToQueue:connectionController];
	[connectionController release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
	if (![object isKindOfClass:[DCTConnectionController class]]) return;
	
	if (!active) return;
	
	DCTConnectionController *connection = (DCTConnectionController *)object;
	
	if (connection.status == DCTConnectionControllerStatusComplete 
		|| connection.status == DCTConnectionControllerStatusFailed
		|| connection.status == DCTConnectionControllerStatusCancelled) {
		
		[self dctInternal_removeActiveConnection:connection];
		[self dctInternal_runNextConnection];
	}
}

- (BOOL)isConnectingToURL:(NSURL *)URL {
	for (DCTConnectionController *c in activeConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return YES;
	
	return NO;
}

- (BOOL)hasQueuedConnectionControllerToURL:(NSURL *)URL {
	if ([self queuedConnectionControllerToURL:URL])
		return YES;
	
	return NO;
}

- (DCTConnectionController *)queuedConnectionControllerToURL:(NSURL *)URL {
	for (DCTConnectionController *c in queuedConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return c;
	
	return nil;
}


#pragma mark -
#pragma mark DCTConnectionQueue Accessors

- (NSArray *)activeConnectionControllers {
	return [NSArray arrayWithArray:activeConnections];
}
- (NSArray *)queuedConnectionControllers {
	return [NSArray arrayWithArray:queuedConnections];
}

- (NSInteger)activeConnectionsCount {
	return [activeConnections count];
}

- (NSInteger)queuedConnectionsCount {
	return [queuedConnections count];
}

- (NSInteger)connectionCount {
	return self.activeConnectionsCount + self.queuedConnectionsCount;
}

- (NSArray *)connectionControllers {	
    return [activeConnections arrayByAddingObjectsFromArray:queuedConnections];
}

#pragma mark -
#pragma mark Internals

- (void)dctInternal_checkConnectionCount {
	
	if (lastActiveConnectionCount == self.activeConnectionsCount) return;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueConnectionCountChangedNotification object:self];
	
	lastActiveConnectionCount = self.activeConnectionsCount;
}

- (void)dctInternal_runNextConnection {
	
	if (self.activeConnectionsCount >= self.maxConnections) return;
	
	if (!active) return;
	
	if ([[self dctInternal_currentConnectionQueue] count] < 1) {
		[self dctInternal_checkConnectionCount];
		return;
	}
	
	// Loop through the queue and try to run the top-most connection.
	// If it can't be run (eg waiting for dependencies), run the next one down.
		
	DCTConnectionController *connection = [self dctInternal_nextConnection];
	
	if (connection) {
		[activeConnections addObject:connection];
		[self dctInternal_removeConnectionFromQueue:connection]; 
		[connection start];	
	}
	
	[self dctInternal_checkConnectionCount];
}

- (DCTConnectionController *)dctInternal_nextConnection {
	
	for (DCTConnectionController *connection in [self dctInternal_currentConnectionQueue]) {
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
	[activeConnections addObject:connection];
	[self dctInternal_removeConnectionFromQueue:connection]; 
	[connection start];
	return YES;
}

- (NSMutableArray *)dctInternal_currentConnectionQueue {
	return queuedConnections;
}

- (void)dctInternal_addConnectionControllerToQueue:(DCTConnectionController *)connectionController {
	[queuedConnections addObject:connectionController];
	[queuedConnections sortUsingComparator:compareConnections];
}

- (void)dctInternal_removeConnectionFromQueue:(DCTConnectionController *)connectionController {
	[queuedConnections removeObject:connectionController];
}

- (void)dctInternal_removeActiveConnection:(DCTConnectionController *)connection {
	[connection removeObserver:self forKeyPath:@"status"];
	[activeConnections removeObject:connection];
}

@end
