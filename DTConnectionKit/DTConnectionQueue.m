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
	
	if (![obj1 isKindOfClass:[DTConnectionController class]] || ![obj2 isKindOfClass:[DTConnectionController class]]) return (NSComparisonResult)NSOrderedSame;
	
	DTConnectionController *con1 = (DTConnectionController *)obj1;
	DTConnectionController *con2 = (DTConnectionController *)obj2;
	
	if (con1.priority > con2.priority) return (NSComparisonResult)NSOrderedDescending;
	
	if (con1.priority < con2.priority) return (NSComparisonResult)NSOrderedAscending;
	
	return (NSComparisonResult)NSOrderedSame;
};

NSString *const DTConnectionQueueConnectionCountChangedNotification = @"DTConnectionQueueConnectionCountChangedNotification";

@interface DTConnectionQueue ()

- (NSMutableArray *)dt_connectionQueue;
- (void)dt_checkConnectionCount;
- (void)dt_runNextConnection;
- (BOOL)dt_tryToRunConnection:(DTConnectionController *)connection;
- (void)dt_removeConnection:(DTConnectionController *)connection;

- (DTConnectionController *)dt_nextConnection;
- (DTConnectionController *)dt_nextConnectionInterator:(DTConnectionController *)connection;

- (void)dt_didEnterBackground:(NSNotification *)notification;
- (void)dt_hush;
- (void)dt_finishedBackgroundConnections;
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

- (void)addConnectionController:(DTConnectionController *)connectionController {
	
	[connectionController addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	
	[queuedConnections addObject:connectionController];
	[connectionController setQueued];
	[queuedConnections sortUsingComparator:compareConnections];
		
	if (!active) return;
	
	[self dt_runNextConnection];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
	if (![object isKindOfClass:[DTConnectionController class]]) return;
	
	DTConnectionController *connection = (DTConnectionController *)object;
	
	if (!active) return;
	
	if (connection.status == DTConnectionControllerStatusComplete 
		|| connection.status == DTConnectionControllerStatusFailed
		|| connection.status == DTConnectionControllerStatusCancelled) {
		[self dt_removeConnection:connection];
		[self dt_runNextConnection];
	}
}

- (BOOL)isConnectingToURL:(NSURL *)URL {
	for (DTConnectionController *c in activeConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return YES;
	
	return NO;
}

- (BOOL)hasQueuedConnectionControllerToURL:(NSURL *)URL {
	for (DTConnectionController *c in queuedConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return YES;
	
	return NO;
}

- (DTConnectionController *)queuedConnectionControllerToURL:(NSURL *)URL {
	for (DTConnectionController *c in queuedConnections)
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
	
	if ([[self dt_connectionQueue] count] < 1) {
		[self dt_checkConnectionCount];
		return;
	}
	
	// Loop through the queue and try to run the top-most connection.
	// If it can't be run (eg waiting for dependencies), run the next one down.
		
	DTConnectionController *connection = [self dt_nextConnection];
	
	if (connection) {
		[activeConnections addObject:connection];
		[queuedConnections removeObject:connection]; 
		[connection start];		
	}
	
	[self dt_checkConnectionCount];
}

- (DTConnectionController *)dt_nextConnection {
	
	for (DTConnectionController *connection in [self dt_connectionQueue]) {
		DTConnectionController *c = [self dt_nextConnectionInterator:connection];
		if (c)
			return c;
	}
	return nil;
}

- (DTConnectionController *)dt_nextConnectionInterator:(DTConnectionController *)connection {
	if ([connection.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];		
		
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DTConnectionController *c in sortedDependencies)
			if (c.status == DTConnectionControllerStatusQueued)
				return [self dt_nextConnectionInterator:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DTConnectionController *c in sortedDependencies)
			if (c.status == DTConnectionControllerStatusStarted || c.status == DTConnectionControllerStatusResponded)
				return nil;
	}	
	
	return connection;
}

- (BOOL)dt_tryToRunConnection:(DTConnectionController *)connection {
	
	if ([connection.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];		
	
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DTConnectionController *c in sortedDependencies)
			if (c.status == DTConnectionControllerStatusQueued)
				return [self dt_tryToRunConnection:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DTConnectionController *c in sortedDependencies)
			if (c.status == DTConnectionControllerStatusStarted || c.status == DTConnectionControllerStatusResponded)
				return NO;
	}	
	
	// There are no dependencies left to be run on this connection, so we can safely run it.	
	[activeConnections addObject:connection];
	[queuedConnections removeObject:connection]; 
	[connection start];
	return YES;
}

- (void)dt_removeConnection:(DTConnectionController *)connection {
	[connection removeObserver:self forKeyPath:@"status"];
	[activeConnections removeObject:connection];
	[self dt_checkConnectionCount];
}

- (NSMutableArray *)dt_connectionQueue {
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
		
		for (DTConnectionController *c in activeConnections)  {
			if (!c.multitaskEnabled) {
				[c reset];
				[nonMultitaskingCurrentlyActive addObject:c];
			}
		}
		
		backgroundConnections = [[NSMutableArray alloc] init];
		
		for (DTConnectionController *c in queuedConnections)
			if (c.multitaskEnabled)
				[backgroundConnections addObject:c];
		
		[queuedConnections removeObjectsInArray:backgroundConnections];
		
		[queuedConnections addObjectsFromArray:nonMultitaskingCurrentlyActive];
		[queuedConnections sortUsingComparator:compareConnections];
		[activeConnections removeObjectsInArray:nonMultitaskingCurrentlyActive];
		
		[nonMultitaskingCurrentlyActive release], nonMultitaskingCurrentlyActive = nil;
		
		[self dt_runNextConnection];
		
	} else {
		[self dt_hush];
	}
}

- (void)dt_hush {
	
	active = NO;
	
	for (DTConnectionController *c in activeConnections)
		[c reset];
	
	[queuedConnections addObjectsFromArray:activeConnections];
	[queuedConnections sortUsingComparator:compareConnections];
	[activeConnections removeAllObjects];
}

- (void)dt_finishedBackgroundConnections {
	[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
}

- (void)dt_willEnterForeground:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
	active = YES;
	[self dt_runNextConnection];
}

#pragma mark -
#pragma mark Depricated

- (void)incrementExternalConnectionCount {}
- (void)decrementExternalConnectionCount {}

@end
