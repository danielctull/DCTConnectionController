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
- (void)dctInternal_removeConnection:(DCTConnectionController *)connection;

- (DCTConnectionController *)dctInternal_nextConnection;
- (DCTConnectionController *)dctInternal_nextConnectionInterator:(DCTConnectionController *)connection;

- (void)dctInternal_didEnterBackground:(NSNotification *)notification;
- (void)dctInternal_hush;
- (void)dctInternal_finishedBackgroundConnections;

- (void)dctInternal_addConnectionControllerToQueue:(DCTConnectionController *)connectionController;
- (void)dctInternal_removeConnectionFromQueue:(DCTConnectionController *)connectionController;
@end

@implementation DCTConnectionQueue

@synthesize maxConnections, multitaskEnabled;

- (void)start {
	active = YES;
}

- (void)stop {
	active = NO;
}

#pragma mark -
#pragma mark init/dealloc

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	activeConnections = [[NSMutableArray alloc] init];
	queuedConnections = [[NSMutableArray alloc] init];
	active = YES;
	self.maxConnections = 5;
	self.multitaskEnabled = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dctInternal_didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	return self;	
}

- (void)dealloc {
	[activeConnections release]; activeConnections = nil;
	[queuedConnections release]; queuedConnections = nil;
	[super dealloc];
}

#pragma mark -

- (NSInteger)activeConnectionsCount {
	return [activeConnections count];
}

- (NSInteger)queuedConnectionsCount {
	return [queuedConnections count];
}

- (NSInteger)connectionCount {
	return self.activeConnectionsCount + self.queuedConnectionsCount + [backgroundConnections count];
}

- (NSArray *)connectionControllers {	
    return [activeConnections arrayByAddingObjectsFromArray:queuedConnections];
}

- (void)addConnectionController:(DCTConnectionController *)connectionController {
	
	[connectionController addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	
	[self dctInternal_addConnectionControllerToQueue:connectionController];
	[connectionController setQueued];
		
	if (!active) return;
	
	[self dctInternal_runNextConnection];
}

- (void)requeueConnectionController:(DCTConnectionController *)connectionController {
	[connectionController retain];
	[self dctInternal_removeConnection:connectionController];
	[connectionController reset];
	[self dctInternal_addConnectionControllerToQueue:connectionController];
	[connectionController release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
	if (![object isKindOfClass:[DCTConnectionController class]]) return;
	
	DCTConnectionController *connection = (DCTConnectionController *)object;
	
	if (!active) return;
	
	if (connection.status == DCTConnectionControllerStatusComplete 
		|| connection.status == DCTConnectionControllerStatusFailed
		|| connection.status == DCTConnectionControllerStatusCancelled) {
		
		[self dctInternal_removeConnection:connection];
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
	
	for (DCTConnectionController *c in backgroundConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return c;
	
	return nil;
}

#pragma mark -
#pragma mark Internal

- (void)dctInternal_checkConnectionCount {
	
	if (lastActiveConnectionCount == self.activeConnectionsCount) return;
		
	if (self.activeConnectionsCount > 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	} else {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		
		if (inBackground) [self dctInternal_finishedBackgroundConnections];
	}
	
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
		DCTConnectionController *c = [self dctInternal_nextConnectionInterator:connection];
		if (c)
			return c;
	}
	return nil;
}

- (DCTConnectionController *)dctInternal_nextConnectionInterator:(DCTConnectionController *)connection {
	if ([connection.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];		
		
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusQueued)
				return [self dctInternal_nextConnectionInterator:c];
		
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

- (void)dctInternal_removeConnection:(DCTConnectionController *)connection {
	[connection removeObserver:self forKeyPath:@"status"];
	[activeConnections removeObject:connection];
	//[self dctInternal_checkConnectionCount];
}

- (NSMutableArray *)dctInternal_currentConnectionQueue {
	if (inBackground) return backgroundConnections;
	return queuedConnections;
}

#pragma mark -
#pragma mark Multitasking

- (void)dctInternal_didEnterBackground:(NSNotification *)notification {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dt_willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
	
	inBackground = YES;
	
	if (multitaskEnabled) {
		
		backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			[self dctInternal_hush];
			[self dctInternal_finishedBackgroundConnections];
		}];
		
		NSMutableArray *nonMultitaskingCurrentlyActive = [[NSMutableArray alloc] init];
		
		for (DCTConnectionController *c in activeConnections)  {
			if (!c.multitaskEnabled) {
				[c reset];
				[c setQueued];
				[nonMultitaskingCurrentlyActive addObject:c];
			}
		}
		
		backgroundConnections = [[NSMutableArray alloc] init];
		
		for (DCTConnectionController *c in queuedConnections)
			if (c.multitaskEnabled)
				[backgroundConnections addObject:c];
		
		[queuedConnections removeObjectsInArray:backgroundConnections];
		
		[queuedConnections addObjectsFromArray:nonMultitaskingCurrentlyActive];
		[activeConnections removeObjectsInArray:nonMultitaskingCurrentlyActive];
		
		[backgroundConnections sortUsingComparator:compareConnections];
		[queuedConnections sortUsingComparator:compareConnections];
		
		[nonMultitaskingCurrentlyActive release], nonMultitaskingCurrentlyActive = nil;
		
		[self dctInternal_runNextConnection];
		
	} else {
		[self dctInternal_hush];
	}
}

- (void)dctInternal_hush {
	
	active = NO;
	
	for (DCTConnectionController *c in activeConnections) {
		[c reset];
		[c setQueued];
	}
	
	[queuedConnections addObjectsFromArray:activeConnections];
	[activeConnections removeAllObjects];
}

- (void)dctInternal_finishedBackgroundConnections {
	
	for (DCTConnectionController *c in backgroundConnections) {
		[c reset];
		[c setQueued];
	}
	
	[queuedConnections addObjectsFromArray:backgroundConnections];
	
	[backgroundConnections release]; backgroundConnections = nil;
	[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
}

- (void)dt_willEnterForeground:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
	[queuedConnections sortUsingComparator:compareConnections];
	active = YES;
	inBackground = NO;
	[self dctInternal_runNextConnection];
}


#pragma mark -
#pragma mark Queue methods

- (void)dctInternal_addConnectionControllerToQueue:(DCTConnectionController *)connectionController {
	if (inBackground && connectionController.multitaskEnabled) {
		[backgroundConnections addObject:connectionController];
		[backgroundConnections sortUsingComparator:compareConnections];
	} else {
		[queuedConnections addObject:connectionController];
		[queuedConnections sortUsingComparator:compareConnections];
	}
}

- (void)dctInternal_removeConnectionFromQueue:(DCTConnectionController *)connectionController {
	// backgroundConnections will be nil for normal running time, so this is ok.
	[backgroundConnections removeObject:connectionController];
	[queuedConnections removeObject:connectionController];
}

#pragma mark -
#pragma mark Depricated

- (void)incrementExternalConnectionCount {}
- (void)decrementExternalConnectionCount {}

@end
