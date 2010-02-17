//
//  DTConnection.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 23.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnection.h"
#import "DTConnectionQueue.h"

NSString * const DTConnectionTypeString[] = {
	@"GET",
	@"POST",
	@"PUT",
	@"DELETE",
	@"OPTIONS",
	@"HEAD",
	@"TRACE",
	@"CONNECT"
};


NSString *const DTConnectionCompletedNotification = @"DTConnectionCompletedNotification";
NSString *const DTConnectionFailedNotification = @"DTConnectionFailedNotification";
NSString *const DTConnectionResponseNotification = @"DTConnectionResponseNotification";

@interface DTConnection ()
@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, retain, readwrite) NSString *identifier;
@property (nonatomic, readwrite) DTConnectionStatus status;
@property (nonatomic, retain, readwrite) NSObject *returnedObject;
@property (nonatomic, retain, readwrite) NSError *returnedError;
@property (nonatomic, retain, readwrite) NSURLResponse *returnedResponse;

- (void)notifyDelegateAndObserversOfReturnedObject:(NSObject *)object;
- (void)notifyDelegateAndObserversOfReturnedError:(NSError *)error;
- (void)notifyDelegateAndObserversOfResponse:(NSURLResponse *)response;
@end

@implementation DTConnection

@synthesize identifier, status, delegate, type, returnedObject, returnedError, returnedResponse, URL;

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	self.identifier = [[NSProcessInfo processInfo] globallyUniqueString];
	
	return self;
}


- (void)dealloc {
	[URL release];
	[identifier release];
	[returnedResponse release];
	[returnedError release];
	[returnedObject release];
	[super dealloc];
}

- (void)main {
	
	self.status = DTConnectionStatusStarted;
	
	NSURLResponse *response = nil;
	NSError *error = nil;
	
	NSURLRequest *request = [self newRequest];
	
	self.URL = [request URL];
	
	if (!request) return;
	
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	[request release];
	
	[self receivedResponse:response];
	
	if (error)
		[self receivedError:error];
	else
		[self receivedObject:data];
}

- (void)connect {
	[[DTConnectionQueue sharedConnectionQueue] addConnection:self];
}

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:DTConnectionTypeString[type]];	
	return request;
}

- (void)receivedObject:(NSObject *)object {
	[self performSelectorOnMainThread:@selector(notifyDelegateAndObserversOfReturnedObject:) withObject:object waitUntilDone:YES];
}

- (void)receivedResponse:(NSURLResponse *)response {
	[self performSelectorOnMainThread:@selector(notifyDelegateAndObserversOfResponse:) withObject:response waitUntilDone:YES];
}

- (void)receivedError:(NSError *)error {
	[self performSelectorOnMainThread:@selector(notifyDelegateAndObserversOfReturnedError:) withObject:error waitUntilDone:YES];
}	 
		 
#pragma mark -
#pragma mark Internal methods

- (void)notifyDelegateAndObserversOfReturnedObject:(NSObject *)object {
	
	self.returnedObject = object;
	
	self.status = DTConnectionStatusComplete;
	
	if ([self.delegate respondsToSelector:@selector(dtconnection:didSucceedWithObject:)])
		[self.delegate dtconnection:self didSucceedWithObject:object];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionCompletedNotification object:self];
}

- (void)notifyDelegateAndObserversOfReturnedError:(NSError *)error {
	
	self.returnedError = error;
	
	self.status = DTConnectionStatusFailed;
		
	if ([self.delegate respondsToSelector:@selector(dtconnection:didFailWithError:)])
		[self.delegate dtconnection:self didFailWithError:error];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionFailedNotification object:self];
}

- (void)notifyDelegateAndObserversOfResponse:(NSURLResponse *)response {
	
	self.returnedResponse = response;
	
	self.status = DTConnectionStatusResponded;
	
	if ([self.delegate respondsToSelector:@selector(dtconnection:didReceiveResponse:)])
		[self.delegate dtconnection:self didReceiveResponse:response];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionResponseNotification object:self];
}

@end
