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
	
	[self addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusResponded)
			responseHandler(connectionController.returnedResponse);
	}];
}

- (void)addFinishHandler:(void (^)())finishHandler {
	
	NSAssert(finishHandler != nil, @"Handler should not be nil.");
	
	if (self.status == DCTConnectionControllerStatusFinished) {
		finishHandler();
		return;
	}
	
	[self addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusFinished)
			finishHandler();
	}];
}

- (void)addFailureHandler:(void (^)(NSError *))failureHandler {
	
	NSAssert(failureHandler != nil, @"Handler should not be nil.");
	
	if (self.status == DCTConnectionControllerStatusFailed) {
		failureHandler(self.returnedError);
		return;
	}
		
	[self addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusFailed)
			failureHandler(connectionController.returnedError);
	}];
}

- (void)addCancelationHandler:(void (^)())cancelationHandler {
	
	NSAssert(cancelationHandler != nil, @"Handler should not be nil.");
	
	if (self.status == DCTConnectionControllerStatusCancelled) {
		cancelationHandler();
		return;
	}
	
	[self addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusCancelled)
			cancelationHandler();		
	}];	
}

@end
