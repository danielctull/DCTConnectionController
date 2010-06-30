//
//  DTURLConnectionJob.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
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

NSString *const DTConnectionIsExecutingKey = @"isExecuting";
NSString *const DTConnectionIsFinishedKey = @"isFinished";

@interface DTConnection ()
@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, readwrite) DTConnectionStatus status;
@property (nonatomic, retain, readwrite) NSObject *returnedObject;
@property (nonatomic, retain, readwrite) NSError *returnedError;
@property (nonatomic, retain, readwrite) NSURLResponse *returnedResponse;
- (void)dt_finishWithFailure;
- (void)dt_finishWithSuccess;

- (void)dt_notifyDelegateOfObject:(NSObject *)object;
- (void)dt_notifyObserversOfObject:(NSObject *)object;
- (void)dt_notifyDelegateOfReturnedError:(NSError *)error;
- (void)dt_notifyObserversOfReturnedError:(NSError *)error;
- (void)dt_notifyDelegateOfResponse:(NSURLResponse *)response;
- (void)dt_notifyObserversOfResponse:(NSURLResponse *)response;

@end


@implementation DTConnection

@synthesize delegate, status, type, priority, URL, returnedObject, returnedError, returnedResponse;

+ (DTConnection *)connection {
	return [[[self alloc] init] autorelease];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	dependencies = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)dealloc {
	[dependencies release];
	[super dealloc];
}

#pragma mark -
#pragma mark Starting the connection

- (void)connect {
	[[DTConnectionQueue sharedConnectionQueue] addConnection:self];
}

#pragma mark -
#pragma mark Dependency methods

- (NSArray *)dependencies {
	return [[dependencies copy] autorelease];
}

- (void)addDependency:(DTConnection *)connection {
	
	if (!connection) return;
	
	[dependencies addObject:connection];
}

- (void)removeDependency:(DTConnection *)connection {
	
	if (![dependencies containsObject:connection]) return;
	
	[dependencies removeObject:connection];
}

- (void)start {
	
	NSURLRequest *request = [self newRequest];
	
	if (!request) {
		[self dt_finishWithFailure];
		return;
	}
	
	self.URL = [request URL];
	urlConnection = [[DTURLConnection alloc] initWithRequest:request delegate:self];
	[request release];
	
	self.status = DTConnectionStatusStarted;
	
	if (!urlConnection) [self dt_finishWithFailure];
}

- (void)setQueued {
	self.status = DTConnectionStatusQueued;
}

#pragma mark -
#pragma mark Subclass methods

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:DTConnectionTypeString[type]];	
	return request;
}

- (void)receivedObject:(NSObject *)object {
	self.returnedObject = object;
	[self dt_notifyDelegateOfObject:object];
	[self dt_notifyObserversOfObject:object];
	self.status = DTConnectionStatusComplete;
}

- (void)receivedResponse:(NSURLResponse *)response {
	self.returnedResponse = response;
	[self dt_notifyDelegateOfResponse:response];
	[self dt_notifyObserversOfResponse:response];
	self.status = DTConnectionStatusResponded;
}

- (void)receivedError:(NSError *)error {
	self.returnedError = error;
	[self dt_notifyDelegateOfReturnedError:error];
	[self dt_notifyObserversOfReturnedError:error];
	self.status = DTConnectionStatusFailed;
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self receivedResponse:response];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(DTURLConnection *)connection appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self receivedObject:((DTURLConnection *)connection).data];
	[self dt_finishWithSuccess];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self receivedError:error];
	[self dt_finishWithFailure];
}

#pragma mark -
#pragma mark Private methods

- (void)dt_finishWithSuccess {
	self.status = DTConnectionStatusComplete;
}

- (void)dt_finishWithFailure {
	self.status = DTConnectionStatusFailed;
}

#pragma mark -
#pragma mark Private notification methods

- (void)dt_notifyDelegateOfObject:(NSObject *)object {	
	if ([(NSObject *)self.delegate respondsToSelector:@selector(dtconnection:didSucceedWithObject:)])
		[self.delegate dtconnection:self didSucceedWithObject:object];
}

- (void)dt_notifyObserversOfObject:(NSObject *)object {
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionCompletedNotification object:self];
}



- (void)dt_notifyDelegateOfReturnedError:(NSError *)error {
	if ([(NSObject *)self.delegate respondsToSelector:@selector(dtconnection:didFailWithError:)])
		[self.delegate dtconnection:self didFailWithError:error];
}

- (void)dt_notifyObserversOfReturnedError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionFailedNotification object:self];
}



- (void)dt_notifyDelegateOfResponse:(NSURLResponse *)response {
	if ([(NSObject *)self.delegate respondsToSelector:@selector(dtconnection:didReceiveResponse:)])
		[self.delegate dtconnection:self didReceiveResponse:response];
}

- (void)dt_notifyObserversOfResponse:(NSURLResponse *)response {
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionResponseNotification object:self];
}

@end
