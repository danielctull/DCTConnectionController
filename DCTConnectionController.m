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

@property (nonatomic, readonly) NSSet *dctInternal_delegates;
@property (nonatomic, readonly) NSSet *dctInternal_responseBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_completionBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_failureBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_cancelationBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_observationInformation;

- (void)dctInternal_mergeInformationFromConnectionController:(DCTConnectionController *)connectionController;

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

- (void)dctInternal_sendResponse:(NSURLResponse *)response toDelegate:(id<DCTConnectionControllerDelegate>)delegate;
- (void)dctInternal_sendCancelationToDelegate:(id<DCTConnectionControllerDelegate>)delegate;
- (void)dctInternal_sendObject:(id)object toDelegate:(id<DCTConnectionControllerDelegate>)delegate;
- (void)dctInternal_sendError:(NSError *)error toDelegate:(id<DCTConnectionControllerDelegate>)delegate;

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

@synthesize status, type, priority, multitaskEnabled, URL, returnedObject, returnedError, returnedResponse;

+ (id)connectionController {
	return [[[self alloc] init] autorelease];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	dependencies = [[NSMutableSet alloc] init];
	dependents = [[NSMutableSet alloc] init];
	priority = DCTConnectionControllerPriorityMedium;
	delegates = [[NSMutableSet alloc] init];
	observationInfos = [[NSMutableSet alloc] init];
	responseBlocks = [[NSMutableSet alloc] init];
	
	return self;
}

- (void)dealloc {
	[responseBlocks release], responseBlocks = nil;
	[observationInfos release], observationInfos = nil;
	[delegates release]; delegates = nil;
	[dependencies release], dependencies = nil;
	[dependents release], dependents = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Block methods

- (void)addResponseBlock:(DCTConnectionControllerResponseBlock)block {
	
	if ([self dctInternal_hasResponded]) block(self.returnedResponse);
	
	[responseBlocks dct_addBlock:block];
}

- (void)addCompletionBlock:(DCTConnectionControllerCompletionBlock)block {
	
	if ([self dctInternal_hasCompleted]) block(self.returnedObject);
	
	[completionBlocks dct_addBlock:block];
}

- (void)addFailureBlock:(DCTConnectionControllerFailureBlock)block {
	
	if ([self dctInternal_hasFailed]) block(self.returnedError);
	
	[failureBlocks dct_addBlock:block];
}

- (void)addCancelationBlock:(DCTConnectionControllerCancelationBlock)block {
	
	if ([self dctInternal_hasCancelled]) block();
		
	[cancelationBlocks dct_addBlock:block];
}

#pragma mark -
#pragma mark Delegatation

- (void)addDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	
	if ([self dctInternal_hasResponded]) [self dctInternal_sendResponse:self.returnedResponse toDelegate:delegate];
	
	if ([self dctInternal_hasFailed]) [self dctInternal_sendError:self.returnedError toDelegate:delegate];
	
	if ([self dctInternal_hasCompleted]) [self dctInternal_sendObject:self.returnedObject toDelegate:delegate];
	
	[delegates addObject:delegate];
}

- (void)removeDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	[delegates removeObject:delegate];
}

- (NSSet *)delegates {
	return [NSSet setWithSet:delegates];
}

#pragma mark -
#pragma mark Managing the connection

- (DCTConnectionController *)connect {
	
	DCTConnectionQueue *queue = [DCTConnectionQueue sharedConnectionQueue];
	
	NSUInteger existingConnectionControllerIndex = [queue.connectionControllers indexOfObject:self];
	
	if (existingConnectionControllerIndex != NSNotFound) {
		
		DCTConnectionController *existingConnectionController = [queue.connectionControllers objectAtIndex:existingConnectionControllerIndex];
		
		[existingConnectionController dctInternal_mergeInformationFromConnectionController:self];
		
		return existingConnectionController;
	}
	
	[queue addConnectionController:self];
	return self;
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
	return [dependencies allObjects];
}

