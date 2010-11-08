//
//  DCTConnectionMonitor.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 08/11/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionMonitor.h"
#import "DCTConnectionQueue+Singleton.h"

@interface DCTConnectionMonitor ()
- (void)dctInternal_countChangedNotification:(NSNotification *)notification;
- (void)dctInternal_countChanged;
@property (nonatomic, assign) NSInteger dctInternal_queueConnectionCount, dctInternal_externalCounnectionCount;
@end

@implementation DCTConnectionMonitor

@synthesize connectionCount, dctInternal_queueConnectionCount, dctInternal_externalCounnectionCount;

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:DCTConnectionQueueConnectionCountChangedNotification 
												  object:nil];
    [super dealloc];
}

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dctInternal_countChangedNotification:) 
												 name:DCTConnectionQueueConnectionCountChangedNotification 
											   object:nil];
	
	return self;
}

#pragma mark -
#pragma mark DCTConnectionMonitor

- (void)addConnection {
	self.dctInternal_externalCounnectionCount++;
}

- (void)removeConnection {
	self.dctInternal_externalCounnectionCount--;
}

#pragma mark -
#pragma mark Internals

- (void)dctInternal_countChangedNotification:(NSNotification *)notification {
	
	if (![[notification object] isKindOfClass:[DCTConnectionQueue class]]) return;
	
	DCTConnectionQueue *queue = [notification object];
	
	self.dctInternal_queueConnectionCount = queue.connectionCount;
}

- (void)dctInternal_countChanged {
	self.connectionCount = self.dctInternal_queueConnectionCount + self.dctInternal_externalCounnectionCount;

	if (self.connectionCount > 0)
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	else
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)setDctInternal_externalCounnectionCount:(NSInteger)externalCounnectionCount {
	dctInternal_externalCounnectionCount = externalCounnectionCount;
	[self dctInternal_countChanged];
}

- (void)setDctInternal_queueConnectionCount:(NSInteger)queueConnectionCount {
	dctInternal_queueConnectionCount = queueConnectionCount;
	[self dctInternal_countChanged];
}

@end
