//
//  DTURLLoadingConnectionController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 25.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTURLLoadingConnectionController.h"


@implementation DCTURLLoadingConnectionController

@dynamic URL;

- (void)dealloc {
	[super dealloc];
}

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [super newRequest];
	[request setURL:URL];
	return request;
}

@end