- (void)addDependency:(DCTConnectionController *)connectionController {
	
	if (!connectionController) return;
	
	[dependencies addObject:connectionController];
	[connectionController dctInternal_addDependent:self];
}

- (void)removeDependency:(DCTConnectionController *)connectionController {
	
	if (![dependencies containsObject:connectionController]) return;
	
	[dependencies removeObject:connectionController];
	[connectionController dctInternal_removeDependent:self];
}

- (void)start {
	
	// Make sure it isn't there
	[urlConnection cancel];
	[urlConnection release];
	urlConnection = nil;
	
	
	DCTConnectionQueue *queue = [DCTConnectionQueue sharedConnectionQueue];
	
	NSUInteger existingConnectionControllerIndex = [queue.connectionControllers indexOfObject:self];
	
	if (existingConnectionControllerIndex != NSNotFound) {
		
		DCTConnectionController *existingConnectionController = [queue.connectionControllers objectAtIndex:existingConnectionControllerIndex];
		
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
		
	NSURLRequest *request = [self newRequest];
	
	self.URL = [request URL];
		
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
	
	self.status = DCTConnectionControllerStatusResponded;
	
	NSURLResponse *response = self.returnedResponse;
	
	for (DCTConnectionControllerResponseBlock block in responseBlocks)
		block(response);
	
	[self.dctInternal_delegates enumerateObjectsUsingBlock:^(id delegate, BOOL *stop) {
		[self dctInternal_sendResponse:response toDelegate:delegate];
	}];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerResponseNotification object:self];	
}

- (void)dctInternal_finishWithSuccess {
	if ([self dctInternal_hasFinished]) return;
	
	self.status = DCTConnectionControllerStatusComplete;
	
	id object = self.returnedObject;
	
	for (DCTConnectionControllerCompletionBlock block in completionBlocks)
		block(object);
	
	[self.dctInternal_delegates enumerateObjectsUsingBlock:^(id delegate, BOOL *stop) {
		[self dctInternal_sendObject:object toDelegate:delegate];
	}];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerCompletedNotification object:self];
	
	[self dctInternal_finish];
}

- (void)dctInternal_finishWithFailure {
	if ([self dctInternal_hasFinished]) return;
	
	self.status = DCTConnectionControllerStatusFailed;
	
	NSError *error = self.returnedError;
	
	for (DCTConnectionControllerFailureBlock block in failureBlocks)
		block(error);
	
	[self.dctInternal_delegates enumerateObjectsUsingBlock:^(id delegate, BOOL *stop) {
		[self dctInternal_sendError:error toDelegate:delegate];
	}];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerFailedNotification object:self];

	[self dctInternal_finish];
}

- (void)dctInternal_finishWithCancelation {
	if ([self dctInternal_hasFinished]) return;

	self.status = DCTConnectionControllerStatusCancelled;	
	
	for (DCTConnectionControllerCancelationBlock block in cancelationBlocks)
		block();
	
	[self.dctInternal_delegates enumerateObjectsUsingBlock:^(id delegate, BOOL *stop) {
		[self dctInternal_sendCancelationToDelegate:delegate];
	}];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerCancellationNotification object:self];

	[self dctInternal_finish];
}

- (void)dctInternal_finish {
	[delegates release]; delegates = nil;
	
	for (DCTConnectionController *dependent in self.dctInternal_dependents)
		[dependent removeDependency:self];
	
	[dependents release], dependents = nil;
}

#pragma mark -
#pragma mark Delegate handling

- (void)dctInternal_sendResponse:(NSURLResponse *)response toDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	if ([delegate respondsToSelector:@selector(connectionController:didReceiveResponse:)])
		[delegate connectionController:self didReceiveResponse:response];
}

- (void)dctInternal_sendCancelationToDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	if ([delegate respondsToSelector:@selector(connectionControllerWasCancelled:)])
		[delegate connectionControllerWasCancelled:self];
}

