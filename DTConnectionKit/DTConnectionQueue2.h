//
//  DTNetworkQueue.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnection2.h"

extern NSString *const DTConnectionQueue2ConnectionCountChangedNotification;

@interface DTConnectionQueue2 : NSObject {
    NSMutableArray *activeConnections;
	NSMutableArray *queuedConnections;
	NSInteger lastActiveConnectionCount;
}
+ (DTConnectionQueue2 *)sharedConnectionQueue;

- (void)addConnection:(DTConnection2 *)connection;

- (NSArray *)connections;

- (BOOL)isConnectingToURL:(NSURL *)URL;
- (BOOL)hasQueuedConnectionToURL:(NSURL *)URL;
- (DTConnection2 *)queuedConnectionToURL:(NSURL *)URL;

@property (nonatomic, assign) NSInteger maxConnections;
@property (nonatomic, readonly) NSInteger activeConnectionsCount;
@property (nonatomic, readonly) NSInteger queuedConnectionsCount;
@property (nonatomic, readonly) NSInteger connectionCount;

#pragma mark -
#pragma mark Depricated

- (void)incrementExternalConnectionCount;
- (void)decrementExternalConnectionCount;

@end
