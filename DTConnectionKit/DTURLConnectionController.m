//
//  DTURLConnectionController.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import "DTURLConnectionController.h"


@implementation DTURLConnectionController

@synthesize URL;

- (void)dealloc {
	[URL release];
	[super dealloc];
}

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [super newRequest];
	[request setURL:URL];
	return request;
}

@end
