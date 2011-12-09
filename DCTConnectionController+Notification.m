//
//  DCTConnectionController+Notification.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 09.12.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController+Notification.h"

NSString *const DCTConnectionControllerDidFinishNotification = @"DCTConnectionControllerDidFinishNotification";
NSString *const DCTConnectionControllerDidFailNotification = @"DCTConnectionControllerDidFailNotification";
NSString *const DCTConnectionControllerDidReceiveResponseNotification = @"DCTConnectionControllerDidReceiveResponseNotification";
NSString *const DCTConnectionControllerWasCancelledNotification = @"DCTConnectionControllerWasCancelledNotification";
NSString *const DCTConnectionControllerStatusChangedNotification = @"DCTConnectionControllerStatusChangedNotification";

@implementation DCTConnectionController (Notification)

+ (void)load {
	
	[self addInitBlock:^(DCTConnectionController *connectionController) {
		
		__dct_weak DCTConnectionController *weakConnectionController = connectionController;
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		
		[connectionController addCancelationHandler:^{
			[notificationCenter postNotificationName:DCTConnectionControllerWasCancelledNotification object:weakConnectionController];
		}];
		
		[connectionController addFailureHandler:^(NSError *error) {
			[notificationCenter postNotificationName:DCTConnectionControllerDidFailNotification object:weakConnectionController];
		}];
		
		[connectionController addFinishHandler:^{
			[notificationCenter postNotificationName:DCTConnectionControllerDidFinishNotification object:weakConnectionController];
		}];
		
		[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
			[notificationCenter postNotificationName:DCTConnectionControllerStatusChangedNotification object:weakConnectionController];
		}];
		
		[connectionController addResponseHandler:^(NSURLResponse *response) {
			[notificationCenter postNotificationName:DCTConnectionControllerDidReceiveResponseNotification object:weakConnectionController];
		}];	
		
	}];
	
}

@end
