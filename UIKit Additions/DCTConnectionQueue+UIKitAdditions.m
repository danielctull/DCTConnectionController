/*
 DCTConnectionQueue+UIKitAdditions.m
 DCTConnectionController
 
 Created by Daniel Tull on 8.11.2010.
 
 
 
 Copyright (c) 2010 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DCTConnectionQueue+UIKitAdditions.h"

@interface DCTConnectionQueue ()
- (void)dctInternal_didEnterBackground:(NSNotification *)notification;
- (void)dctInternal_willEnterForeground:(NSNotification *)notification;
- (void)dctInternal_activeConnectionCountChanged:(NSNotification *)notificaiton;
- (void)uikit_init;
- (void)uikit_dealloc;
@end





@interface DCTConnectionController (DCTConnectionQueueUIKitAdditions)
- (void)dctInternal_start;
- (void)dctInternal_reset;
- (void)dctInternal_setQueued;
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
}

- (NSArray *)nonMultitaskingQueuedConnectionControllers {
	if (!nonMultitaskingConnectionControllers) return nil;
	
	return [NSArray arrayWithArray:nonMultitaskingConnectionControllers];
}

- (NSUInteger)nonMultitaskingQueuedConnectionControllersCount {
	return [nonMultitaskingConnectionControllers count];
}

- (void)dctInternal_didEnterBackground:(NSNotification *)notification {
	
	if (inBackground) return;
	inBackground = YES;
	
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
			[c dctInternal_reset];
			[c dctInternal_setQueued];
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
	
	nonMultitaskingConnectionControllers = nil;
	[self start];
}

@end
