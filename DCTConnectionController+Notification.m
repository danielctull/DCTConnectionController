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
		
		[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
			
			[notificationCenter postNotificationName:DCTConnectionControllerStatusChangedNotification object:weakConnectionController];
			
			switch (status) {
				case DCTConnectionControllerStatusResponded:
					[notificationCenter postNotificationName:DCTConnectionControllerDidReceiveResponseNotification object:weakConnectionController];
					break;
									
				case DCTConnectionControllerStatusCancelled:
					[notificationCenter postNotificationName:DCTConnectionControllerWasCancelledNotification object:weakConnectionController];
					break;
					
				case DCTConnectionControllerStatusFinished:
					[notificationCenter postNotificationName:DCTConnectionControllerDidFinishNotification object:weakConnectionController];
					break;
					
				case DCTConnectionControllerStatusFailed:
					[notificationCenter postNotificationName:DCTConnectionControllerDidFailNotification object:weakConnectionController];
					break;
					
				default:
					break;
			}
		}];
	}];
}

@end
