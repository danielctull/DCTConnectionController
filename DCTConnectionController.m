//
//  DCTConnectionController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"
#import "DCTConnectionQueue+Singleton.h"
#import "DCTConnectionController+Equality.h"
#import "DCTObservationInfo.h"
#import "NSMutableSet+DCTExtras.h"

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

- (void)dctInternal_reset;
- (void)dctInternal_start;
- (void)dctInternal_setQueued;

@property (nonatomic, readonly) NSSet *dctInternal_responseBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_completionBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_failureBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_cancelationBlocks;

@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, readwrite) DCTConnectionControllerStatus status;
@property (nonatomic, retain, readwrite) NSObject *returnedObject;
@property (nonatomic, retain, readwrite) NSError *returnedError;
@property (nonatomic, retain, readwrite) NSURLResponse *returnedResponse;

- (void)dctInternal_announceResponse;
- (void)dctInternal_finishWithFailure;
- (void)dctInternal_finishWithSuccess;
- (void)dctInternal_finishWithCancelation;
- (void)dctInternal_finish;


- (void)dctInternal_sendResponseToDelegate:(NSURLResponse *)response;
- (void)dctInternal_sendCancelationToDelegate:(id<DCTConnectionControllerDelegate>)delegate;
- (void)dctInternal_sendObjectToDelegate:(id)object;
- (void)dctInternal_sendErrorToDelegate:(NSError *)error;

- (BOOL)dctInternal_hasResponded;
- (BOOL)dctInternal_hasFinished;
- (BOOL)dctInternal_hasFailed;
- (BOOL)dctInternal_hasCompleted;
- (BOOL)dctInternal_hasCancelled;

@property (nonatomic, readonly) NSSet *dctInternal_dependents;
- (void)dctInternal_addDependent:(DCTConnectionController *)connectionController;
- (void)dctInternal_removeDependent:(DCTConnectionController *)connectionController;

@end


@implementation DCTConnectionController

@synthesize status, type, priority, multitaskEnabled, URL, returnedObject, returnedError, returnedResponse, delegate;

+ (id)connectionController {
	return [[[self alloc] init] autorelease];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	priority = DCTConnectionControllerPriorityMedium;
	
	return self;
}

