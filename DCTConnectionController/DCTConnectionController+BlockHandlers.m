//
//  DCTConnectionController+BlockHandlers.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 09.12.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController+BlockHandlers.h"
#import "DCTConnectionController+UsefulChecks.h"

@implementation DCTConnectionController (BlockHandlers)

- (void)addResponseHandler:(DCTConnectionControllerResponseBlock)handler {
	
	NSAssert(handler != nil, @"Handler should not be nil.");
	
	if (self.didReceiveResponse) {
		handler(self.returnedResponse);
		return;
	}
	
	__weak DCTConnectionController *weakSelf = self;
	
	[self addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusResponded)
			handler(weakSelf.returnedResponse);
	}];
}

- (void)addFinishHandler:(DCTConnectionControllerFinishBlock)handler {
	
	NSAssert(handler != nil, @"Handler should not be nil.");
	
	if (self.finished) {
		handler();
		return;
	}
	
	[self addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusFinished)
			handler();
	}];
}

- (void)addFailureHandler:(DCTConnectionControllerFailureBlock)handler {
	
	NSAssert(handler != nil, @"Handler should not be nil.");
	
	if (self.failed) {
		handler(self.returnedError);
		return;
	}
	
	__weak DCTConnectionController *weakSelf = self;
	
	[self addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusFailed)
			handler(weakSelf.returnedError);
	}];
}

- (void)addCancelationHandler:(DCTConnectionControllerCancelationBlock)handler {
	
	NSAssert(handler != nil, @"Handler should not be nil.");
	
	if (self.cancelled) {
		handler();
		return;
	}
	
	[self addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
		if (status == DCTConnectionControllerStatusCancelled)
			handler();		
	}];	
}



@end
