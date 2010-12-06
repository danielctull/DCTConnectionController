//
//  DCTMockConnection.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTMockConnection.h"

@implementation DCTMockConnection

- (void)complete {
	[super receivedObject:nil];
}

@end
