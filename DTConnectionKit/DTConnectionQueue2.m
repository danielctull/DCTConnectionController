//
//  DTConnectionQueue2.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnectionQueue2.h"


NSString *const DTConnectionQueue2ConnectionCountChangedNotification = @"DTConnectionQueueConnectionCountChangedNotification";

static DTConnectionQueue2 *sharedInstance = nil;

@interface DTConnectionQueue2 ()
- (void)checkAndRunConnections;
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

- (NSInteger)connectionCount {
	return [activeConnections count];
}

- (NSArray *)connections {	
    return [[activeConnections copy] autorelease];
}

- (void)addConnection:(DTConnection2 *)connection {
	[queuedConnections addObject:connection];
	[self checkAndRunConnections];
}

- (void)checkAndRunConnections {
	
	if (self.connectionCount >= self.maxConnections) return;
	
	if ([queuedConnections count] < 1) return;
	
	DTConnection2 *connection = [queuedConnections objectAtIndex:0];
	
	[queuedConnections removeObject:connection];
	
	[activeConnections addObject:connection];
	
	[connection start];
}










// DECREMENTED
- (void)incrementExternalConnectionCount {}
- (void)decrementExternalConnectionCount {}

@end
