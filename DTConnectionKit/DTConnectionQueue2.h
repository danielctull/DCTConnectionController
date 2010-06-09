//
//  DTConnectionQueue2.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnection2.h"

@interface DTConnectionQueue2 : NSObject {

}
+ (DTConnectionQueue2 *)sharedConnectionQueue;

- (void)addConnection:(DTConnection2 *)connection;

- (NSArray *)connections;

- (BOOL)isConnectingToURL:(NSURL *)URL;
- (BOOL)hasQueuedConnectionToURL:(NSURL *)URL;
- (DTConnection2 *)queuedConnectionToURL:(NSURL *)URL;

- (void)incrementExternalConnectionCount;
- (void)decrementExternalConnectionCount;

@property (nonatomic, assign) NSInteger maxConnections;
@property (nonatomic, readonly) NSInteger connectionCount;

@end
