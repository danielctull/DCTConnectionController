/*
 DCTConnectionController.m
 DCTConnectionController
 
 Created by Daniel Tull on 9.6.2010.
 
 
 
 Copyright (c) 2010 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DCTConnectionController.h"
#import "DCTConnectionQueue+Singleton.h"
#import "DCTConnectionController+Equality.h"
#import "DCTObservationInfo.h"
#import "NSMutableSet+DCTExtras.h"
#import "NSObject+DCTKVOExtras.h"

NSString * const DCTConnectionControllerTypeString[] = {
	@"GET",
	@"POST",
	@"PUT",
	@"DELETE",
	@"OPTIONS",
	@"HEAD",
	@"TRACE",
	@"CONNECT",
	@"PATCH"
};


NSString *const DCTConnectionControllerDidReceiveObjectNotification = @"DCTConnectionControllerDidReceiveObjectNotification";
NSString *const DCTConnectionControllerDidReceiveErrorNotification = @"DCTConnectionControllerDidReceiveErrorNotification";
NSString *const DCTConnectionControllerDidReceiveResponseNotification = @"DCTConnectionControllerDidReceiveResponseNotification";
NSString *const DCTConnectionControllerCancellationNotification = @"DCTConnectionControllerCancellationNotification";

@interface DCTConnectionController ()

- (void)dctInternal_reset;
- (void)dctInternal_start;
- (void)dctInternal_setQueued;

@property (nonatomic, readonly) NSSet *dctInternal_responseBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_completionBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_failureBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_cancelationBlocks;

@property (nonatomic, strong, readwrite) NSURL *URL;
@property (nonatomic, readwrite) DCTConnectionControllerStatus status;
@property (nonatomic, strong, readwrite) NSObject *returnedObject;
@property (nonatomic, strong, readwrite) NSError *returnedError;
@property (nonatomic, strong, readwrite) NSURLResponse *returnedResponse;

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


@implementation DCTConnectionController {
	__strong DCTURLConnection *urlConnection;
	__strong NSURL *URL;
	__strong NSMutableSet *dependencies;
	__strong NSMutableSet *dependents;
	__strong NSMutableSet *responseBlocks;
	__strong NSMutableSet *completionBlocks;
	__strong NSMutableSet *failureBlocks;
	__strong NSMutableSet *cancelationBlocks;
	
	__strong NSFileHandle *fileHandle; // Used if a path is given.
	float contentLength, downloadedLength;
}

@synthesize status, type, priority, multitaskEnabled, URL, returnedObject, returnedError, returnedResponse, delegate, downloadPath, percentDownloaded;

+ (id)connectionController {
	return [[self alloc] init];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	priority = DCTConnectionControllerPriorityMedium;
	percentDownloaded = [[NSNumber alloc] initWithInteger:0];
	
	return self;
}

#pragma mark - Block methods

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


#pragma mark - Managing the connection

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
	 urlConnection = nil;
}

- (void)dctInternal_reset {
	[urlConnection cancel];
	 urlConnection = nil;
	self.returnedResponse = nil;
	self.returnedError = nil;
	self.returnedObject = nil;
	self.status = DCTConnectionControllerStatusNotStarted;
}

#pragma mark - Dependency methods

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
	urlConnection = nil;
	
	NSURLRequest *request = [self newRequest];
	
	self.URL = [request URL];
	
	urlConnection = [[DCTURLConnection alloc] initWithRequest:request delegate:self];
	
	self.status = DCTConnectionControllerStatusStarted;
	
	if (!urlConnection) [self dctInternal_finishWithFailure];
}

- (void)dctInternal_setQueued {
	self.status = DCTConnectionControllerStatusQueued;
}

#pragma mark - Subclass methods

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:DCTConnectionControllerTypeString[type]];	
	return request;
}

- (void)connectionDidReceiveObject:(NSObject *)object {
	self.returnedObject = object;
	// Call to finish here allows subclasses to change whether a connection was successfully or not. 
	// For example if the web service always responds successful, but returns an error in JSON, a 
	// subclass could call receivedError: and this would mean the core connection controller fails.
	[self dctInternal_finishWithSuccess];
}

- (void)connectionDidReceiveResponse:(NSURLResponse *)response {
	self.returnedResponse = response;
}

- (void)connectionDidReceiveError:(NSError *)error {
	self.returnedError = error;
	// Call to finish here allows subclasses to change whether a connection was successfully or not. 
	// For example if the web service always responds successful, but returns an error in JSON, a 
	// subclass could call receivedError: and this would mean the core connection controller fails.
	[self dctInternal_finishWithFailure];
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
	contentLength = (float)[response expectedContentLength];
	
	if (self.downloadPath) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		
		if ([fileManager fileExistsAtPath:self.downloadPath])
			[fileManager removeItemAtPath:self.downloadPath error:nil];
		
		[fileManager createFileAtPath:self.downloadPath
							 contents:nil
						   attributes:nil];
	
		fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.downloadPath];
	}
	
	self.returnedResponse = response;
    [self connectionDidReceiveResponse:response];
	[self dctInternal_announceResponse];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	
	if (contentLength > 0) {
		downloadedLength += (float)[data length];
		[self dct_changeValueForKey:@"percentDownloaded" withChange:^{
			percentDownloaded = [NSNumber numberWithFloat:(downloadedLength / contentLength)];
			
		}];
	}
	
	if (fileHandle) {
		[fileHandle seekToEndOfFile];
		[fileHandle writeData:data];
		return;
	}
	
	[(DCTURLConnection *)connection appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	if ([self.percentDownloaded integerValue] < 1.0) {
		[self dct_changeValueForKey:@"percentDownloaded" withChange:^{
			percentDownloaded = [NSNumber numberWithInteger:1];
			
		}];
	}
	
	NSData *data = ((DCTURLConnection *)connection).data;
	
	if (fileHandle) {
		[fileHandle closeFile];
		data = nil;
	}
	
	[urlConnection cancel];
	 urlConnection = nil;
	
	self.returnedObject = data;
    [self connectionDidReceiveObject:data];
	[self dctInternal_finishWithSuccess];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.returnedError = error;
	
	[urlConnection cancel];
	 urlConnection = nil;
	
    [self connectionDidReceiveError:error];
	[self dctInternal_finishWithFailure];
}

#pragma mark - Private methods

- (void)dctInternal_announceResponse {
	
	NSURLResponse *response = self.returnedResponse;
	
	for (DCTConnectionControllerResponseBlock block in responseBlocks)
		block(response);
	
	[self dctInternal_sendResponseToDelegate:response];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerDidReceiveResponseNotification object:self];
	
	self.status = DCTConnectionControllerStatusResponded;
}

- (void)dctInternal_finishWithSuccess {
	if ([self dctInternal_hasFinished]) return;
	
	id object = self.returnedObject;
	
	for (DCTConnectionControllerCompletionBlock block in completionBlocks)
		block(object);
	
	[self dctInternal_sendObjectToDelegate:object];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerDidReceiveObjectNotification object:self];
	
	[self dctInternal_finish];
	
	self.status = DCTConnectionControllerStatusComplete;
}

- (void)dctInternal_finishWithFailure {
	if ([self dctInternal_hasFinished]) return;
	
	NSError *error = self.returnedError;
	
	for (DCTConnectionControllerFailureBlock block in failureBlocks)
		block(error);
	
	[self dctInternal_sendErrorToDelegate:error];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerDidReceiveErrorNotification object:self];

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
	 delegate = nil;
	
	for (DCTConnectionController *dependent in self.dctInternal_dependents)
		[dependent removeDependency:self];
	
	dependents = nil;
}

#pragma mark - Delegate handling

- (void)dctInternal_sendResponseToDelegate:(NSURLResponse *)response {
	if ([self.delegate respondsToSelector:@selector(connectionController:didReceiveResponse:)])
		[self.delegate connectionController:self didReceiveResponse:response];
}

- (void)dctInternal_sendCancelationToDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	if ([self.delegate respondsToSelector:@selector(connectionControllerWasCancelled:)])
		[self.delegate connectionControllerWasCancelled:self];
}

- (void)dctInternal_sendObjectToDelegate:(id)object {
	if ([self.delegate respondsToSelector:@selector(connectionController:didReceiveObject:)])
		[self.delegate connectionController:self didReceiveObject:object];
}

- (void)dctInternal_sendErrorToDelegate:(NSError *)error {
	if ([self.delegate respondsToSelector:@selector(connectionController:didReceiveError:)])
		[self.delegate connectionController:self didReceiveError:error];
}

#pragma mark - Duplication handling

- (BOOL)isEqual:(id)object {
	
	if (![object isKindOfClass:[DCTConnectionController class]]) return NO;
	
	return [self isEqualToConnectionController:object];
}

#pragma mark - Useful checks

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

#pragma mark - Internal getters

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