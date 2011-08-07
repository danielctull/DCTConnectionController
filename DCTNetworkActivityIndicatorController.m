//
//  DCTNetworkActivityIndicatorController.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 07.08.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTNetworkActivityIndicatorController.h"
#import "NSObject+DCTKVOExtras.h"

// These tie to DCTConnectionQueue
NSString *const DCTNetworkActivityIndicatorControllerConnectionQueueActiveConnectionCountIncreasedNotification = @"DCTConnectionQueueActiveConnectionCountIncreasedNotification";
NSString *const DCTNetworkActivityIndicatorControllerConnectionQueueActiveConnectionCountDecreasedNotification = @"DCTConnectionQueueActiveConnectionCountDecreasedNotification";

NSString *const DCTNetworkActivityIndicatorControllerNetworkActivityKey = @"networkActivity";
NSString *const DCTNetworkActivityIndicatorControllerNetworkActivityChangedNotification = @"DCTNetworkActivityIndicatorControllerNetworkActivityChangedNotification";

static DCTNetworkActivityIndicatorController *sharedInstance = nil;

@interface DCTNetworkActivityIndicatorController ()
- (void)dctInternal_calculateNetworkActivity;
@end

@implementation DCTNetworkActivityIndicatorController

@synthesize networkActivity;

+ (DCTNetworkActivityIndicatorController *)sharedNetworkActivityIndicatorController {
	
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		sharedInstance = [[self alloc] init];
	});
	
    return sharedInstance;
}

- (id)init {
    
    if (!(self = [super init])) return nil;
    
	networkActivity = 0;
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(incrementNetworkActivity) name:DCTNetworkActivityIndicatorControllerConnectionQueueActiveConnectionCountIncreasedNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(decrementNetworkActivity) name:DCTNetworkActivityIndicatorControllerConnectionQueueActiveConnectionCountDecreasedNotification object:nil];
	
	return self;
}

- (void)dealloc {
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter removeObserver:self name:DCTNetworkActivityIndicatorControllerConnectionQueueActiveConnectionCountIncreasedNotification object:nil];
	[notificationCenter removeObserver:self name:DCTNetworkActivityIndicatorControllerConnectionQueueActiveConnectionCountDecreasedNotification object:nil];
}

- (void)decrementNetworkActivity {
	
	NSAssert((networkActivity > 0), @"%@ increment/decrement calls mismatch", self);
	
	[self dct_changeValueForKey:DCTNetworkActivityIndicatorControllerNetworkActivityKey withChange:^() {
		networkActivity--;
	}];
	
	[self dctInternal_calculateNetworkActivity];
}

- (void)incrementNetworkActivity {
	
	[self dct_changeValueForKey:DCTNetworkActivityIndicatorControllerNetworkActivityKey withChange:^() {
		networkActivity++;
	}];
	
	[self dctInternal_calculateNetworkActivity];
}

- (void)dctInternal_calculateNetworkActivity {
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTNetworkActivityIndicatorControllerNetworkActivityChangedNotification object:self];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(networkActivity > 0)];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ %p; networkActivity = %i>", NSStringFromClass([self class]), self, self.networkActivity];
}

@end
