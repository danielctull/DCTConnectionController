//
//  DTConnectionManager.h
//  DTKit
//
//  Created by Daniel Tull on 17.09.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTURLConnection.h"
#import "DTQueue.h"

@protocol DTConnectionManagerDelegate;

@interface DTConnectionManager : NSObject {
	NSMutableDictionary *connectionDictionary;
	NSMutableArray *internalConnections;
	DTQueue *requestQueue, *delegateQueue;
	NSInteger maxConnections;
}
@property (nonatomic, assign) NSInteger maxConnections;
@property (nonatomic, readonly) NSArray *delegates;
@property (nonatomic, readonly) NSArray *connections;

+ (DTConnectionManager *)sharedConnectionManager;
+ (NSArray *)delegates;
+ (NSArray *)connections;
+ (id)delegateForConnection:(DTURLConnection *)connection;

+ (DTURLConnection *)makeRequest:(NSURLRequest *)request delegate:(id<DTConnectionManagerDelegate>)delegate;
- (DTURLConnection *)makeRequest:(NSURLRequest *)request delegate:(id<DTConnectionManagerDelegate>)delegate;
- (void)connectionsCountChanged;

- (BOOL)isConnectingToURL:(NSURL *)aUrl;


@end

@protocol DTConnectionManagerDelegate
- (void)connectionManager:(DTConnectionManager *)connectionManager connection:(DTURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionManager:(DTConnectionManager *)connectionManager connectionDidFinishLoading:(DTURLConnection *)connection;
@optional
- (void)connectionManager:(DTConnectionManager *)connectionManager connection:(DTURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connectionManager:(DTConnectionManager *)connectionManager didQueueRequest:(NSURLRequest *)request;
- (void)connectionManager:(DTConnectionManager *)connectionManager didStartConnection:(DTURLConnection *)connection;
@end
