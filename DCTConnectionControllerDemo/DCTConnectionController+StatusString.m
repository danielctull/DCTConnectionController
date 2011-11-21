//
//  DCTConnectionController+StatusString.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 21.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController+StatusString.h"

NSString * const DCTConnectionControllerStatusString[] = {
	@"Not Started",
	@"Queued",
	@"Started",
	@"Responded",
	@"Finished",
	@"Failed",
	@"Cancelled"
};

@implementation DCTConnectionController (StatusString)

- (NSString *)statusString {
	return DCTConnectionControllerStatusString[self.status];
}

@end
