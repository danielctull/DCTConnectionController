//
//  DTConnectionManager.m
//  DTKit
//
//  Created by Daniel Tull on 17.09.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTConnectionManager.h"
#import "DTConnectionController.h"


NSString *const DTConnectionManagerConnectionCountChangedNotification = @"DTConnectionManagerConnectionCountChangedNotification";

@interface DTConnectionManager ()
- (NSArray *)delegates;
- (NSArray *)connections;
- (id<DTConnectionManagerDelegate>)delegateForConnection:(DTURLConnection *)connection;
- (void)connectionsCountChanged;
@end

static DTConnectionManager *sharedInstance = nil;

@implementation DTConnectionManager

@synthesize maxConnections;

#pragma mark -
#pragma mark Methods for Singleton use

+ (void)initialize {
    if (!sharedInstance) {
        sharedInstance = [[self alloc] init];
    }
}

+ (DTConnectionManager *)sharedConnectionManager {
    //Already set by +initialize.
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    //Usually already set by +initialize.
    if (sharedInstance) {
        //The caller expects to receive a new object, so implicitly retain it to balance out the caller's eventual release message.
        return [sharedInstance retain];
    } else {
        //When not already set, +initialize is our caller—it's creating the shared instance. Let this go through.
        return [super allocWithZone:zone];
    }
}

#pragma mark -

- (id)init {
	if (!([super init])) return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
	
	connectionDictionary = [[NSMutableDictionary alloc] init];
	internalConnections = [[NSMutableArray alloc] init];
	requestQueue = [[DTQueue alloc] init];
	delegateQueue = [[DTQueue alloc] init];
	maxConnections = 0;
	
	return self;
}

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	for (DTURLConnection *connection in internalConnections)
		[connection cancel];
	
	[requestQueue release];
	[delegateQueue release];
	[internalConnections release];
	[connectionDictionary release];
	[super dealloc];
}

+ (NSArray *)delegates {
	return [[DTConnectionManager sharedConnectionManager] delegates];
}

- (NSArray *)delegates {
	return [connectionDictionary allValues];
}

+ (id<DTConnectionManagerDelegate>)delegateForConnection:(DTURLConnection *)connection {
	return [[DTConnectionManager sharedConnectionManager] delegateForConnection:connection];
}

- (id<DTConnectionManagerDelegate>)delegateForConnection:(DTURLConnection *)connection {
	return [connectionDictionary objectForKey:connection.identifier];
}

+ (NSArray *)connections {
	return [[DTConnectionManager sharedConnectionManager] connections];
}

- (NSArray *)connections {
	return [NSArray arrayWithArray:internalConnections];
}

- (NSInteger)connectionCount {
	return [self.connections count] + externalConnectionsCount;
}

+ (DTURLConnection *)makeRequest:(NSURLRequest *)request delegate:(id<DTConnectionManagerDelegate>)delegate {
	return [[DTConnectionManager sharedConnectionManager] makeRequest:request delegate:delegate];
}

- (DTURLConnection *)makeRequest:(NSURLRequest *)request delegate:(id<DTConnectionManagerDelegate>)delegate {
	
	if (self.maxConnections != 0 && [internalConnections count] >= self.maxConnections) {
		[requestQueue push:request];
		[delegateQueue push:delegate];
		if ([(NSObject *)delegate respondsToSelector:@selector(connectionManager:didQueueRequest:)])
			[delegate connectionManager:self didQueueRequest:request];
		return nil;
	}
	
	DTURLConnection *connection = [[DTURLConnection alloc] initWithRequest:request delegate:self];
	if ([(NSObject *)delegate respondsToSelector:@selector(connectionManager:didStartConnection:)])
		[delegate connectionManager:self didStartConnection:connection];
	
	[connectionDictionary setObject:delegate forKey:connection.identifier];
	[internalConnections addObject:connection];
	[self connectionsCountChanged];
	return [connection autorelease];
}

- (void)connectionsCountChanged {
	
	if (self.maxConnections != 0 && [requestQueue count] > 0 && [internalConnections count] < self.maxConnections)
		[self makeRequest:[requestQueue pop] delegate:[delegateQueue pop]];
	
	if (([[connectionDictionary allKeys] count] + externalConnectionsCount) > 0)
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	else
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionManagerConnectionCountChangedNotification object:self];
}

- (BOOL)isConnectingToURL:(NSURL *)aUrl {
	for (DTURLConnection *conn in self.connections)
		if ([[conn.URL absoluteString] isEqualToString:[aUrl absoluteString]])
			return YES;
	
	return NO;
}

- (void)addExternalConnection {
	externalConnectionsCount++;
	[self connectionsCountChanged];
}

- (void)removeExternalConnection {
	if (externalConnectionsCount > 0) {
		externalConnectionsCount--;
		[self connectionsCountChanged];
	}
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	DTURLConnection *dtconnection = (DTURLConnection *)connection;
	
	id theDelegate = [connectionDictionary objectForKey:dtconnection.identifier];
	if ([theDelegate respondsToSelector:@selector(connectionManager:connection:didReceiveResponse:)])
		[theDelegate connectionManager:self connection:dtconnection didReceiveResponse:response];
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)someData {
	[(DTURLConnection *)aConnection appendData:someData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	DTURLConnection *dtconnection = (DTURLConnection *)connection;
	
	id theDelegate = [[connectionDictionary objectForKey:dtconnection.identifier] retain];
	[connectionDictionary removeObjectForKey:dtconnection.identifier];
	[internalConnections removeObject:dtconnection];
	
	if ([theDelegate respondsToSelector:@selector(connectionManager:connection:didFailWithError:)])
		[theDelegate connectionManager:self connection:dtconnection didFailWithError:error];
	
	[theDelegate release];
	[self connectionsCountChanged];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	DTURLConnection *dtconnection = (DTURLConnection *)connection;
	
	id theDelegate = [[connectionDictionary objectForKey:dtconnection.identifier] retain];
	[connectionDictionary removeObjectForKey:dtconnection.identifier];
	[internalConnections removeObject:dtconnection];
	if ([theDelegate respondsToSelector:@selector(connectionManager:connectionDidFinishLoading:)])
		[theDelegate connectionManager:self connectionDidFinishLoading:dtconnection];	
	
	[theDelegate release];
	[self connectionsCountChanged];
}

- (void)applicationWillTerminate:(id)sender {
	[self release];
}


@end
