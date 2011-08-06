//
//  DCTConnectionController+Deprication.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 06.08.2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController+Deprication.h"

@implementation DCTConnectionController (Deprication)

- (void)addResponseBlock:(DCTConnectionControllerResponseBlock)responseBlock {
	[self addResponseHandler:responseBlock];
}

- (void)addFailureBlock:(DCTConnectionControllerFailureBlock)failureBlock {
	[self addFailureBlock:failureBlock];
}

- (void)addCompletionBlock:(DCTConnectionControllerCompletionBlock)completionBlock {
	
	DCTConnectionControllerCompletionBlock b = [completionBlock copy];
	__block DCTConnectionController *myself = self;
	
	[self addFinishHandler:^(void) {
		b(myself.returnedObject);
	}];
}

- (void)addCancelationBlock:(DCTConnectionControllerCancelationBlock)cancelationBlock {
	[self addCancelationHandler:cancelationBlock];
}

- (void)setDownloadPath:(NSString *)downloadPath {
	NSLog(@"DCTConnectionController WARNING: Cannot set downloadPath");
}

@end
