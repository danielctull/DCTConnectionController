//
//  DTURLConnectionJob.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnection2.h"
#import "DTConnectionQueue2.h"

@interface DTConnection2 ()
@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, readwrite) DTConnectionStatus status;
- (void)dtInternalFinish;
@end


@implementation DTConnection2

@synthesize status, type, priority, URL;

+ (DTConnection2 *)connection {
	return [[[self alloc] init] autorelease];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	dependencies = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)dealloc {
	[dependencies release];
	[super dealloc];
}

#pragma mark -
#pragma mark Starting the connection

- (void)connect {
	[[DTConnectionQueue2 sharedConnectionQueue] addConnection:self];
}

#pragma mark -
#pragma mark Dependency methods

- (NSArray *)dependencies {
	return [[dependencies copy] autorelease];
}

- (void)addDependency:(DTConnection2 *)connection {
	
	if (!connection) return;
	
	[dependencies addObject:connection];
}

- (void)removeDependency:(DTConnection2 *)connection {
	
	if (![dependencies containsObject:connection]) return;
	
	[dependencies removeObject:connection];
}

- (void)start {
	
	NSURLRequest *request = [self newRequest];
	
	if (!request) {
		[self dtInternalFinish];
		return;
	}
	
	self.URL = [request URL];
	urlConnection = [[DTURLConnection alloc] initWithRequest:request delegate:self];
	[request release];
	
	self.status = DTConnectionStatusStarted;
	
	if (!urlConnection) [self dtInternalFinish];
}

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:DTConnectionTypeString[self.type]];	
	return request;
}

- (void)dtInternalFinish {
	self.status = DTConnectionStatusComplete;
}

@end
