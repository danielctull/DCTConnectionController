//
//  DCTConnectionController+UsefulChecks.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 06.08.2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController+UsefulChecks.h"

@implementation DCTConnectionController (UsefulChecks)

- (BOOL)didReceiveResponse {
	return (self.status >= DCTConnectionControllerStatusResponded);
}

- (BOOL)isFailed {
	return (self.status == DCTConnectionControllerStatusFailed);
}

- (BOOL)isFinished {
	return (self.status == DCTConnectionControllerStatusFinished);
}

- (BOOL)isCancelled {
	return (self.status == DCTConnectionControllerStatusCancelled);
}

- (BOOL)isActive {
	return (self.status >= DCTConnectionControllerStatusStarted && self.status <= DCTConnectionControllerStatusResponded);
}

- (BOOL)isEnded {
	return (self.status > DCTConnectionControllerStatusResponded);
}

- (BOOL)isStarted {
	return (self.status >= DCTConnectionControllerStatusQueued);
}

@end
