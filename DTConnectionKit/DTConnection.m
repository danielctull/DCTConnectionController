//
//  DTConnection.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 23.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnection.h"
#import "DTConnectionQueue.h"

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


NSString *const DTConnectionCompletedNotification = @"DTConnectionCompletedNotification";
NSString *const DTConnectionFailedNotification = @"DTConnectionFailedNotification";
NSString *const DTConnectionResponseNotification = @"DTConnectionResponseNotification";

@interface DTConnection ()
@property (nonatomic, retain, readwrite) NSString *identifier;
@property (nonatomic, readwrite) DTConnectionStatus status;
@property (nonatomic, retain, readwrite) NSObject *returnedObject;
@property (nonatomic, retain, readwrite) NSError *returnedError;
@property (nonatomic, retain, readwrite) NSURLResponse *returnedResponse;
@end

@implementation DTConnection

@synthesize identifier, status, delegate, type, returnedObject, returnedError, returnedResponse;

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	self.identifier = [[NSProcessInfo processInfo] globallyUniqueString];
	
	return self;
}


- (void)dealloc {
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
	
	NSData *data = [NSURLConnection sendSynchronousRequest:[self newRequest] returningResponse:&response error:&error];
	
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
	[request setHTTPMethod:DTConnectionTypeStrings[type]];	
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
