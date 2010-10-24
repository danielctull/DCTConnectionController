//
//  DCTConnectionController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"
#import "DCTConnectionQueue+Singleton.h"

NSString * const DCTConnectionControllerTypeString[] = {
	@"GET",
	@"POST",
	@"PUT",
	@"DELETE",
	@"OPTIONS",
	@"HEAD",
	@"TRACE",
	@"CONNECT"
};


NSString *const DCTConnectionControllerCompletedNotification = @"DCTConnectionControllerCompletedNotification";
NSString *const DCTConnectionControllerFailedNotification = @"DCTConnectionControllerFailedNotification";
NSString *const DCTConnectionControllerResponseNotification = @"DCTConnectionControllerResponseNotification";
NSString *const DCTConnectionControllerCancellationNotification = @"DCTConnectionControllerCancellationNotification";

@interface DCTConnectionController ()
@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, readwrite) DCTConnectionControllerStatus status;
@property (nonatomic, retain, readwrite) NSObject *returnedObject;
@property (nonatomic, retain, readwrite) NSError *returnedError;
@property (nonatomic, retain, readwrite) NSURLResponse *returnedResponse;

- (void)dctInternal_announceResponse;
- (void)dctInternal_finishWithFailure;
- (void)dctInternal_finishWithSuccess;
- (void)dctInternal_finishWithCancelation;

- (void)dctInternal_notifyDelegateOfObject:(NSObject *)object;
- (void)dctInternal_notifyObserversOfObject:(NSObject *)object;
- (void)dctInternal_notifyDelegateOfReturnedError:(NSError *)error;
- (void)dctInternal_notifyObserversOfReturnedError:(NSError *)error;
- (void)dctInternal_notifyDelegateOfCancellation;
- (void)dctInternal_notifyObserversOfCancellation;
- (void)dctInternal_notifyDelegateOfResponse:(NSURLResponse *)response;
- (void)dctInternal_notifyObserversOfResponse:(NSURLResponse *)response;

@end


@implementation DCTConnectionController

@synthesize delegate, status, type, priority, multitaskEnabled, URL, returnedObject, returnedError, returnedResponse;

+ (id)connectionController {
	return [[[self alloc] init] autorelease];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	dependencies = [[NSMutableArray alloc] init];
	priority = DCTConnectionControllerPriorityMedium;
	
	return self;
}

- (void)dealloc {
	[dependencies release];
	[super dealloc];
}

#pragma mark -
#pragma mark Managing the connection

- (void)connect {
	[[DCTConnectionQueue sharedConnectionQueue] addConnectionController:self];
}

- (void)requeue {
	[[DCTConnectionQueue sharedConnectionQueue] requeueConnectionController:self];
}

- (void)cancel {
	[urlConnection cancel];
	[self dctInternal_finishWithCancelation];
	[urlConnection release]; urlConnection = nil;
}

- (void)reset {
	[urlConnection cancel];
	[urlConnection release]; urlConnection = nil;
	self.returnedResponse = nil;
	self.returnedError = nil;
	self.returnedObject = nil;
	self.status = DCTConnectionControllerStatusNotStarted;
}

#pragma mark -
#pragma mark Dependency methods

- (NSArray *)dependencies {
	return [[dependencies copy] autorelease];
}

- (void)addDependency:(DCTConnectionController *)connectionController {
	
	if (!connectionController) return;
	
	[dependencies addObject:connectionController];
}

- (void)removeDependency:(DCTConnectionController *)connectionController {
	
	if (![dependencies containsObject:connectionController]) return;
	
	[dependencies removeObject:connectionController];
}

- (void)start {
	
	NSURLRequest *request = [self newRequest];
	
	if (!request) {
		[self dctInternal_finishWithFailure];
		return;
	}
	
	self.URL = [request URL];
	[urlConnection release];
	urlConnection = nil;
	urlConnection = [[DCTURLConnection alloc] initWithRequest:request delegate:self];
	[request release];
	
	self.status = DCTConnectionControllerStatusStarted;
	
	if (!urlConnection) [self dctInternal_finishWithFailure];
}

- (void)setQueued {
	self.status = DCTConnectionControllerStatusQueued;
}

#pragma mark -
#pragma mark Subclass methods

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:DCTConnectionControllerTypeString[type]];	
	return request;
}

- (void)receivedObject:(NSObject *)object {
	self.returnedObject = object;
	[self dctInternal_finishWithSuccess];
}

- (void)receivedResponse:(NSURLResponse *)response {
	self.returnedResponse = response;
	[self dctInternal_announceResponse];
}

- (void)receivedError:(NSError *)error {
	self.returnedError = error;
	[self dctInternal_finishWithFailure];
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self receivedResponse:response];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(DCTURLConnection *)connection appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSData *data = ((DCTURLConnection *)connection).data;
	
    [self receivedObject:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self receivedError:error];
}

#pragma mark -
#pragma mark Private methods

- (void)dctInternal_announceResponse {
	[self dctInternal_notifyDelegateOfResponse:self.returnedResponse];
	[self dctInternal_notifyObserversOfResponse:self.returnedResponse];
	self.status = DCTConnectionControllerStatusResponded;
}

- (void)dctInternal_finishWithSuccess {
	[self dctInternal_notifyDelegateOfObject:self.returnedObject];
	[self dctInternal_notifyObserversOfObject:self.returnedObject];
	self.status = DCTConnectionControllerStatusComplete;
	[delegate release]; delegate = nil;
}

- (void)dctInternal_finishWithFailure {
	[self dctInternal_notifyDelegateOfReturnedError:self.returnedError];
	[self dctInternal_notifyObserversOfReturnedError:self.returnedError];
	self.status = DCTConnectionControllerStatusFailed;
	[delegate release]; delegate = nil;
}

- (void)dctInternal_finishWithCancelation {
	[self dctInternal_notifyDelegateOfCancellation];
	[self dctInternal_notifyObserversOfCancellation];
	self.status = DCTConnectionControllerStatusCancelled;
	[delegate release]; delegate = nil;
}

#pragma mark -
#pragma mark Private notification methods

- (void)dctInternal_notifyDelegateOfObject:(NSObject *)object {	
	if ([self.delegate respondsToSelector:@selector(connectionController:didSucceedWithObject:)])
		[self.delegate connectionController:self didSucceedWithObject:object];
}

- (void)dctInternal_notifyObserversOfObject:(NSObject *)object {
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerCompletedNotification object:self];
}

- (void)dctInternal_notifyDelegateOfReturnedError:(NSError *)error {
	if ([self.delegate respondsToSelector:@selector(connectionController:didFailWithError:)])
		[self.delegate connectionController:self didFailWithError:error];
}

- (void)dctInternal_notifyObserversOfReturnedError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerFailedNotification object:self];
}

- (void)dctInternal_notifyDelegateOfCancellation {
	if ([self.delegate respondsToSelector:@selector(connectionControllerWasCancelled:)])
		[self.delegate connectionControllerWasCancelled:self];
}

- (void)dctInternal_notifyObserversOfCancellation {
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerCancellationNotification object:self];
}

- (void)dctInternal_notifyDelegateOfResponse:(NSURLResponse *)response {
	if ([self.delegate respondsToSelector:@selector(connectionController:didReceiveResponse:)])
		[self.delegate connectionController:self didReceiveResponse:response];
}

- (void)dctInternal_notifyObserversOfResponse:(NSURLResponse *)response {
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerResponseNotification object:self];
}

@end
