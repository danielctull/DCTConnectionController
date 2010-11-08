//
//  DTNetworkQueue.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTConnectionController.h"

extern NSString *const DCTConnectionQueueConnectionCountChangedNotification;

@interface DCTConnectionQueue : NSObject {
    NSMutableArray *activeConnections;
	NSMutableArray *queuedConnections;
	NSInteger lastActiveConnectionCount;
	BOOL active;
}

- (void)removeConnectionController:(DCTConnectionController *)connectionController;
- (void)addConnectionController:(DCTConnectionController *)connectionController;
- (void)requeueConnectionController:(DCTConnectionController *)connectionController;

- (NSArray *)connectionControllers;

- (BOOL)isConnectingToURL:(NSURL *)URL;
- (BOOL)hasQueuedConnectionControllerToURL:(NSURL *)URL;
- (DCTConnectionController *)queuedConnectionControllerToURL:(NSURL *)URL;

- (void)stop;
- (void)start;

@property (nonatomic, assign) NSInteger maxConnections;

@property (nonatomic, readonly) NSInteger activeConnectionsCount;
@property (nonatomic, readonly) NSInteger queuedConnectionsCount;
@property (nonatomic, readonly) NSInteger connectionCount;


@property (nonatomic, readonly) NSArray *activeConnectionControllers, *queuedConnectionControllers;

@end
