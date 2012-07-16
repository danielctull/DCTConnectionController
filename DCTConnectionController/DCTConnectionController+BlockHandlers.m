//
//  DCTConnectionController+BlockHandlers.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 09.12.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController+BlockHandlers.h"

@implementation DCTConnectionController (BlockHandlers)

- (void)addResponseHandler:(void (^)(NSURLResponse *))responseHandler {
	
	NSAssert(responseHandler != nil, @"Handler should not be nil.");
	
	if (self.status >= DCTConnectionControllerStatusResponded) {
		responseHandler(self.returnedResponse);
		return;
	}

	__weak DCTConnectionController *weakSelf = self;

	[self addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusResponded)
			responseHandler(weakSelf.returnedResponse);
	}];
}

- (void)addCompletionHandler:(void (^)())completionHandler {
	
	NSAssert(completionHandler != NULL, @"Handler should not be nil.");
	
	if (self.status == DCTConnectionControllerStatusCompleted) {
		completionHandler();
		return;
	}

	[self addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusCompleted)
			completionHandler();
	}];
}

- (void)addFailureHandler:(void (^)(NSError *))failureHandler {
	
	NSAssert(failureHandler != nil, @"Handler should not be nil.");
	
	if (self.status == DCTConnectionControllerStatusFailed) {
		failureHandler(self.returnedError);
		return;
	}

	__weak DCTConnectionController *weakSelf = self;

	[self addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusFailed)
			failureHandler(weakSelf.returnedError);
	}];
}

- (void)addCancelationHandler:(void (^)())cancelationHandler {
	
	NSAssert(cancelationHandler != nil, @"Handler should not be nil.");
	
	if (self.status == DCTConnectionControllerStatusCancelled) {
		cancelationHandler();
		return;
	}
	
	[self addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusCancelled)
			cancelationHandler();		
	}];	
}

@end
