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
	
	DTQueue *requestQueue;
	NSMutableDictionary *queuedDelegates, *queuedRequests;
	
	NSInteger maxConnections, externalConnectionsCount;
	
	DTDataStore *dataStore;
}

#pragma mark -
#pragma mark Getting the Connection Manager
/** @name Getting the Connection Manager
 @{
 */

/** @brief Returns the shared connection manager object for the system.
 
 @return The systemwide connection manager object.
 */
+ (DTConnectionManager *)sharedConnectionManager;

/**
 @}
 */

#pragma mark -
#pragma mark Connection Manager Settings
/** @name Connection Manager Settings
 @{
 */

/** @brief The maximum number of connections to perform at any given time.
 */
@property (nonatomic, assign) NSInteger maxConnections;

/**
 @}
 */

#pragma mark -
#pragma mark Making requests
/** @name Making requests
 @{
 */

/** @brief Initialises a newly created DTConnectionController with the given type and delegate.
 
 DTConnectionManager handles many delegates (one for each connection), so making a new connection will assign this delegate to 
 the returned connection object. 
 
 @param request The request for the connection.
 @param delegate The delegate for the connection.
 @return A DTURLConnection object initialised with the request. This can return nil in the case where the request has been queued.
 */
- (NSString *)makeRequest:(NSURLRequest *)request delegate:(id<DTConnectionManagerDelegate>)delegate;

/**
 @}
 */

#pragma mark -
#pragma mark Managing External Connections

/** @name Managing External Connections
 @{
 */

/** @brief Removes one from the external connections counter.
 
 If you perform connections outside of the connection manager, use this method to make the manger
 keep track of these, so that the activity indicator displays for these separate connections.
 
 */
- (void)addExternalConnection;

/** @brief Removes one from the external connections counter.
 */
- (void)removeExternalConnection;

/**
 @}
 */

#pragma mark -
#pragma mark Information about connections
/** @name Information about connections
 @{
 */

/** @brief The number of connections being performed both internally by the manager and externally.
 
 There is an external connections count that can be altered using -addExternalConnection and
 -removeExternalConnection. This enables raw socket connections to be made, while still allowing the
 connection manager to handle the activity indicator.
 */
@property (nonatomic, readonly) NSInteger connectionCount;

/** @brief Used to determine whether the connection manager already has a connection in progress to the given URL.
 
 @param URL The URL to check for.
 
 @return A boolean indicating whether a request is in progress to the URL.
 */
- (BOOL)isConnectingToURL:(NSURL *)URL;

/** @brief Gives the URL of a connection with the given connection identifier.
 
 @param connectionID The identifier of the connection.
 
 @return The URL for the connection with the given identifier.
 */
- (NSURL *)URLForConnectionID:(NSString *)connectionID;
/**
 @}
 */


- (NSData *)cachedDataForURL:(NSURL *)URL;
@end

#pragma mark -
/** The delegates DTConnectionManager must adopt the DTConnectionManagerDelegate protocol.
 */
@protocol DTConnectionManagerDelegate
#pragma mark -
#pragma mark Connection Completion
/** @name Connection Completion
 @{
 */

/** @brief Tells the delegate the connection failed.
 
 @param connectionManager The connection manager.
 @param connectionID The identifier of the connection.
 @param error The received error from the connection.
 */
- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didFailWithError:(NSError *)error;

/** @brief Tells the delegate the connection succeeded.
 
 @param connectionManager The connection manager.
 @param connectionID The identifier of the connection.
 @param data The received data from the connection.
 */
- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didFinishLoadingData:(NSData *)data;
/**
 @}
 */
#pragma mark -
#pragma mark Connection Response
/** @name Connection Response
 @{
 */
@optional

/** @brief Tells the delegate the connection got a response.
 
 @param connectionManager The connection manager.
 @param connectionID The identifier of the connection.
 @param response The received response from the connection.
 */
- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didReceiveResponse:(NSURLResponse *)response;

/**
 @}
 */
#pragma mark -
#pragma mark Queueing Connections
/** @name Queueing Connections
 @{
 */

/** @brief Tells the delegate the connection request has been queued.
 
 @param connectionManager The connection manager.
 @param connectionID The identifier of the connection.
 @param request The request that has been queued.
 */
- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didQueueRequest:(NSURLRequest *)request;

/** @brief Tells the delegate the connection has started.
 
 @param connectionManager The connection manager.
 @param connectionID The identifier of the connection.
 */
- (void)connectionManager:(DTConnectionManager *)connectionManager didStartConnectionID:(NSString *)connectionID;
/**
 @}
 */
@end
