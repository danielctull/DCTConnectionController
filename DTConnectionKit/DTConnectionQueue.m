//
//  DTConnectionQueue.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 23.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnectionQueue.h"

NSString *const DTConnectionQueueConnectionCountChangedNotification = @"DTConnectionQueueConnectionCountChangedNotification";

static DTConnectionQueue *sharedInstance = nil;

@implementation DTConnectionQueue


#pragma mark -
#pragma mark Methods for Singleton use

+ (void)initialize {
    if (!sharedInstance) {
        sharedInstance = [[self alloc] init];
    }
}

+ (DTConnectionQueue *)sharedConnectionQueue {
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

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	
	[self addObserver:self forKeyPath:@"operations" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	
	return self;
	
}

- (void)addConnection:(DTConnection *)connection {
	[super addOperation:connection];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	
	if ([keyPath isEqualToString:@"operations"]) {
		if ([self.operations count] > 0)
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		else
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionQueueConnectionCountChangedNotification object:self];
	
}

- (void)setMaxConnections:(NSInteger)max {
	[super setMaxConcurrentOperationCount:max];
}

- (NSInteger)maxConnections {
	return [super maxConcurrentOperationCount];
}

- (NSInteger)connectionCount {
	
	NSInteger count = 0;
	
	for (NSOperation *o in self.operations)
		if (o.isExecuting)
			count++;
	
	return count;
}

@end
