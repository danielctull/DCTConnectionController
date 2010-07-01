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
	
	if (![obj1 isKindOfClass:[DTConnection class]] || ![obj2 isKindOfClass:[DTConnection class]]) return (NSComparisonResult)NSOrderedSame;
	
	DTConnection *con1 = (DTConnection *)obj1;
	DTConnection *con2 = (DTConnection *)obj2;
	
	if (con1.priority > con2.priority) return (NSComparisonResult)NSOrderedDescending;
	
	if (con1.priority < con2.priority) return (NSComparisonResult)NSOrderedAscending;
	
	return (NSComparisonResult)NSOrderedSame;
};

NSString *const DTConnectionQueueConnectionCountChangedNotification = @"DTConnectionQueueConnectionCountChangedNotification";

@interface DTConnectionQueue ()
- (void)dt_checkConnectionCount;
- (void)dt_runNextConnection;
- (BOOL)dt_tryToRunConnection:(DTConnection *)connection;
- (void)dt_removeConnection:(DTConnection *)connection;
@end

@implementation DTConnectionQueue

@synthesize maxConnections;

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
	
	return self;	
}

- (void)dealloc {
	[activeConnections release];
	[queuedConnections release];
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
	return self.activeConnectionsCount + self.queuedConnectionsCount;
}

- (NSArray *)connections {	
    return [activeConnections arrayByAddingObjectsFromArray:queuedConnections];
}

- (void)addConnection:(DTConnection *)connection {
	
	[connection addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	
	[queuedConnections addObject:connection];
	[connection setQueued];
	[queuedConnections sortUsingComparator:compareConnections];
		
	if (active)
		[self dt_runNextConnection];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
	if (![object isKindOfClass:[DTConnection class]]) return;
	
	DTConnection *connection = (DTConnection *)object;
	
	if (connection.status == DTConnectionStatusComplete 
		|| connection.status == DTConnectionStatusFailed
		|| connection.status == DTConnectionStatusCancelled) {
		[self dt_removeConnection:connection];
		[self dt_runNextConnection];
	}
}

- (BOOL)isConnectingToURL:(NSURL *)URL {
	for (DTConnection *c in activeConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return YES;
	
	return NO;
}

- (BOOL)hasQueuedConnectionToURL:(NSURL *)URL {
	for (DTConnection *c in queuedConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return YES;
	
	return NO;
}

- (DTConnection *)queuedConnectionToURL:(NSURL *)URL {
	for (DTConnection *c in queuedConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return c;
	
	return nil;
}

#pragma mark -
#pragma mark Private methods

- (void)dt_checkConnectionCount {
	
	if (lastActiveConnectionCount == self.activeConnectionsCount) return;
		
	if (self.activeConnectionsCount > 0)
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	else
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionQueueConnectionCountChangedNotification object:self];
	
	lastActiveConnectionCount = self.activeConnectionsCount;
}

- (void)dt_runNextConnection {
	
	if (self.activeConnectionsCount >= self.maxConnections) return;
	
	if ([queuedConnections count] < 1) {
		[self dt_checkConnectionCount];
		return;
	}
	
	// Loop through the queue and try to run the top-most connection.
	// If it can't be run (eg waiting for dependencies), run the next one down.
	
	for (DTConnection *connection in queuedConnections)
		if ([self dt_tryToRunConnection:connection])
			break;
	
	[self dt_checkConnectionCount];
}


- (BOOL)dt_tryToRunConnection:(DTConnection *)connection {
	
	if ([connection.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];		
	
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DTConnection *c in sortedDependencies)
			if (c.status == DTConnectionStatusQueued)
				return [self dt_tryToRunConnection:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DTConnection *c in sortedDependencies)
			if (c.status == DTConnectionStatusStarted || c.status == DTConnectionStatusResponded)
				return NO;
	}	
	
	// There are no dependencies left to be run on this connection, so we can safely run it.	
	[activeConnections addObject:connection];
	[queuedConnections removeObject:connection]; 
	[connection start];
	return YES;
}

- (void)dt_removeConnection:(DTConnection *)connection {
	[connection removeObserver:self forKeyPath:@"status"];
	[activeConnections removeObject:connection];
	[self dt_checkConnectionCount];
}

#pragma mark -
#pragma mark Depricated

- (void)incrementExternalConnectionCount {}
- (void)decrementExternalConnectionCount {}

@end
