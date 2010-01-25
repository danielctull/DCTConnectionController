//
//  DTConnectionManager.m
//  DTKit
//
//  Created by Daniel Tull on 17.09.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "DTConnectionManager.h"
#import "DTConnectionController.h"


NSString *const DTConnectionManagerConnectionCountChangedNotification = @"DTConnectionManagerConnectionCountChangedNotification";

NSString *const DTConnectionHeaderIfModifiedSince = @"If-Modified-Since";
NSString *const DTConnectionHeaderIfNoneMatch = @"If-None-Match";
NSString *const DTConnectionHeaderEtag = @"Etag";
NSString *const DTConnectionHeaderLastModified = @"Last-Modified";
NSString *const DTConnectionHeaderCacheControl = @"Cache-Control";

@interface DTConnectionManager ()
- (void)connectionsCountChanged;
- (NSString *)makeRequest:(NSURLRequest *)request delegate:(id<DTConnectionManagerDelegate>)delegate identifier:(NSString *)identifier;
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	
	connectionDictionary = [[NSMutableDictionary alloc] init];
	
	// QUEUE
	requestQueue = [[DTQueue alloc] init];
	queuedDelegates = [[NSMutableDictionary alloc] init];
	queuedRequests = [[NSMutableDictionary alloc] init];
	maxConnections = 0;
	
	// CACHE
	dataStore = [[DTDataStore alloc] initWithName:@"DTConnectionCache"];
	
	return self;
}

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	for (DTURLConnection *connection in [connectionDictionary allValues])
		[connection cancel];
	
	[dataStore release];
	[requestQueue release];
	[queuedRequests release];
	[queuedDelegates release];
	[connectionDictionary release];
	[super dealloc];
}

- (NSInteger)connectionCount {
	return [connectionDictionary count] + externalConnectionsCount;
}

- (NSString *)makeRequest:(NSURLRequest *)request delegate:(id<DTConnectionManagerDelegate>)delegate {
	return [self makeRequest:request delegate:delegate identifier:nil];
}

- (void)cancelConnectionWithID:(NSString *)connectionID {
	DTURLConnection *connection = [connectionDictionary objectForKey:connectionID];
	
	if (connection) {
		[connection cancel];
		[connectionDictionary removeObjectForKey:connectionID];
	}
	
	NSURLRequest *request = [queuedRequests objectForKey:connectionID];
	
	if (request) {
		[queuedDelegates removeObjectForKey:connectionID];
		[queuedRequests removeObjectForKey:connectionID];
	}
}

- (NSURL *)URLForConnectionID:(NSString *)connectionID {
	NSURL *URL = ((DTURLConnection *)[connectionDictionary objectForKey:connectionID]).URL;
	
	if (URL) return URL;
	
	return [(NSURLRequest *)[queuedRequests objectForKey:connectionID] URL];
}

- (BOOL)isConnectingToURL:(NSURL *)aUrl {
	for (DTURLConnection *conn in [connectionDictionary allValues])
		if ([[conn.URL absoluteString] isEqualToString:[aUrl absoluteString]])
			return YES;
	
	return NO;
}

#pragma mark -
#pragma mark External Connections methods

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
#pragma mark Caching methods

- (NSData *)cachedDataForURL:(NSURL *)URL {
	return nil;
}

#pragma mark -
#pragma mark Private methods

- (NSString *)makeRequest:(NSURLRequest *)request delegate:(id<DTConnectionManagerDelegate>)delegate identifier:(NSString *)identifier {
	
	if (self.maxConnections != 0 && [connectionDictionary count] >= self.maxConnections) {
		
		if (!identifier) identifier = [[NSProcessInfo processInfo] globallyUniqueString];
		
		[requestQueue push:identifier];
		[queuedRequests setObject:request forKey:identifier];
		[queuedDelegates setObject:delegate forKey:identifier];
		
		if ([(NSObject *)delegate respondsToSelector:@selector(connectionManager:connectionID:didQueueRequest:)])
			[delegate connectionManager:self connectionID:identifier didQueueRequest:request];
		
		return identifier;
	}
	
	DTURLConnection *connection = [[[DTURLConnection alloc] initWithRequest:request delegate:self identifier:identifier] autorelease];
	
	if ([(NSObject *)delegate respondsToSelector:@selector(connectionManager:didStartConnectionID:)])
		[delegate connectionManager:self didStartConnectionID:connection.identifier];
	
	[connectionDictionary setObject:delegate forKey:connection.identifier];
	[self connectionsCountChanged];
	return connection.identifier;
}

- (void)connectionsCountChanged {
	
	if (self.maxConnections != 0 && [requestQueue count] > 0 && [connectionDictionary count] < self.maxConnections) {
		
		NSString *identifier = [requestQueue pop];
		
		NSURLRequest *request = [[queuedRequests objectForKey:identifier] retain];
		[queuedRequests removeObjectForKey:identifier];
		
		id<DTConnectionManagerDelegate> delegate = [[queuedDelegates objectForKey:identifier] retain];
		[queuedDelegates removeObjectForKey:identifier];
		
		[self makeRequest:request delegate:delegate];		
		[request release];
		[(NSObject *)delegate release];
	}
	
	if (([[connectionDictionary allKeys] count] + externalConnectionsCount) > 0)
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	else
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionManagerConnectionCountChangedNotification object:self];
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	DTURLConnection *dtconnection = (DTURLConnection *)connection;
	
	id theDelegate = [connectionDictionary objectForKey:dtconnection.identifier];
	if ([theDelegate respondsToSelector:@selector(connectionManager:connectionID:didReceiveResponse:)])
		[theDelegate connectionManager:self connectionID:dtconnection.identifier didReceiveResponse:response];
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)someData {
	[(DTURLConnection *)aConnection appendData:someData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	DTURLConnection *dtconnection = (DTURLConnection *)connection;
	
	id theDelegate = [[connectionDictionary objectForKey:dtconnection.identifier] retain];
	[connectionDictionary removeObjectForKey:dtconnection.identifier];
	
	if ([theDelegate respondsToSelector:@selector(connectionManager:connectionID:didFailWithError:)])
		[theDelegate connectionManager:self connectionID:dtconnection.identifier didFailWithError:error];
	
	[theDelegate release];
	[self connectionsCountChanged];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	DTURLConnection *dtconnection = (DTURLConnection *)connection;
	
	id theDelegate = [[connectionDictionary objectForKey:dtconnection.identifier] retain];
	[connectionDictionary removeObjectForKey:dtconnection.identifier];
	if ([theDelegate respondsToSelector:@selector(connectionManager:connectionID:didFinishLoadingData:)])
		[theDelegate connectionManager:self connectionID:dtconnection.identifier didFinishLoadingData:dtconnection.data];	
	
	[theDelegate release];
	[self connectionsCountChanged];
}


- (void)applicationDidReceiveMemoryWarning:(id)sender {
}

- (void)applicationWillTerminate:(id)sender {
	[self release];
}


@end
