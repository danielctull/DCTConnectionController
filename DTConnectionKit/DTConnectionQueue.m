//
//  DTConnectionQueue.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTConnectionQueue.h"

NSComparisonResult (^compareConnections)(id obj1, id obj2) = ^(id obj1, id obj2) {
	
	if (![obj1 isKindOfClass:[DCTConnectionController class]] || ![obj2 isKindOfClass:[DCTConnectionController class]]) return (NSComparisonResult)NSOrderedSame;
	
	DCTConnectionController *con1 = (DCTConnectionController *)obj1;
	DCTConnectionController *con2 = (DCTConnectionController *)obj2;
	
	if (con1.priority > con2.priority) return (NSComparisonResult)NSOrderedDescending;
	
	if (con1.priority < con2.priority) return (NSComparisonResult)NSOrderedAscending;
	
	return (NSComparisonResult)NSOrderedSame;
};

NSString *const DTConnectionQueueConnectionCountChangedNotification = @"DTConnectionQueueConnectionCountChangedNotification";

@interface DTConnectionQueue ()

- (NSMutableArray *)dt_currentConnectionQueue;
- (void)dt_checkConnectionCount;
- (void)dt_runNextConnection;
- (BOOL)dt_tryToRunConnection:(DCTConnectionController *)connection;
- (void)dt_removeConnection:(DCTConnectionController *)connection;

- (DCTConnectionController *)dt_nextConnection;
- (DCTConnectionController *)dt_nextConnectionInterator:(DCTConnectionController *)connection;

- (void)dt_didEnterBackground:(NSNotification *)notification;
- (void)dt_hush;
- (void)dt_finishedBackgroundConnections;

- (void)dt_addConnectionControllerToQueue:(DCTConnectionController *)connectionController;
- (void)dt_removeConnectionFromQueue:(DCTConnectionController *)connectionController;
@end

@implementation DTConnectionQueue

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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dt_didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	
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
	
	[self dt_addConnectionControllerToQueue:connectionController];
	[connectionController setQueued];
		
	if (!active) return;
	
	[self dt_runNextConnection];
}

- (void)requeueConnectionController:(DCTConnectionController *)connectionController {
	[connectionController retain];
	[self dt_removeConnection:connectionController];
	[connectionController reset];
	[self dt_addConnectionControllerToQueue:connectionController];
	[connectionController release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
	if (![object isKindOfClass:[DCTConnectionController class]]) return;
	
	DCTConnectionController *connection = (DCTConnectionController *)object;
	
	if (!active) return;
	
	if (connection.status == DTConnectionControllerStatusComplete 
		|| connection.status == DTConnectionControllerStatusFailed
		|| connection.status == DTConnectionControllerStatusCancelled) {
		
		[self dt_removeConnection:connection];
		[self dt_runNextConnection];
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
#pragma mark Private methods

- (void)dt_checkConnectionCount {
	
	if (lastActiveConnectionCount == self.activeConnectionsCount) return;
		
	if (self.activeConnectionsCount > 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	} else {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		
		if (inBackground) [self dt_finishedBackgroundConnections];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionQueueConnectionCountChangedNotification object:self];
	
	lastActiveConnectionCount = self.activeConnectionsCount;
}

- (void)dt_runNextConnection {
	
	if (self.activeConnectionsCount >= self.maxConnections) return;
	
	if (!active) return;
	
	if ([[self dt_currentConnectionQueue] count] < 1) {
		[self dt_checkConnectionCount];
		return;
	}
	
	// Loop through the queue and try to run the top-most connection.
	// If it can't be run (eg waiting for dependencies), run the next one down.
		
	DCTConnectionController *connection = [self dt_nextConnection];
	
	if (connection) {
		[activeConnections addObject:connection];
		[self dt_removeConnectionFromQueue:connection]; 
		[connection start];	
	}
	
	[self dt_checkConnectionCount];
}

- (DCTConnectionController *)dt_nextConnection {
	
	for (DCTConnectionController *connection in [self dt_currentConnectionQueue]) {
		DCTConnectionController *c = [self dt_nextConnectionInterator:connection];
		if (c)
			return c;
	}
	return nil;
}

- (DCTConnectionController *)dt_nextConnectionInterator:(DCTConnectionController *)connection {
	if ([connection.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];		
		
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DTConnectionControllerStatusQueued)
				return [self dt_nextConnectionInterator:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DTConnectionControllerStatusStarted || c.status == DTConnectionControllerStatusResponded)
				return nil;
	}	
	
	return connection;
}

- (BOOL)dt_tryToRunConnection:(DCTConnectionController *)connection {
	
	if ([connection.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];		
	
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DTConnectionControllerStatusQueued)
				return [self dt_tryToRunConnection:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DTConnectionControllerStatusStarted || c.status == DTConnectionControllerStatusResponded)
				return NO;
	}	
	
	// There are no dependencies left to be run on this connection, so we can safely run it.	
	[activeConnections addObject:connection];
	[self dt_removeConnectionFromQueue:connection]; 
	[connection start];
	return YES;
}

- (void)dt_removeConnection:(DCTConnectionController *)connection {
	[connection removeObserver:self forKeyPath:@"status"];
	[activeConnections removeObject:connection];
	//[self dt_checkConnectionCount];
}

- (NSMutableArray *)dt_currentConnectionQueue {
	if (inBackground) return backgroundConnections;
	return queuedConnections;
}

#pragma mark -
#pragma mark Multitasking

- (void)dt_didEnterBackground:(NSNotification *)notification {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dt_willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
	
	inBackground = YES;
	
	if (multitaskEnabled) {
		
		backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			[self dt_hush];
			[self dt_finishedBackgroundConnections];
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
		
		[self dt_runNextConnection];
		
	} else {
		[self dt_hush];
	}
}

- (void)dt_hush {
	
	active = NO;
	
	for (DCTConnectionController *c in activeConnections) {
		[c reset];
		[c setQueued];
	}
	
	[queuedConnections addObjectsFromArray:activeConnections];
	[activeConnections removeAllObjects];
}

- (void)dt_finishedBackgroundConnections {
	
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
	[self dt_runNextConnection];
}


#pragma mark -
#pragma mark Queue methods

- (void)dt_addConnectionControllerToQueue:(DCTConnectionController *)connectionController {
	if (inBackground && connectionController.multitaskEnabled) {
		[backgroundConnections addObject:connectionController];
		[backgroundConnections sortUsingComparator:compareConnections];
	} else {
		[queuedConnections addObject:connectionController];
		[queuedConnections sortUsingComparator:compareConnections];
	}
}

- (void)dt_removeConnectionFromQueue:(DCTConnectionController *)connectionController {
	// backgroundConnections will be nil for normal running time, so this is ok.
	[backgroundConnections removeObject:connectionController];
	[queuedConnections removeObject:connectionController];
}

#pragma mark -
#pragma mark Depricated

- (void)incrementExternalConnectionCount {}
- (void)decrementExternalConnectionCount {}

@end
