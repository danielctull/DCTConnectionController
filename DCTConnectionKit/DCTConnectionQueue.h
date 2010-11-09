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
extern NSString *const DCTConnectionQueueActiveConnectionCountChangedNotification;

@interface DCTConnectionQueue : NSObject {
    NSMutableArray *activeConnections;
	NSMutableArray *queuedConnections;
	BOOL active;
	NSInteger externalConnectionCount;
	NSInteger connectionCount;
	
	NSArray *externalConnectionCountKeys;
}

/**
 Add a connection controller to the queue. This method causes the connection queue to
 find the next connection and run it.
 */
- (DCTConnectionController *)addConnectionController:(DCTConnectionController *)connectionController;

/**
 
 */
- (void)removeConnectionController:(DCTConnectionController *)connectionController;
- (void)requeueConnectionController:(DCTConnectionController *)connectionController;

- (BOOL)isConnectingToURL:(NSURL *)URL;
- (BOOL)hasQueuedConnectionControllerToURL:(NSURL *)URL;
- (DCTConnectionController *)queuedConnectionControllerToURL:(NSURL *)URL;

- (void)stop;
- (void)pause;
- (void)start;

@property (nonatomic, assign) NSInteger maxConnections;

@property (nonatomic, readonly) NSInteger connectionCount, activeConnectionCount;
@property (nonatomic, readonly) NSArray *activeConnectionControllers;
@property (nonatomic, readonly) NSArray *queuedConnectionControllers;
@property (nonatomic, readonly) NSArray *connectionControllers;

- (void)incrementExternalConnectionCount;
- (void)decrementExternalConnectionCount;

@end
