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
	DCTConnectionQueue *queue = [DCTConnectionQueue sharedConnectionQueue];
	[queue removeObserver:self forKeyPath:@"connectionCount"];
    [super dealloc];
}

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	DCTConnectionQueue *queue = [DCTConnectionQueue sharedConnectionQueue];
	[queue addObserver:self forKeyPath:@"connectionCount" options:NSKeyValueObservingOptionNew context:NULL];
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	
	DCTConnectionQueue *queue = [DCTConnectionQueue sharedConnectionQueue];

	if (queue.connectionCount > 0)
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	else
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
