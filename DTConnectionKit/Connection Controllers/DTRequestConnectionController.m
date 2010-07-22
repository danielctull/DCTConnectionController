//
//  DTRequestConnectionController.m
//  Car Maps
//
//  Created by Daniel Tull on 14.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTRequestConnectionController.h"


@implementation DTRequestConnectionController
@synthesize request;

- (NSMutableURLRequest *)newRequest {
	return [self.request mutableCopy];
}

@end
