//
//  DTURLLoadingConnection.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 25.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTURLLoadingConnection.h"


@implementation DTURLLoadingConnection

@synthesize URL;

- (void)dealloc {
	[super dealloc];
}

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [super newRequest];
	[request setURL:URL];
	return request;
}

@end
