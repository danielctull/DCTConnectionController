//
//  DTConnectionQueue2.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnectionQueue2.h"

NSComparisonResult (^compareConnections)(id obj1, id obj2) = ^(id obj1, id obj2){
	
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
- (void)runNextConnection;
- (void)tryToRunConnection:(DTConnection2 *)connection;
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

- (NSArray *)connections {	
    return [activeConnections arrayByAddingObjectsFromArray:queuedConnections];
}

- (void)addConnection:(DTConnection2 *)connection {
	[queuedConnections addObject:connection];
	
	[queuedConnections sortUsingComparator:compareConnections];
	
	[self runNextConnection];
}

- (void)runNextConnection {
	
	if (self.activeConnectionsCount >= self.maxConnections) return;
	
	if ([queuedConnections count] < 1) return;
	
	DTConnection2 *connection = [queuedConnections objectAtIndex:0];
	
	[self tryToRunConnection:connection];
}


- (void)tryToRunConnection:(DTConnection2 *)connection {
	
	if ([connection.dependencies count] == 0) {
		[queuedConnections removeObject:connection];
		[activeConnections addObject:connection];
		[connection start];
		return;
	}
		
	NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];
	
	[self tryToRunConnection:[sortedDependencies objectAtIndex:0]];
}







// DECREMENTED
- (void)incrementExternalConnectionCount {}
- (void)decrementExternalConnectionCount {}

@end
