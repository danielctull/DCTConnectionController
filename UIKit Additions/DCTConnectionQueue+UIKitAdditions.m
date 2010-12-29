//
//  DCTiOSConnectionQueue.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 08/11/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueue+UIKitAdditions.h"

@interface DCTConnectionQueue ()
- (void)dctInternal_didEnterBackground:(NSNotification *)notification;
- (void)dctInternal_willEnterForeground:(NSNotification *)notification;
- (void)uikit_init;
- (void)uikit_dealloc;

//- (void)dctInternal_hush;
//- (void)dctInternal_finishedBackgroundConnections;
@end





@interface DCTConnectionController (DCTConnectionQueueUIKitAdditions)
- (void)dctConnectionQueueUIKitAdditions_start;
- (void)dctConnectionQueueUIKitAdditions_reset;
- (void)dctConnectionQueueUIKitAdditions_setQueued;
@end
@implementation DCTConnectionController (DCTConnectionQueue)
- (void)dctConnectionQueueUIKitAdditions_start {
	[self performSelector:@selector(dctInternal_start)];
}
- (void)dctConnectionQueueUIKitAdditions_reset {
	[self performSelector:@selector(dctInternal_reset)];
}
- (void)dctConnectionQueueUIKitAdditions_setQueued {
	[self performSelector:@selector(dctInternal_setQueued)];
}
@end



@implementation DCTConnectionQueue (UIKitAdditions)

- (void)setBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)aBackgroundTaskIdentifier {
	backgroundTaskIdentifier = aBackgroundTaskIdentifier;
}

- (UIBackgroundTaskIdentifier)backgroundTaskIdentifier {
	return backgroundTaskIdentifier;
}

- (void)setMultitaskEnabled:(BOOL)aBool {
	multitaskEnabled = aBool;
}

- (BOOL)multitaskEnabled {
	return multitaskEnabled;
}

- (BOOL)inBackground {
	return inBackground;
}

- (void)uikit_dealloc {
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
}

- (void)uikit_init {
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	multitaskEnabled = YES;
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
}

- (void)dctInternal_activeConnectionCountChanged:(NSNotification *)notificaiton {
	
	UIApplication *application = [UIApplication sharedApplication];
	
	if (self.activeConnectionCount > 0) {
		[application setNetworkActivityIndicatorVisible:YES];
	
	} else {
		[application setNetworkActivityIndicatorVisible:NO];
		
		if (inBackground) [application endBackgroundTask:self.backgroundTaskIdentifier];
	}
}

- (NSArray *)nonMultitaskingQueuedConnectionControllers {
	if (!nonMultitaskingConnectionControllers) return nil;
	
	return [NSArray arrayWithArray:nonMultitaskingConnectionControllers];
}

- (void)dctInternal_didEnterBackground:(NSNotification *)notification {
	
	if (inBackground) return;
	inBackground = YES;
	
	[nonMultitaskingConnectionControllers release];
	nonMultitaskingConnectionControllers = [[NSMutableArray alloc] init];
	
	if (!self.multitaskEnabled) {
		[self stop];
		return;
	}
	
	self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		[self stop];
	}];
	
	// Remove non-multitasking connections from the queue
	for (DCTConnectionController *c in self.queuedConnectionControllers) {
		if (!c.multitaskEnabled) {
			[nonMultitaskingConnectionControllers addObject:c]; 
			[self removeConnectionController:c];
		}
	}
	
	// Remove connections that are active, but not multitasking and put them in our own queue.
	for (DCTConnectionController *c in self.activeConnectionControllers) {
		if (!c.multitaskEnabled) {
			[c dctConnectionQueueUIKitAdditions_reset];
			[c dctConnectionQueueUIKitAdditions_setQueued];
			[nonMultitaskingConnectionControllers addObject:c];
			[self removeConnectionController:c];
		}
	}
}

- (void)dctInternal_willEnterForeground:(NSNotification *)notification {
	if (!inBackground) return;
	inBackground = NO;
	
	for (DCTConnectionController *c in nonMultitaskingConnectionControllers)
		[self addConnectionController:c];
	
	[nonMultitaskingConnectionControllers release];
	nonMultitaskingConnectionControllers = nil;
	[self start];
}

@end