- (void)dealloc {	
	[responseBlocks release], responseBlocks = nil;
	[completionBlocks release], completionBlocks = nil;
	[failureBlocks release], failureBlocks = nil;
	[cancelationBlocks release], cancelationBlocks = nil;
	[dependencies release], dependencies = nil;
	[dependents release], dependents = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Block methods

- (void)addResponseBlock:(DCTConnectionControllerResponseBlock)block {
	
	if (!responseBlocks) responseBlocks = [[NSMutableSet alloc] initWithCapacity:1];
	
	if ([self dctInternal_hasResponded]) block(self.returnedResponse);
	
	[responseBlocks dct_addBlock:block];
}

- (void)addCompletionBlock:(DCTConnectionControllerCompletionBlock)block {
	
	if (!completionBlocks) completionBlocks = [[NSMutableSet alloc] initWithCapacity:1];
	
	if ([self dctInternal_hasCompleted]) block(self.returnedObject);
	
	[completionBlocks dct_addBlock:block];
}

- (void)addFailureBlock:(DCTConnectionControllerFailureBlock)block {
	
	if (!failureBlocks) failureBlocks = [[NSMutableSet alloc] initWithCapacity:1];
	
	if ([self dctInternal_hasFailed]) block(self.returnedError);
	
	[failureBlocks dct_addBlock:block];
}

- (void)addCancelationBlock:(DCTConnectionControllerCancelationBlock)block {
	
	if (!cancelationBlocks) cancelationBlocks = [[NSMutableSet alloc] initWithCapacity:1];
	
	if ([self dctInternal_hasCancelled]) block();
		
	[cancelationBlocks dct_addBlock:block];
}


#pragma mark -
#pragma mark Managing the connection

- (void)connect {
		
	DCTConnectionQueue *queue = [DCTConnectionQueue sharedConnectionQueue];
	
	NSUInteger existingConnectionControllerIndex = [queue.connectionControllers indexOfObject:self];
	
	if (existingConnectionControllerIndex != NSNotFound) {
		
		DCTConnectionController *existingConnectionController = [queue.connectionControllers objectAtIndex:existingConnectionControllerIndex];
		
		if (existingConnectionController.priority > self.priority)
			existingConnectionController.priority = self.priority;
		
		self.status = existingConnectionController.status;
		
		[existingConnectionController addResponseBlock:^(NSURLResponse *response) {
			self.returnedResponse = response;
			[self dctInternal_announceResponse];
		}];
		
		[existingConnectionController addCompletionBlock:^(NSObject *object) {
			self.returnedObject = object;
			[self dctInternal_finishWithSuccess];
		}];
		
		[existingConnectionController addFailureBlock:^(NSError *error) {
			self.returnedError = error;
			[self dctInternal_finishWithFailure];
		}];
		
		return;
	}
		
	[queue addConnectionController:self];
}

- (void)requeue {
	[[DCTConnectionQueue sharedConnectionQueue] requeueConnectionController:self];
}

- (void)cancel {
	[urlConnection cancel];
	[self dctInternal_finishWithCancelation];
	[urlConnection release]; urlConnection = nil;
}

- (void)dctInternal_reset {
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
	return [dependencies allObjects];
}

- (void)addDependency:(DCTConnectionController *)connectionController {
	
	if (!connectionController) return;
	
	if (!dependencies) dependencies = [[NSMutableSet alloc] initWithCapacity:1];
	
	[dependencies addObject:connectionController];
	[connectionController dctInternal_addDependent:self];
}

- (void)removeDependency:(DCTConnectionController *)connectionController {
	
	if (![dependencies containsObject:connectionController]) return;
	
	[dependencies removeObject:connectionController];
	[connectionController dctInternal_removeDependent:self];
}

- (void)dctInternal_start {
	
	// Make sure it isn't there
	[urlConnection cancel];
	[urlConnection release];
	urlConnection = nil;
		
	NSURLRequest *request = [self newRequest];
	
	self.URL = [request URL];
		
	urlConnection = [[DCTURLConnection alloc] initWithRequest:request delegate:self];
	[request release];
	
	self.status = DCTConnectionControllerStatusStarted;
	
	if (!urlConnection) [self dctInternal_finishWithFailure];
}

- (void)dctInternal_setQueued {
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
	// Call to finish here allows subclasses to change whether a connection was successfully or not. 
	// For example if the web service always responds successful, but returns an error in JSON, a 
	// subclass could call receivedError: and this would mean the core connection controller fails.
	[self dctInternal_finishWithSuccess];
}

- (void)receivedResponse:(NSURLResponse *)response {
	self.returnedResponse = response;
}

- (void)receivedError:(NSError *)error {
	self.returnedError = error;
	// Call to finish here allows subclasses to change whether a connection was successfully or not. 
	// For example if the web service always responds successful, but returns an error in JSON, a 
	// subclass could call receivedError: and this would mean the core connection controller fails.
	[self dctInternal_finishWithFailure];
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	self.returnedResponse = response;
    [self receivedResponse:response];
	[self dctInternal_announceResponse];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(DCTURLConnection *)connection appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSData *data = ((DCTURLConnection *)connection).data;
	
	[urlConnection cancel];
	[urlConnection release]; urlConnection = nil;
	
	self.returnedObject = data;
    [self receivedObject:data];
	[self dctInternal_finishWithSuccess];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.returnedError = error;
	
	[urlConnection cancel];
	[urlConnection release]; urlConnection = nil;
	
    [self receivedError:error];
	[self dctInternal_finishWithFailure];
}

#pragma mark -
#pragma mark Private methods

- (void)dctInternal_announceResponse {
	
	NSURLResponse *response = self.returnedResponse;
	
	for (DCTConnectionControllerResponseBlock block in responseBlocks)
		block(response);
	
	[self dctInternal_sendResponseToDelegate:response];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerResponseNotification object:self];
	
	self.status = DCTConnectionControllerStatusResponded;
}

- (void)dctInternal_finishWithSuccess {
	if ([self dctInternal_hasFinished]) return;
	
	id object = self.returnedObject;
	
	for (DCTConnectionControllerCompletionBlock block in completionBlocks)
		block(object);
	
	[self dctInternal_sendObjectToDelegate:object];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerCompletedNotification object:self];
	
	[self dctInternal_finish];
	
	self.status = DCTConnectionControllerStatusComplete;
}

