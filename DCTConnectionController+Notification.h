//
//  DCTConnectionController+Notification.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 09.12.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"

/** Name of the notification sent out when the connection has successfully completed.
 */
extern NSString *const DCTConnectionControllerDidFinishNotification;

/** Name of the notification sent out when the connection has failed.
 */
extern NSString *const DCTConnectionControllerDidFailNotification;

/** Name of the notification sent out when the connection has recieved a response.
 */
extern NSString *const DCTConnectionControllerDidReceiveResponseNotification;

extern NSString *const DCTConnectionControllerWasCancelledNotification;

extern NSString *const DCTConnectionControllerStatusChangedNotification;

@interface DCTConnectionController (Notification)

@end
