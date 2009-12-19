//
//  DTConnectionController.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 05.10.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import "DTConnectionController.h"

NSString * const DTConnectionTypeStrings[] = {
	@"GET",
	@"POST",
	@"PUT",
	@"DELETE",
	@"OPTIONS",
	@"HEAD",
	@"TRACE",
	@"CONNECT"
};

NSString *const DTConnectionControllerCompletedNotification = @"DTConnectionControllerCompletedNotification";
NSString *const DTConnectionControllerFailedNotification = @"DTConnectionControllerFailedNotification";
NSString *const DTConnectionControllerResponseNotification = @"DTConnectionControllerResponseNotification";

NSString *const DTConnectionHeaderIfModifiedSince = @"If-Modified-Since";
NSString *const DTConnectionHeaderIfNoneMatch = @"If-None-Match";
NSString *const DTConnectionHeaderEtag = @"Etag";
NSString *const DTConnectionHeaderLastModified = @"Last-Modified";
NSString *const DTConnectionHeaderCacheControl = @"Cache-Control";

@interface DTConnectionController () <DTConnectionManagerDelegate>
@property (nonatomic, readwrite) DTConnectionStatus status;
@end


@implementation DTConnectionController

@synthesize delegate, type, returnedObject, returnedError, returnedResponse, status, enableCaching;

- (void)dealloc {
	[httpResponse release];
	[returnedResponse release];
	[returnedError release];
	[returnedObject release];
	[delegate release];
	[super dealloc];
}

- (void)start {
	NSURLRequest *request = [self newRequest];
	
	DTConnectionManager *connectionManager = [DTConnectionManager sharedConnectionManager];
	
	if (self.type == DTConnectionTypeGet) {
		NSData *data = [connectionManager cachedDataForURL:[request URL]];	
		if (data) [self didRecieveCachedData:data];
	}
	
	[connectionManager makeRequest:request delegate:self];
	[request release];
}

#pragma mark -
#pragma mark For subclasses to use

- (void)didReceiveConnectionError:(NSError *)error {
}

- (void)didReceiveConnectionResponse:(NSURLResponse *)response {
}

- (void)didReceiveConnectionData:(NSData *)data {
}

- (void)didRecieveCachedData:(NSData *)data {
}

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	
	if (enableCaching) {
		[request addValue:@"" forHTTPHeaderField:DTConnectionHeaderIfModifiedSince];
		[request addValue:@"etag" forHTTPHeaderField:DTConnectionHeaderIfNoneMatch];
	}
	
	[request setHTTPMethod:DTConnectionTypeStrings[type]];	
	return request;
}

- (void)notifyDelegateAndObserversOfReturnedObject:(NSObject *)object {
	
	self.status = DTConnectionStatusComplete;
	
	if (!object) return;
	
	[returnedObject release];
	returnedObject = [object retain];
	
	if ([self.delegate respondsToSelector:@selector(connectionController:didSucceedWithObject:)])
		[self.delegate connectionController:self didSucceedWithObject:returnedObject];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionControllerCompletedNotification object:self];
}

- (void)notifyDelegateAndObserversOfReturnedError:(NSError *)error {
	
	self.status = DTConnectionStatusFailed;
	
	if (!error) return;
	
	[returnedError release];
	returnedError = [error retain];

	if ([self.delegate respondsToSelector:@selector(connectionController:didFailWithError:)])
		[self.delegate connectionController:self didFailWithError:returnedError];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionControllerFailedNotification object:self];
}

- (void)notifyDelegateAndObserversOfResponse:(NSURLResponse *)response {
	
	self.status = DTConnectionStatusResponded;
	
	if (!response) return;
	
	[returnedResponse release];
	returnedResponse = [response retain];
	
	if ([self.delegate respondsToSelector:@selector(connectionController:didReceiveResponse:)])
		[self.delegate connectionController:self didReceiveResponse:returnedResponse];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionControllerResponseNotification object:self];
}

#pragma mark -
#pragma mark DTConnectionManagerDelegate methods

- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didFailWithError:(NSError *)error {
	[self didReceiveConnectionError:error];
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didReceiveResponse:(NSURLResponse *)response {
	[self didReceiveConnectionResponse:response];
	
	NSHTTPURLResponse *theResponse = (NSHTTPURLResponse *)response;
	
	if (enableCaching && [theResponse statusCode] == 304) {
		
		//[connectionManager cancelConnection:connection];
		NSData *data = [connectionManager cachedDataForURL:[connectionManager URLForConnectionID:connectionID]];
		[self didRecieveCachedData:data];
		
	} else if (self.type == DTConnectionTypeGet && enableCaching) {
		
		httpResponse = [theResponse retain];
		
	}
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didFinishLoadingData:(NSData *)data {
	[self didReceiveConnectionData:data];
	
	if (httpResponse) {
		
	}
}

- (void)connectionManager:(DTConnectionManager *)connectionManager didStartConnectionID:(NSString *)connectionID {
	self.status = DTConnectionStatusStarted;
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didQueueRequest:(NSURLRequest *)request {
	self.status = DTConnectionStatusQueued;
}

@end
