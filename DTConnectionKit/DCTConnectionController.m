//
//  DTConnectionController.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"
#import "DTConnectionQueue+DTSingleton.h"

NSString * const DTConnectionControllerTypeString[] = {
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
NSString *const DTConnectionControllerCancellationNotification = @"DTConnectionControllerCancellationNotification";

@interface DCTConnectionController ()
@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, readwrite) DTConnectionControllerStatus status;
@property (nonatomic, retain, readwrite) NSObject *returnedObject;
@property (nonatomic, retain, readwrite) NSError *returnedError;
@property (nonatomic, retain, readwrite) NSURLResponse *returnedResponse;

- (void)dt_announceResponse;
- (void)dt_finishWithFailure;
- (void)dt_finishWithSuccess;
- (void)dt_finishWithCancelation;

- (void)dt_notifyDelegateOfObject:(NSObject *)object;
- (void)dt_notifyObserversOfObject:(NSObject *)object;
- (void)dt_notifyDelegateOfReturnedError:(NSError *)error;
- (void)dt_notifyObserversOfReturnedError:(NSError *)error;
- (void)dt_notifyDelegateOfCancellation;
- (void)dt_notifyObserversOfCancellation;
- (void)dt_notifyDelegateOfResponse:(NSURLResponse *)response;
- (void)dt_notifyObserversOfResponse:(NSURLResponse *)response;

@end


@implementation DCTConnectionController

@synthesize delegate, status, type, priority, multitaskEnabled, URL, returnedObject, returnedError, returnedResponse;

+ (id)connectionController {
	return [[[self alloc] init] autorelease];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	dependencies = [[NSMutableArray alloc] init];
	priority = DTConnectionControllerPriorityMedium;
	
	return self;
}

- (void)dealloc {
	[dependencies release];
	[super dealloc];
}

#pragma mark -
#pragma mark Managing the connection

- (void)connect {
	[[DTConnectionQueue sharedConnectionQueue] addConnectionController:self];
}

- (void)requeue {
	[[DTConnectionQueue sharedConnectionQueue] requeueConnectionController:self];
}

- (void)cancel {
	[urlConnection cancel];
	[self dt_finishWithCancelation];
	[urlConnection release]; urlConnection = nil;
}

- (void)reset {
	[urlConnection cancel];
	[urlConnection release]; urlConnection = nil;
	self.returnedResponse = nil;
	self.returnedError = nil;
	self.returnedObject = nil;
	self.status = DTConnectionControllerStatusNotStarted;
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
		[self dt_finishWithFailure];
		return;
	}
	
	self.URL = [request URL];
	[urlConnection release];
	urlConnection = nil;
	urlConnection = [[DTURLConnection alloc] initWithRequest:request delegate:self];
	[request release];
	
	self.status = DTConnectionControllerStatusStarted;
	
	if (!urlConnection) [self dt_finishWithFailure];
}

- (void)setQueued {
	self.status = DTConnectionControllerStatusQueued;
}

#pragma mark -
#pragma mark Subclass methods

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:DTConnectionControllerTypeString[type]];	
	return request;
}

- (void)receivedObject:(NSObject *)object {
	self.returnedObject = object;
}

- (void)receivedResponse:(NSURLResponse *)response {
	self.returnedResponse = response;
}

- (void)receivedError:(NSError *)error {
	self.returnedError = error;
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self receivedResponse:response];
	if (!self.returnedResponse) self.returnedResponse = response;
	[self dt_announceResponse];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(DTURLConnection *)connection appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSData *data = ((DTURLConnection *)connection).data;
	
    [self receivedObject:data];
	if (!self.returnedObject) self.returnedObject = data;
	[self dt_finishWithSuccess];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self receivedError:error];
	if (!self.returnedError) self.returnedError = error;
	[self dt_finishWithFailure];
}

#pragma mark -
#pragma mark Private methods

- (void)dt_announceResponse {
	[self dt_notifyDelegateOfResponse:self.returnedResponse];
	[self dt_notifyObserversOfResponse:self.returnedResponse];
	self.status = DTConnectionControllerStatusResponded;
}

- (void)dt_finishWithSuccess {
	[self dt_notifyDelegateOfObject:self.returnedObject];
	[self dt_notifyObserversOfObject:self.returnedObject];
	self.status = DTConnectionControllerStatusComplete;
	[delegate release]; delegate = nil;
}

- (void)dt_finishWithFailure {
	[self dt_notifyDelegateOfReturnedError:self.returnedError];
	[self dt_notifyObserversOfReturnedError:self.returnedError];
	self.status = DTConnectionControllerStatusFailed;
	[delegate release]; delegate = nil;
}

- (void)dt_finishWithCancelation {
	[self dt_notifyDelegateOfCancellation];
	[self dt_notifyObserversOfCancellation];
	self.status = DTConnectionControllerStatusCancelled;
	[delegate release]; delegate = nil;
}

#pragma mark -
#pragma mark Private notification methods

- (void)dt_notifyDelegateOfObject:(NSObject *)object {	
	if ([self.delegate respondsToSelector:@selector(connectionController:didSucceedWithObject:)])
		[self.delegate connectionController:self didSucceedWithObject:object];
}

- (void)dt_notifyObserversOfObject:(NSObject *)object {
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionControllerCompletedNotification object:self];
}

- (void)dt_notifyDelegateOfReturnedError:(NSError *)error {
	if ([self.delegate respondsToSelector:@selector(connectionController:didFailWithError:)])
		[self.delegate connectionController:self didFailWithError:error];
}

- (void)dt_notifyObserversOfReturnedError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionControllerFailedNotification object:self];
}

- (void)dt_notifyDelegateOfCancellation {
	if ([self.delegate respondsToSelector:@selector(connectionControllerWasCancelled:)])
		[self.delegate connectionControllerWasCancelled:self];
}

- (void)dt_notifyObserversOfCancellation {
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionControllerCancellationNotification object:self];
}

- (void)dt_notifyDelegateOfResponse:(NSURLResponse *)response {
	if ([self.delegate respondsToSelector:@selector(connectionController:didReceiveResponse:)])
		[self.delegate connectionController:self didReceiveResponse:response];
}

- (void)dt_notifyObserversOfResponse:(NSURLResponse *)response {
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionControllerResponseNotification object:self];
}

@end
