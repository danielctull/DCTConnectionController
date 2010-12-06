//
//  DTRequestConnectionController.m
//  Car Maps
//
//  Created by Daniel Tull on 14.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTRequestConnectionController.h"


@implementation DCTRequestConnectionController
@synthesize request;

- (NSMutableURLRequest *)newRequest {
	return [self.request mutableCopy];
}

@end
