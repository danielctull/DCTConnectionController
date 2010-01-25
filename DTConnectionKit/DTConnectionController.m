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

@interface DTConnectionController () <DTConnectionManagerDelegate>
@property (nonatomic, readwrite) DTConnectionStatus status;

/* @brief Sends the delegate a message that the conenction has returned this object and sends out a notification.￼
 
 Subclasses should handle the incoming data, creating a wrapper or data object for it for the delegate and observers to use and then call this method with that created object.
 
 @param object The object to be sent to the delegate and stored in returnedObject.
 
 */
- (void)notifyDelegateAndObserversOfReturnedObject:(NSObject *)object;

/* @brief Sends the delegate a message that the conenction has failed, with the given error.
 
 By default this is called when an error returns from DTConnectionManager. Subclasses could utilise this
 by interpretating the error from the connection and packaging an error more meaningful to the delegate and observers.
 
 @param error The error to be sent to the delegate and stored in returnedError.
 */
- (void)notifyDelegateAndObserversOfReturnedError:(NSError *)error;

/* @brief Sends the delegate a message that the conenction has received a response, with the given URL response.
 
 This is called when a response returns from DTConnectionManager. Subclasses should override this method to handle errors,
 calling the superclass implementation
 
 @param response The URL response to be sent to the delegate and stored in returnedResponse.
 
 */
- (void)notifyDelegateAndObserversOfResponse:(NSURLResponse *)response;
@end
#pragma mark -
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

#pragma mark -
#pragma mark For external classes to use

- (void)start {
	NSURLRequest *request = [self newRequest];
	
	DTConnectionManager *connectionManager = [DTConnectionManager sharedConnectionManager];
	/*
	if (self.type == DTConnectionTypeGet) {
		NSData *data = [connectionManager cachedDataForURL:[request URL]];	
		if (data) [self didRecieveCachedData:data];
	}*/	
	[connectionManager makeRequest:request delegate:self];
	[request release];
}

#pragma mark -
#pragma mark For subclasses to override

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	/*
	if (enableCaching) {
		[request addValue:@"" forHTTPHeaderField:DTConnectionHeaderIfModifiedSince];
		[request addValue:@"etag" forHTTPHeaderField:DTConnectionHeaderIfNoneMatch];
	}
	*/
	[request setHTTPMethod:DTConnectionTypeStrings[type]];	
	return request;
}

- (void)receivedObject:(NSObject *)object {
	[self notifyDelegateAndObserversOfReturnedObject:object];
}

- (void)receivedResponse:(NSURLResponse *)response {
	[self notifyDelegateAndObserversOfResponse:response];
}

- (void)receivedError:(NSError *)error {
	[self notifyDelegateAndObserversOfReturnedError:error];
}

#pragma mark -
#pragma mark Internal methods

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
	[self receivedError:error];
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didReceiveResponse:(NSURLResponse *)response {
	[self receivedResponse:response];
	/*
	NSHTTPURLResponse *theResponse = (NSHTTPURLResponse *)response;
	
	if (enableCaching && [theResponse statusCode] == 304) {
		
		//[connectionManager cancelConnection:connection];
		NSData *data = [connectionManager cachedDataForURL:[connectionManager URLForConnectionID:connectionID]];
		[self didRecieveCachedData:data];
		
	} else if (self.type == DTConnectionTypeGet && enableCaching) {
		
		httpResponse = [theResponse retain];
		
	}*/
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didFinishLoadingData:(NSData *)data {
	[self receivedObject:data];
	/*
	if (httpResponse) {
		
	}*/
}

- (void)connectionManager:(DTConnectionManager *)connectionManager didStartConnectionID:(NSString *)connectionID {
	self.status = DTConnectionStatusStarted;
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connectionID:(NSString *)connectionID didQueueRequest:(NSURLRequest *)request {
	self.status = DTConnectionStatusQueued;
}

@end
