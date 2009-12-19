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
#import "DTDataStore.h"

#pragma mark Notification Names

extern NSString *const DTConnectionManagerConnectionCountChangedNotification;

#pragma mark -

@protocol DTConnectionManagerDelegate;

#pragma mark -

@interface DTConnectionManager : NSObject {
	NSMutableDictionary *connectionDictionary;
	NSMutableArray *internalConnections;
	DTQueue *requestQueue, *delegateQueue;
	NSInteger maxConnections, externalConnectionsCount;
	DTDataStore *dataStore;
}
@property (nonatomic, assign) NSInteger maxConnections;
@property (nonatomic, readonly) NSArray *delegates;
@property (nonatomic, readonly) NSArray *connections;
@property (nonatomic, readonly) NSInteger connectionCount;

/** Removes one from the external connections counter.
 
 If you perform connections outside of the connection manager, use this method to make the manger
 keep track of these, so that the activity indicator displays for these separate connections.
 
 */
- (void)addExternalConnection;

/** Removes one from the external connections counter.
 
 */
- (void)removeExternalConnection;

/** Returns the shared connection manager object for the system.
 
 @return The systemwide connection manager object.
 */
+ (DTConnectionManager *)sharedConnectionManager;

/** Class method which returns the result of the delegates property of the sharedConnectionManager.
 
 @return An array of all the objects that are currently delegates for connections in progress.
 */
+ (NSArray *)delegates;

/** Class method which returns the result of the connections property of the sharedConnectionManager.
 
 @return An array of all the connections in progress.
 */
+ (NSArray *)connections;


+ (id<DTConnectionManagerDelegate>)delegateForConnection:(DTURLConnection *)connection;

/** Initialises a newly created DTConnectionController with the given type and delegate.
 
 DTConnectionManager handles many delegates (one for each connection), so making a new connection will assign this delegate to 
 the returned connection object.
 
 @return A DTURLConnection object initialised with the request. This can return nil in the case where the request has been queued.
 */
+ (DTURLConnection *)makeRequest:(NSURLRequest *)request delegate:(id<DTConnectionManagerDelegate>)delegate;

/** Initialises a newly created DTConnectionController with the given type and delegate.
 
 DTConnectionManager handles many delegates (one for each connection), so making a new connection will assign this delegate to 
 the returned connection object. 
 
 @param request The request for the connection.
 @param delegate The delegate for the connection.
 @return A DTURLConnection object initialised with the request. This can return nil in the case where the request has been queued.
 */
- (DTURLConnection *)makeRequest:(NSURLRequest *)request delegate:(id<DTConnectionManagerDelegate>)delegate;


/** Initialises a newly created DTConnectionController with the given type and delegate.
 
 DTConnectionManager handles many delegates (one for each connection), so making a new connection will assign this delegate to 
 the returned connection object. 
 
 @param request The request for the connection.
 @param delegate The delegate for the connection.
 @return A boolean indicating whether a request is in progress to the URL
 */
- (BOOL)isConnectingToURL:(NSURL *)aUrl;

+ (NSData *)cachedDataForURL:(NSURL *)URL;
- (NSData *)cachedDataForURL:(NSURL *)URL;
@end

#pragma mark -
/** The delegates DTConnectionManager must adopt the DTConnectionManagerDelegate protocol.
 */
@protocol DTConnectionManagerDelegate
- (void)connectionManager:(DTConnectionManager *)connectionManager connection:(DTURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionManager:(DTConnectionManager *)connectionManager connectionDidFinishLoading:(DTURLConnection *)connection;
@optional
- (void)connectionManager:(DTConnectionManager *)connectionManager connection:(DTURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connectionManager:(DTConnectionManager *)connectionManager didQueueRequest:(NSURLRequest *)request;
- (void)connectionManager:(DTConnectionManager *)connectionManager didStartConnection:(DTURLConnection *)connection;
@end