- (void)dctInternal_sendObject:(id)object toDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	if ([delegate respondsToSelector:@selector(connectionController:didSucceedWithObject:)])
		[delegate connectionController:self didSucceedWithObject:object];
}

- (void)dctInternal_sendError:(NSError *)error toDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	if ([delegate respondsToSelector:@selector(connectionController:didFailWithError:)])
		[delegate connectionController:self didFailWithError:error];
}

#pragma mark -
#pragma mark Duplication handling

- (BOOL)isEqual:(id)object {
	
	if (![object isKindOfClass:[DCTConnectionController class]]) return NO;
	
	return [self isEqualToConnectionController:object];
}

- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
	[super addObserver:anObserver forKeyPath:keyPath options:options context:context];
	
	DCTObservationInfo *info = [[DCTObservationInfo alloc] init];
	info.object = anObserver;
	info.keyPath = keyPath;
	info.options = options;
	info.context = context;
	[observationInfos addObject:info];
	[info release];
}

- (void)removeObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath {
	[super removeObserver:anObserver forKeyPath:keyPath];
	
	NSSet *infos = [observationInfos dct_observationInfosWithObject:anObserver keyPath:keyPath];	
	[observationInfos minusSet:infos];
}


- (void)dctInternal_mergeInformationFromConnectionController:(DCTConnectionController *)connectionController {
	
	// Add the delegates from the given connection controller
	for (id<DCTConnectionControllerDelegate> delegate in connectionController.dctInternal_delegates)
		[self addDelegate:delegate];	
	
	// Add blocks from the given connection controller:
	
	for (DCTConnectionControllerResponseBlock block in connectionController.dctInternal_responseBlocks)
		[self addResponseBlock:block];
	
	for (DCTConnectionControllerCancelationBlock block in connectionController.dctInternal_cancelationBlocks)
		[self addCancelationBlock:block];
	
	for (DCTConnectionControllerCompletionBlock block in connectionController.dctInternal_completionBlocks)
		[self addCompletionBlock:block];
	
	for (DCTConnectionControllerFailureBlock block in connectionController.dctInternal_failureBlocks)
		[self addFailureBlock:block];
	
	// Add the observers from the duplicated connection to the existing one, and remove from the merged one
	for (DCTObservationInfo *info in [connectionController dctInternal_observationInformation]) {
		
		if ([[[self dctInternal_observationInformation] dct_observationInfosWithObject:info.object	keyPath:info.keyPath] count] == 0)
			[self addObserver:info.object forKeyPath:info.keyPath options:info.options context:info.context];
		
		[connectionController removeObserver:info.object forKeyPath:info.keyPath];
	}
	
	
	for (DCTConnectionController *dependent in connectionController.dctInternal_dependents) {
		[dependent removeDependency:connectionController];
		[dependent addDependency:self];
	}
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

- (NSSet *)dctInternal_delegates {
	return [NSSet setWithSet:delegates];
}

- (NSSet *)dctInternal_responseBlocks {
	return [NSSet setWithSet:responseBlocks];
}

- (NSSet *)dctInternal_completionBlocks {
	return [NSSet setWithSet:completionBlocks];
}

- (NSSet *)dctInternal_failureBlocks {
	return [NSSet setWithSet:failureBlocks];
}

- (NSSet *)dctInternal_cancelationBlocks {
	return [NSSet setWithSet:cancelationBlocks];
}

- (NSSet *)dctInternal_observationInformation {
	return [NSSet setWithSet:observationInfos];
}

- (NSSet *)dctInternal_dependents {
	return [NSSet setWithSet:dependents];
}

- (void)dctInternal_addDependent:(DCTConnectionController *)connectionController {
	[dependents addObject:connectionController];
}

- (void)dctInternal_removeDependent:(DCTConnectionController *)connectionController {
	[dependents removeObject:connectionController];
}

@end
