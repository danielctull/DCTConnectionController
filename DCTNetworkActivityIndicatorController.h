//
//  DCTNetworkActivityIndicatorController.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 07.08.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const DCTNetworkActivityIndicatorControllerNetworkActivityChangedNotification;

@interface DCTNetworkActivityIndicatorController : NSObject

+ (DCTNetworkActivityIndicatorController *)sharedNetworkActivityIndicatorController;

@property (nonatomic, readonly) NSUInteger networkActivity;

- (void)decrementNetworkActivity;
- (void)incrementNetworkActivity;

@end
