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
	@"DELETE"
};

NSString *const DTConnectionControllerCompletedNotification = @"DTConnectionControllerCompletedNotification";
NSString *const DTConnectionControllerFailedNotification = @"DTConnectionControllerFailedNotification";
NSString *const DTConnectionControllerResponseNotification = @"DTConnectionControllerResponseNotification";

@implementation DTConnectionController

@synthesize delegate, type, returnedObject, returnedError, returnedResponse, isComplete;

- (id)init {
	return [self initWithType:DTConnectionTypeGet];
}

- (id)initWithType:(DTConnectionType)aType {
	return [self initWithDelegate:nil type:aType];	
}


- (id)initWithDelegate:(NSObject<DTConnectionControllerDelegate> *)aDelegate type:(DTConnectionType)aType {
	
	if (!(self = [super init])) return nil;
	
	type = aType;
	delegate = [aDelegate retain];
	
	return self;	
}

- (void)dealloc {
	[returnedResponse release];
	[returnedError release];
	[returnedObject release];
	[delegate release];
	[super dealloc];
}

- (void)start {
	NSURLRequest *request = [self newRequest];
	[DTConnectionManager makeRequest:request delegate:self];
	[request release];
	status = DTConnectionStatusStarted;
}

#pragma mark -
#pragma mark For subclasses to use

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:DTConnectionTypeStrings[type]];
	return request;
}

- (void)notifyDelegateAndObserversOfReturnedObject:(NSObject *)object {
	
	status = DTConnectionStatusComplete;
	
	if (!object) return;
	
	[returnedObject release];
	returnedObject = [object retain];
	
	if ([self.delegate respondsToSelector:@selector(connectionController:didSucceedWithObject:)])
		[self.delegate connectionController:self didSucceedWithObject:returnedObject];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionControllerCompletedNotification object:self];
}

- (void)notifyDelegateAndObserversOfReturnedError:(NSError *)error {
	
	status = DTConnectionStatusFailed;
	
	if (!error) return;
	
	[returnedError release];
	returnedError = [error retain];

	if ([self.delegate respondsToSelector:@selector(connectionController:didFailWithError:)])
		[self.delegate connectionController:self didFailWithError:returnedError];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionControllerFailedNotification object:self];
}

- (void)notifyDelegateAndObserversOfResponse:(NSURLResponse *)response {
	
	status = DTConnectionStatusResponded;
	
	if (!response) return;
	
	[returnedResponse release];
	returnedResponse = [response retain];
	
	if ([self.delegate respondsToSelector:@selector(connectionController:didReceiveResponse:)])
		[self.delegate connectionController:self didReceiveResponse:returnedResponse];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionControllerResponseNotification object:self];
}

#pragma mark -
#pragma mark DTConnectionManagerDelegate methods

- (void)connectionManager:(DTConnectionManager *)connectionManager connection:(DTURLConnection *)connection didFailWithError:(NSError *)anError {
	[self notifyDelegateAndObserversOfReturnedError:anError];
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connection:(DTURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[self notifyDelegateAndObserversOfResponse:response];
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connectionDidFinishLoading:(DTURLConnection *)connection {
	[self notifyDelegateAndObserversOfReturnedObject:connection.data];
}

@end
