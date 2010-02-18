//
//  DTConnectionQueue.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 23.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnection.h"

extern NSString *const DTConnectionQueueConnectionCountChangedNotification;

@interface DTConnectionQueue : NSOperationQueue {
	NSInteger externalConnections;
}

+ (DTConnectionQueue *)sharedConnectionQueue;

- (void)addConnection:(DTConnection *)connection;

- (BOOL)isConnectingToURL:(NSURL *)URL;
- (BOOL)hasQueuedConnectionToURL:(NSURL *)URL;
- (DTConnection *)queuedConnectionToURL:(NSURL *)URL;

- (void)incrementExternalConnectionCount;
- (void)decrementExternalConnectionCount;

@property (nonatomic, assign) NSInteger maxConnections;
@property (nonatomic, readonly) NSInteger connectionCount;
@end
