//
//  DCTConnectionController+Depricated.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 11.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController+Depricated.h"

@implementation DCTConnectionController (Depricated)

- (void)addFinishHandler:(DCTConnectionControllerFinishBlock)handler {
	[self addCompletionHandler:^(id object) {
		handler();
	}];
}

@end
