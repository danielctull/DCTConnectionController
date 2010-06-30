//
//  DTNetworkQueue.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnection.h"

extern NSString *const DTConnectionQueueConnectionCountChangedNotification;

@interface DTConnectionQueue : NSObject {
    NSMutableArray *activeConnections;
	NSMutableArray *queuedConnections;
	NSInteger lastActiveConnectionCount;
}
+ (DTConnectionQueue *)sharedConnectionQueue;

- (void)addConnection:(DTConnection *)connection;

- (NSArray *)connections;

- (BOOL)isConnectingToURL:(NSURL *)URL;
- (BOOL)hasQueuedConnectionToURL:(NSURL *)URL;
- (DTConnection *)queuedConnectionToURL:(NSURL *)URL;

@property (nonatomic, assign) NSInteger maxConnections;
@property (nonatomic, readonly) NSInteger activeConnectionsCount;
@property (nonatomic, readonly) NSInteger queuedConnectionsCount;
@property (nonatomic, readonly) NSInteger connectionCount;

#pragma mark -
#pragma mark Depricated

- (void)incrementExternalConnectionCount;
- (void)decrementExternalConnectionCount;

@end
