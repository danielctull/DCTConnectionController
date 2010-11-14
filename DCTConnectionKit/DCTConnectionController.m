//
//  DCTConnectionController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"
#import "DCTConnectionQueue+Singleton.h"
#import "DCTConnectionController+DCTEquality.h"
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
- (void)dctInternal_notifyBlockOfObject:(NSObject *)object;

- (void)dctInternal_notifyDelegateOfReturnedError:(NSError *)error;
- (void)dctInternal_notifyObserversOfReturnedError:(NSError *)error;
- (void)dctInternal_notifyBlockOfReturnedError:(NSError *)error;

- (void)dctInternal_notifyDelegateOfCancellation;
- (void)dctInternal_notifyObserversOfCancellation;
- (void)dctInternal_notifyBlockOfCancellation;

- (void)dctInternal_notifyDelegateOfResponse:(NSURLResponse *)response;
- (void)dctInternal_notifyObserversOfResponse:(NSURLResponse *)response;
- (void)dctInternal_notifyBlockOfResponse:(NSURLResponse *)response;
@end


@implementation DCTConnectionController

@synthesize status, type, priority, multitaskEnabled, URL, returnedObject, returnedError, returnedResponse;
@synthesize completionBlock, failureBlock, responseBlock, cancelationBlock;

+ (id)connectionController {
	return [[[self alloc] init] autorelease];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	dependencies = [[NSMutableArray alloc] init];
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
	[super dealloc];
}

#pragma mark -
#pragma mark Depricated Blocks

- (void)setResponseBlock:(DCTConnectionControllerResponseBlock)block {
	[self addResponseBlock:block];
}

- (DCTConnectionControllerResponseBlock)responseBlock {
	return nil;
}

- (void)setCompletionBlock:(DCTConnectionControllerCompletionBlock)block {
	[self addCompletionBlock:block];
}

- (DCTConnectionControllerCompletionBlock)completionBlock {
	return nil;
}

- (void)setFailureBlock:(DCTConnectionControllerFailureBlock)block {
	[self addFailureBlock:block];
}

- (DCTConnectionControllerFailureBlock)failureBlock {
	return nil;
}

- (void)setCancelationBlock:(DCTConnectionControllerCancelationBlock)block {
	[self addCancelationBlock:block];
}

- (DCTConnectionControllerCancelationBlock)cancelationBlock {
	return nil;
}

#pragma mark -
#pragma mark Block methods

- (void)addResponseBlock:(DCTConnectionControllerResponseBlock)block {
	[responseBlocks dct_addBlock:block];
}

- (void)addCompletionBlock:(DCTConnectionControllerCompletionBlock)block {
	[completionBlocks dct_addBlock:block];
}

- (void)addFailureBlock:(DCTConnectionControllerFailureBlock)block {
	[failureBlocks dct_addBlock:block];
}

- (void)addCancelationBlock:(DCTConnectionControllerCancelationBlock)block {
	[cancelationBlocks dct_addBlock:block];
}

#pragma mark -
#pragma mark Delegatation

- (void)setDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	[self addDelegate:delegate];
}

- (id<DCTConnectionControllerDelegate>)delegate {
	return nil;
}

- (void)addDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	[delegates addObject:delegate];
}

- (void)addDelegates:(NSSet *)delegateArray {
	[delegates unionSet:delegateArray];
}

- (void)removeDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	[delegates removeObject:delegate];
}

- (void)removeDelegates:(NSSet *)delegatesToRemove {
	[delegates minusSet:delegatesToRemove];
}

- (NSSet *)delegates {
	return [NSSet setWithSet:delegates];
}

#pragma mark -
#pragma mark Managing the connection

- (DCTConnectionController *)connect {
	return [[DCTConnectionQueue sharedConnectionQueue] addConnectionController:self];
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
	[self dctInternal_notifyBlockOfResponse:self.returnedResponse];
	self.status = DCTConnectionControllerStatusResponded;
}

- (void)dctInternal_finishWithSuccess {
	[self dctInternal_notifyDelegateOfObject:self.returnedObject];
	[self dctInternal_notifyObserversOfObject:self.returnedObject];
	[self dctInternal_notifyBlockOfObject:self.returnedObject];
	self.status = DCTConnectionControllerStatusComplete;
	[delegates release]; delegates = nil;
}

- (void)dctInternal_finishWithFailure {
	[self dctInternal_notifyDelegateOfReturnedError:self.returnedError];
	[self dctInternal_notifyObserversOfReturnedError:self.returnedError];
	[self dctInternal_notifyBlockOfReturnedError:self.returnedError];
	self.status = DCTConnectionControllerStatusFailed;
	[delegates release]; delegates = nil;
}

- (void)dctInternal_finishWithCancelation {
	[self dctInternal_notifyDelegateOfCancellation];
	[self dctInternal_notifyObserversOfCancellation];
	[self dctInternal_notifyBlockOfCancellation];
	self.status = DCTConnectionControllerStatusCancelled;
	[delegates release]; delegates = nil;
}

#pragma mark -
#pragma mark Private object notification methods

- (void)dctInternal_notifyDelegateOfObject:(NSObject *)object {	
	
	for (id<DCTConnectionControllerDelegate> delegate in delegates) {
		
		if ([delegate respondsToSelector:@selector(connectionController:didSucceedWithObject:)])
			[delegate connectionController:self didSucceedWithObject:object];
	}
}

- (void)dctInternal_notifyObserversOfObject:(NSObject *)object {
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerCompletedNotification object:self];
}

- (void)dctInternal_notifyBlockOfObject:(NSObject *)object {
	if (self.completionBlock) self.completionBlock(object);
}

#pragma mark -
#pragma mark Private error notification methods

- (void)dctInternal_notifyDelegateOfReturnedError:(NSError *)error {
	
	for (id<DCTConnectionControllerDelegate> delegate in delegates) {
		
		if ([delegate respondsToSelector:@selector(connectionController:didFailWithError:)])
			[delegate connectionController:self didFailWithError:error];
	}
}

- (void)dctInternal_notifyObserversOfReturnedError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerFailedNotification object:self];
}

- (void)dctInternal_notifyBlockOfReturnedError:(NSError *)error {
	if (self.failureBlock) self.failureBlock(error);
}

#pragma mark -
#pragma mark Private cancelation notification methods

- (void)dctInternal_notifyDelegateOfCancellation {
	for (id<DCTConnectionControllerDelegate> delegate in delegates) {
		
		if ([delegate respondsToSelector:@selector(connectionControllerWasCancelled:)])
			[delegate connectionControllerWasCancelled:self];
	}
}

- (void)dctInternal_notifyObserversOfCancellation {
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerCancellationNotification object:self];
}

- (void)dctInternal_notifyBlockOfCancellation {
	if (self.cancelationBlock) self.cancelationBlock();
}

#pragma mark -
#pragma mark Private response notification methods

- (void)dctInternal_notifyDelegateOfResponse:(NSURLResponse *)response {
	for (id<DCTConnectionControllerDelegate> delegate in delegates) {
		
		if ([delegate respondsToSelector:@selector(connectionController:didReceiveResponse:)])
			[delegate connectionController:self didReceiveResponse:response];
	}
}

- (void)dctInternal_notifyObserversOfResponse:(NSURLResponse *)response {
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerResponseNotification object:self];
}


- (void)dctInternal_notifyBlockOfResponse:(NSURLResponse *)response {
	if (self.responseBlock) self.responseBlock(response);
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

- (NSSet *)observationInformation {
	return [NSSet setWithSet:observationInfos];
}

@end
