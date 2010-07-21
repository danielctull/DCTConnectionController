//
//  DTNetworkQueue.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DTConnectionController.h"

extern NSString *const DTConnectionQueueConnectionCountChangedNotification;

@interface DTConnectionQueue : NSObject {
    NSMutableArray *activeConnections;
	NSMutableArray *queuedConnections;
	NSInteger lastActiveConnectionCount;
	BOOL active;
	
	NSMutableArray *backgroundConnections;
	UIBackgroundTaskIdentifier backgroundTaskIdentifier;
	BOOL inBackground;
}

- (void)addConnectionController:(DTConnectionController *)connectionController;
- (void)requeueConnectionController:(DTConnectionController *)connectionController;

- (NSArray *)connectionControllers;

- (BOOL)isConnectingToURL:(NSURL *)URL;
- (BOOL)hasQueuedConnectionControllerToURL:(NSURL *)URL;
- (DTConnectionController *)queuedConnectionControllerToURL:(NSURL *)URL;

- (void)stop;
- (void)start;

@property (nonatomic, assign) NSInteger maxConnections;
@property (nonatomic, assign) BOOL multitaskEnabled;

@property (nonatomic, readonly) NSInteger activeConnectionsCount;
@property (nonatomic, readonly) NSInteger queuedConnectionsCount;
@property (nonatomic, readonly) NSInteger connectionCount;

#pragma mark -
#pragma mark Depricated

- (void)incrementExternalConnectionCount;
- (void)decrementExternalConnectionCount;

@end