- (void)dctInternal_finishWithFailure {
	if ([self dctInternal_hasFinished]) return;
	
	NSError *error = self.returnedError;
	
	for (DCTConnectionControllerFailureBlock block in failureBlocks)
		block(error);
	
	[self dctInternal_sendErrorToDelegate:error];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerFailedNotification object:self];

	[self dctInternal_finish];
	
	self.status = DCTConnectionControllerStatusFailed;
}

- (void)dctInternal_finishWithCancelation {
	if ([self dctInternal_hasFinished]) return;
	
	for (DCTConnectionControllerCancelationBlock block in cancelationBlocks)
		block();
	
	[self dctInternal_sendCancelationToDelegate:self.delegate];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerCancellationNotification object:self];

	[self dctInternal_finish];
	
	self.status = DCTConnectionControllerStatusCancelled;
}

- (void)dctInternal_finish {
	[delegate release]; delegate = nil;
	
	for (DCTConnectionController *dependent in self.dctInternal_dependents)
		[dependent removeDependency:self];
	
	[dependents release], dependents = nil;
}

#pragma mark -
#pragma mark Delegate handling

- (void)dctInternal_sendResponseToDelegate:(NSURLResponse *)response {
	if ([self.delegate respondsToSelector:@selector(connectionController:didReceiveResponse:)])
		[self.delegate connectionController:self didReceiveResponse:response];
}

- (void)dctInternal_sendCancelationToDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	if ([self.delegate respondsToSelector:@selector(connectionControllerWasCancelled:)])
		[self.delegate connectionControllerWasCancelled:self];
}

- (void)dctInternal_sendObjectToDelegate:(id)object {
	if ([self.delegate respondsToSelector:@selector(connectionController:didSucceedWithObject:)])
		[self.delegate connectionController:self didSucceedWithObject:object];
}

- (void)dctInternal_sendErrorToDelegate:(NSError *)error {
	if ([self.delegate respondsToSelector:@selector(connectionController:didFailWithError:)])
		[self.delegate connectionController:self didFailWithError:error];
}

#pragma mark -
#pragma mark Duplication handling

- (BOOL)isEqual:(id)object {
	
	if (![object isKindOfClass:[DCTConnectionController class]]) return NO;
	
	return [self isEqualToConnectionController:object];
}

#pragma mark -
#pragma mark Useful checks

- (BOOL)dctInternal_hasResponded {
	return (self.status >= DCTConnectionControllerStatusResponded);
}

- (BOOL)dctInternal_hasFinished {
	return (self.status > DCTConnectionControllerStatusResponded);
}

- (BOOL)dctInternal_hasFailed {
	return (self.status == DCTConnectionControllerStatusFailed);
}

- (BOOL)dctInternal_hasCompleted {
	return (self.status == DCTConnectionControllerStatusComplete);
}

- (BOOL)dctInternal_hasCancelled {
	return (self.status == DCTConnectionControllerStatusCancelled);
}

#pragma mark -
#pragma mark Internal getters

- (NSSet *)dctInternal_responseBlocks {
	
	if (!responseBlocks) return nil;
	
	return [NSSet setWithSet:responseBlocks];
}

- (NSSet *)dctInternal_completionBlocks {

	if (!completionBlocks) return nil;
	
	return [NSSet setWithSet:completionBlocks];
}

- (NSSet *)dctInternal_failureBlocks {
	
	if (!failureBlocks) return nil;
	
	return [NSSet setWithSet:failureBlocks];
}

- (NSSet *)dctInternal_cancelationBlocks {
	
	if (!cancelationBlocks) return nil;
	
	return [NSSet setWithSet:cancelationBlocks];
}

- (NSSet *)dctInternal_dependents {
	
	if (!dependents) return nil;
	
	return [NSSet setWithSet:dependents];
}

- (void)dctInternal_addDependent:(DCTConnectionController *)connectionController {
	
	if (!dependents) dependents = [[NSMutableSet alloc] initWithCapacity:1];
	
	[dependents addObject:connectionController];
}

- (void)dctInternal_removeDependent:(DCTConnectionController *)connectionController {
	[dependents removeObject:connectionController];
}

@end
