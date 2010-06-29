//
//  DTURLConnectionJob.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnection2.h"
#import "DTConnectionQueue2.h"

@implementation DTConnection2

@synthesize dependencies;

- (void)connect {
	[self addToConnectionQueue];
}

- (void)addToConnectionQueue {
	[[DTConnectionQueue2 sharedConnectionQueue] addConnection:self];
}

- (void)addDependency:(DTConnection2 *)connection {
	NSMutableArray *temp = [[NSMutableArray alloc] init];
	[temp addObjectsFromArray:dependencies];
	[temp addObject:connection];
	[dependencies release];
	dependencies = nil;
	dependencies = temp;
}

- (void)removeDependency:(DTConnection2 *)connection {
	NSMutableArray *temp = [[NSMutableArray alloc] init];
	[temp addObjectsFromArray:dependencies];
	[temp removeObject:connection];
	[dependencies release];
	dependencies = nil;
	dependencies = temp;
}

@end
