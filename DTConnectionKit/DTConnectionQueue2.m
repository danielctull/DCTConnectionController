//
//  DTConnectionQueue2.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnectionQueue2.h"

NSComparisonResult (^compareConnections)(id obj1, id obj2) = ^(id obj1, id obj2) {
	
	if (![obj1 isKindOfClass:[DTConnection2 class]] || ![obj2 isKindOfClass:[DTConnection2 class]]) return (NSComparisonResult)NSOrderedSame;
	
	DTConnection2 *con1 = (DTConnection2 *)obj1;
	DTConnection2 *con2 = (DTConnection2 *)obj2;
	
	if (con1.priority > con2.priority) return (NSComparisonResult)NSOrderedDescending;
	
	if (con1.priority < con2.priority) return (NSComparisonResult)NSOrderedAscending;
	
	return (NSComparisonResult)NSOrderedSame;
};

NSString *const DTConnectionQueue2ConnectionCountChangedNotification = @"DTConnectionQueueConnectionCountChangedNotification";

static DTConnectionQueue2 *sharedInstance = nil;

@interface DTConnectionQueue2 ()
- (void)dt_checkConnectionCount;
- (void)dt_runNextConnection;
- (void)dt_tryToRunConnection:(DTConnection2 *)connection;
- (void)dt_removeConnection:(DTConnection2 *)connection;
@end

@implementation DTConnectionQueue2

@synthesize maxConnections;

#pragma mark -
#pragma mark Methods for Singleton use

+ (void)initialize {
    if (!sharedInstance) {
        sharedInstance = [[self alloc] init];
    }
}

+ (DTConnectionQueue2 *)sharedConnectionQueue {
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    //Usually already set by +initialize.
    if (sharedInstance) {
        //The caller expects to receive a new object, so implicitly retain it to balance out the caller's eventual release message.
        return [sharedInstance retain];
    } else {
        //When not already set, +initialize is our caller—it's creating the shared instance. Let this go through.
        return [super allocWithZone:zone];
    }
}

#pragma mark -
#pragma mark init/dealloc

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	activeConnections = [[NSMutableArray alloc] init];
	queuedConnections = [[NSMutableArray alloc] init];
	
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

- (void)addConnection:(DTConnection2 *)connection {
	
	[connection addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	
	[queuedConnections addObject:connection];
	[connection setQueued];
	[queuedConnections sortUsingComparator:compareConnections];
		
	[self dt_runNextConnection];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
	if (![object isKindOfClass:[DTConnection2 class]]) return;
	
	DTConnection2 *connection = (DTConnection2 *)object;
	
	if (connection.status == DTConnectionStatusComplete 
		|| connection.status == DTConnectionStatusFailed
		|| connection.status == DTConnectionStatusCancelled) {
		[self dt_removeConnection:connection];
		[self dt_runNextConnection];
	}
}

- (BOOL)isConnectingToURL:(NSURL *)URL {
	for (DTConnection2 *c in activeConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return YES;
	
	return NO;
}

- (BOOL)hasQueuedConnectionToURL:(NSURL *)URL {
	for (DTConnection2 *c in queuedConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return YES;
	
	return NO;
}

- (DTConnection2 *)queuedConnectionToURL:(NSURL *)URL {
	for (DTConnection2 *c in queuedConnections)
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionQueue2ConnectionCountChangedNotification object:self];
	
	lastActiveConnectionCount = self.activeConnectionsCount;
}

- (void)dt_runNextConnection {
	
	if (self.activeConnectionsCount >= self.maxConnections) return;
	
	if ([queuedConnections count] < 1) {
		[self dt_checkConnectionCount];
		return;
	}
	
	DTConnection2 *connection = [queuedConnections objectAtIndex:0];
	
	[self dt_tryToRunConnection:connection];
	[self dt_checkConnectionCount];
}


- (void)dt_tryToRunConnection:(DTConnection2 *)connection {
	
	if ([connection.dependencies count] == 0) {
		[activeConnections addObject:connection];
		[queuedConnections removeObject:connection]; 
		[connection start];
		return;
	}
		
	NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];
	
	[self dt_tryToRunConnection:[sortedDependencies objectAtIndex:0]];
}

- (void)dt_removeConnection:(DTConnection2 *)connection {
	[connection removeObserver:self forKeyPath:@"status"];
	[activeConnections removeObject:connection];
	[self dt_checkConnectionCount];
}

#pragma mark -
#pragma mark Depricated

- (void)incrementExternalConnectionCount {}
- (void)decrementExternalConnectionCount {}

@end
