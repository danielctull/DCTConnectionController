//
//  DCTConnectionController+UsefulChecks.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 06.08.2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"

@interface DCTConnectionController (UsefulChecks)

@property (nonatomic, readonly) BOOL didReceiveResponse;
@property (nonatomic, readonly, getter = isFinished) BOOL finished;
@property (nonatomic, readonly, getter = isFailed) BOOL failed;
@property (nonatomic, readonly, getter = isCancelled) BOOL cancelled;
@property (nonatomic, readonly, getter = isActive) BOOL active;

@end
