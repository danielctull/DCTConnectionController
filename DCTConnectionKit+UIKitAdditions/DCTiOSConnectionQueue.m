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
- (void)dctInternal_hush;
- (void)dctInternal_finishedBackgroundConnections;
@end

@implementation DCTiOSConnectionQueue

@synthesize multitaskEnabled;

- (id)init {
	if (!(self = [super init])) return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(dctInternal_didEnterBackground:) 
												 name:UIApplicationDidEnterBackgroundNotification 
											   object:nil];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(dctInternal_willEnterForeground:) 
												 name:UIApplicationWillEnterForegroundNotification 
											   object:nil];
	
	return self;
}

- (NSInteger)connectionCount {
	return [super connectionCount] + [nonMultitaskingConnections count];
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
		[self dctInternal_finishedBackgroundConnections];
	}];
	
	// Remove connections that are active, but not multitasking and put them in our own queue.
	for (DCTConnectionController *c in self.activeConnectionControllers) {
		if (!c.multitaskEnabled) {
			[c reset];
			[c setQueued];
			[nonMultitaskingConnections addObject:c];
		}
	}
	
	// Remove non-multitasking connections from the queue
	for (DCTConnectionController *c in self.queuedConnectionControllers)
		if (!c.multitaskEnabled)
			[nonMultitaskingConnections addObject:c];
	
	[self re
	[ removeObjectsInArray:nonMultitaskingConnections];
	[activeConnections removeObjectsInArray:nonMultitaskingConnections];
		
	[self dctInternal_runNextConnection];
}

- (void)dctInternal_willEnterForeground:(NSNotification *)notification {
	if (!inBackground) return;
	
	[queuedConnections addObjectsFromArray:nonMultitaskingConnections];
	[nonMultitaskingConnections release];
	nonMultitaskingConnections = nil;
	inBackground = NO;
	[self start];
}

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
}

@end
