//
//  DCTiOSConnectionQueue.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 08/11/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DCTiOSConnectionQueue.h"

@interface DCTiOSConnectionQueue ()
- (void)dctInternal_didEnterBackground:(NSNotification *)notification;
- (void)dctInternal_willEnterForeground:(NSNotification *)notification;
//- (void)dctInternal_hush;
//- (void)dctInternal_finishedBackgroundConnections;
@end

@implementation DCTiOSConnectionQueue

@synthesize multitaskEnabled;

- (void)dealloc {
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter removeObserver:self
								  name:UIApplicationDidEnterBackgroundNotification
								object:nil];
	
	[notificationCenter removeObserver:self
								  name:UIApplicationWillEnterForegroundNotification
								object:nil];
	
	[notificationCenter removeObserver:self
								  name:DCTConnectionQueueActiveConnectionCountChangedNotification
								object:self];
    
	[super dealloc];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self 
						   selector:@selector(dctInternal_didEnterBackground:) 
							   name:UIApplicationDidEnterBackgroundNotification 
							 object:nil];
	
	
	[notificationCenter addObserver:self 
						   selector:@selector(dctInternal_willEnterForeground:) 
							   name:UIApplicationWillEnterForegroundNotification 
							 object:nil];
	
	[notificationCenter addObserver:self 
						   selector:@selector(dctInternal_activeConnectionCountChanged:) 
							   name:DCTConnectionQueueActiveConnectionCountChangedNotification 
							 object:self];
	
	return self;
}

- (void)dctInternal_activeConnectionCountChanged:(NSNotification *)notificaiton {
	
	UIApplication *application = [UIApplication sharedApplication];
	
	if (self.activeConnectionCount > 0) {
		[application setNetworkActivityIndicatorVisible:YES];
	
	} else {
		[application setNetworkActivityIndicatorVisible:NO];
		
		if (inBackground) [application endBackgroundTask:backgroundTaskIdentifier];
	}
}

- (NSInteger)connectionCount {
	return [super connectionCount] + [nonMultitaskingConnections count];
}

- (NSArray *)nonMultitaskingQueuedConnections {
	if (!nonMultitaskingConnections) return nil;
	
	return [NSArray arrayWithArray:nonMultitaskingConnections];
}

- (DCTConnectionController *)queuedConnectionControllerToURL:(NSURL *)URL {
	
	DCTConnectionController *c = [super queuedConnectionControllerToURL:URL];
	if (c) return c;
	
	for (c in nonMultitaskingConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return c;
	
	return nil;
}

- (void)dctInternal_didEnterBackground:(NSNotification *)notification {
	
	if (inBackground) return;
	
	inBackground = YES;
	
	if (!self.multitaskEnabled) {
		[self stop];
		return;
	}
	
	backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		[self stop];
	}];
	
	// Remove non-multitasking connections from the queue
	for (DCTConnectionController *c in self.queuedConnectionControllers) {
		if (!c.multitaskEnabled) {
			[nonMultitaskingConnections addObject:c]; 
			[self removeConnectionController:c];
		}
	}
	
	// Remove connections that are active, but not multitasking and put them in our own queue.
	for (DCTConnectionController *c in self.activeConnectionControllers) {
		if (!c.multitaskEnabled) {
			[c reset];
			[c setQueued];
			[nonMultitaskingConnections addObject:c];
			[self removeConnectionController:c];
		}
	}
}

- (void)dctInternal_willEnterForeground:(NSNotification *)notification {
	if (!inBackground) return;
	inBackground = NO;
	
	for (DCTConnectionController *c in nonMultitaskingConnections)
		[self addConnectionController:c];
	
	[nonMultitaskingConnections release];
	nonMultitaskingConnections = nil;
	[self start];
}

/*
- (void)dctInternal_finishedBackgroundConnections {
	
	for (DCTConnectionController *c in backgroundConnections) {
		[c reset];
		[c setQueued];
	}
	
	[queuedConnections addObjectsFromArray:backgroundConnections];
	
	[backgroundConnections release]; backgroundConnections = nil;
	[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
}

- (void)dctInternal_hush {
	
	active = NO;
	
	for (DCTConnectionController *c in activeConnections) {
		[c reset];
		[c setQueued];
	}
	
	[queuedConnections addObjectsFromArray:activeConnections];
	[activeConnections removeAllObjects];
}*/

@end
