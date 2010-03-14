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

NSString *const DTConnectionIsExecutingKey = @"isExecuting";
NSString *const DTConnectionIsFinishedKey = @"isFinished";

@interface DTConnection ()
@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, retain, readwrite) NSString *identifier;
@property (nonatomic, readwrite) DTConnectionStatus status;
@property (nonatomic, retain, readwrite) NSObject *returnedObject;
@property (nonatomic, retain, readwrite) NSError *returnedError;
@property (nonatomic, retain, readwrite) NSURLResponse *returnedResponse;

- (void)notifyDelegateOfObject:(NSObject *)object;
- (void)notifyObserversOfObject:(NSObject *)object;

- (void)notifyDelegateOfReturnedError:(NSError *)error;
- (void)notifyObserversOfReturnedError:(NSError *)error;

- (void)notifyDelegateOfResponse:(NSURLResponse *)response;
- (void)notifyObserversOfResponse:(NSURLResponse *)response;

- (void)finish;
- (void)inQueueCheck;
@end

@implementation DTConnection

@synthesize identifier, status, delegate, type, returnedObject, returnedError, returnedResponse, URL, originatingThread;

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	self.identifier = [[NSProcessInfo processInfo] globallyUniqueString];
	
	originatingThread = [[NSThread currentThread] retain];
	
	return self;
}


- (void)dealloc {
	[originatingThread release]; originatingThread = nil;
	[URL release]; URL = nil;
	[identifier release]; identifier = nil;
	[returnedResponse release]; returnedResponse = nil;
	[returnedError release]; returnedError = nil;
	[returnedObject release]; returnedObject = nil;
	[urlConnection release]; urlConnection = nil;
	[super dealloc];
}

- (BOOL)isExecuting {
	return isExecuting;
}
- (BOOL)isFinished {
	if (self.status == DTConnectionStatusNotStarted)
		[self performSelector:@selector(inQueueCheck) withObject:nil afterDelay:0.0];
	
	return isFinished;
}

- (void)start {
	pool = [[NSAutoreleasePool alloc] init];
	[self willChangeValueForKey:DTConnectionIsExecutingKey];
    isExecuting = YES;
    [self didChangeValueForKey:DTConnectionIsExecutingKey];
	
	NSURLRequest *request = [self newRequest];
	
	if (!request) [self finish];
	
	self.URL = [request URL];
	urlConnection = [[DTURLConnection alloc] initWithRequest:request delegate:self];
	[request release];
	
	self.status = DTConnectionStatusStarted;
	
	if (!urlConnection) [self finish];
	
	CFRunLoopRun();
}

- (void)cancel {
	[super cancel];
	[urlConnection cancel];
	[self finish];
}

- (void)connect {
	[[DTConnectionQueue sharedConnectionQueue] addConnection:self];
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
	self.status = DTConnectionStatusComplete;
	[self performSelector:@selector(notifyDelegateOfObject:) onThread:originatingThread withObject:object waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(notifyObserversOfObject:) withObject:object waitUntilDone:YES];
}

- (void)receivedResponse:(NSURLResponse *)response {
	self.returnedResponse = response;
	self.status = DTConnectionStatusResponded;
	[self performSelector:@selector(notifyDelegateOfResponse:) onThread:originatingThread withObject:response waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(notifyObserversOfResponse:) withObject:response waitUntilDone:YES];
}

- (void)receivedError:(NSError *)error {
	self.returnedError = error;
	self.status = DTConnectionStatusFailed;
	[self performSelector:@selector(notifyDelegateOfReturnedError:) onThread:originatingThread withObject:error waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(notifyObserversOfReturnedError:) withObject:error waitUntilDone:YES];
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
	[self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self receivedError:error];
	[self finish];
}
		 
#pragma mark -
#pragma mark Internal methods

- (void)notifyDelegateOfObject:(NSObject *)object {	
	if ([(NSObject *)self.delegate respondsToSelector:@selector(dtconnection:didSucceedWithObject:)])
		[self.delegate dtconnection:self didSucceedWithObject:object];
}

- (void)notifyObserversOfObject:(NSObject *)object {
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionCompletedNotification object:self];
}



- (void)notifyDelegateOfReturnedError:(NSError *)error {
	if ([(NSObject *)self.delegate respondsToSelector:@selector(dtconnection:didFailWithError:)])
		[self.delegate dtconnection:self didFailWithError:error];
}

- (void)notifyObserversOfReturnedError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionFailedNotification object:self];
}



- (void)notifyDelegateOfResponse:(NSURLResponse *)response {
	if ([(NSObject *)self.delegate respondsToSelector:@selector(dtconnection:didReceiveResponse:)])
		[self.delegate dtconnection:self didReceiveResponse:response];
}

- (void)notifyObserversOfResponse:(NSURLResponse *)response {
	[[NSNotificationCenter defaultCenter] postNotificationName:DTConnectionResponseNotification object:self];
}

- (void)finish {
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
	[self willChangeValueForKey:DTConnectionIsExecutingKey];
    [self willChangeValueForKey:DTConnectionIsFinishedKey];
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:DTConnectionIsExecutingKey];
    [self didChangeValueForKey:DTConnectionIsFinishedKey];
	[pool drain];
}

- (void)inQueueCheck {
	if (![self isExecuting])
		self.status = DTConnectionStatusQueued;
}

@end
