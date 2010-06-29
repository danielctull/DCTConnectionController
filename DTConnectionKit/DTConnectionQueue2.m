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

@synthesize maxConnections, connectionCount;

#pragma mark -
#pragma mark Methods for Singleton use

+ (DTConnectionQueue2 *)sharedConnectionQueue {
	
	
	
    return sharedInstance;
}

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	connections = [[NSMutableArray alloc] init];
	queue = [[NSMutableArray alloc] init];
	
	return self;	
}

- (id)dealloc {
	[connections release];
	[queue release];
	[super dealloc];
}

- (NSArray *)connections {
    return [[connections copy] autorelease];
}

- (void)addConnection:(DTConnection2 *)connection {
	[queue addObject:connection];
}

// DECREMENTED
- (void)incrementExternalConnectionCount {}
- (void)decrementExternalConnectionCount {}

@end
