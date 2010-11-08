//
//  DCTConnectionMonitor.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 08/11/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionMonitor.h"
#import "DCTConnectionQueue+Singleton.h"

@implementation DCTConnectionMonitor

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:DCTConnectionQueueConnectionCountChangedNotification 
												  object:nil];
    [super dealloc];
}

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(countChanged:) 
												 name:DCTConnectionQueueConnectionCountChangedNotification 
											   object:nil];
	
	return self;
}

- (void)countChanged:(NSNotification *)notification {
	
	if (![[notification object] isKindOfClass:[DCTConnectionQueue class]]) return;
	
	DCTConnectionQueue *queue = [notification object];
	
	if (queue.connectionCount > 0)
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	else
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
