//
//  DCTConnectionController+Deprecated.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 11.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController+Deprecated.h"

@implementation DCTConnectionController (Deprecated)

- (void)addFinishHandler:(DCTConnectionControllerFinishBlock)handler {
	[self addCompletionHandler:^(id object) {
		handler();
	}];
}

@end
