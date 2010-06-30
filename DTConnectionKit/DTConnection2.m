//
//  DTURLConnectionJob.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnection2.h"
#import "DTConnectionQueue2.h"

@interface DTConnection2 ()
@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, readwrite) DTConnectionStatus status;
@property (nonatomic, retain, readwrite) NSObject *returnedObject;
@property (nonatomic, retain, readwrite) NSError *returnedError;
@property (nonatomic, retain, readwrite) NSURLResponse *returnedResponse;
- (void)dt_finish;

- (void)dt_notifyDelegateOfObject:(NSObject *)object;
- (void)dt_notifyObserversOfObject:(NSObject *)object;
- (void)dt_notifyDelegateOfReturnedError:(NSError *)error;
- (void)dt_notifyObserversOfReturnedError:(NSError *)error;
- (void)dt_notifyDelegateOfResponse:(NSURLResponse *)response;
- (void)dt_notifyObserversOfResponse:(NSURLResponse *)response;

@end


@implementation DTConnection2

@synthesize delegate, status, type, priority, URL, returnedObject, returnedError, returnedResponse;

+ (DTConnection2 *)connection {
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
	[[DTConnectionQueue2 sharedConnectionQueue] addConnection:self];
}

#pragma mark -
#pragma mark Dependency methods

- (NSArray *)dependencies {
	return [[dependencies copy] autorelease];
}

- (void)addDependency:(DTConnection2 *)connection {
	
	if (!connection) return;
	
	[dependencies addObject:connection];
}

- (void)removeDependency:(DTConnection2 *)connection {
	
	if (![dependencies containsObject:connection]) return;
	
	[dependencies removeObject:connection];
}

- (void)start {
	
	NSURLRequest *request = [self newRequest];
	
	if (!request) {
		[self dt_finish];
		return;
	}
	
	self.URL = [request URL];
	urlConnection = [[DTURLConnection alloc] initWithRequest:request delegate:self];
	[request release];
	
	self.status = DTConnectionStatusStarted;
	
	if (!urlConnection) [self dt_finish];
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
	[self dt_notifyDelegateOfObject:object];
	[self dt_notifyObserversOfObject:object];
}

- (void)receivedResponse:(NSURLResponse *)response {
	self.returnedResponse = response;
	self.status = DTConnectionStatusResponded;
	[self dt_notifyDelegateOfResponse:response];
	[self dt_notifyObserversOfResponse:response];
}

- (void)receivedError:(NSError *)error {
	self.returnedError = error;
	self.status = DTConnectionStatusFailed;
	[self dt_notifyDelegateOfReturnedError:error];
	[self dt_notifyObserversOfReturnedError:error];
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
	[self dt_finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self receivedError:error];
	[self dt_finish];
}

#pragma mark -
#pragma mark Private methods

- (void)dt_finish {
	self.status = DTConnectionStatusComplete;
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
