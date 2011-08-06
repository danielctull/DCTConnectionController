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
#import "DCTConnectionController+UsefulChecks.h"
#import "DCTObservationInfo.h"
#import "NSMutableSet+DCTExtras.h"
#import "NSObject+DCTKVOExtras.h"

NSString * const DCTConnectionControllerStatusString[] = {
	@"NotStarted",
	@"Queued",
	@"Started",
	@"Responded",
	@"Finished",
	@"Failed",
	@"Cancelled"
};

NSString * const DCTConnectionControllerPriorityString[] = {
	@"VeryHigh",
	@"High",
	@"Medium",
	@"Low",
	@"VeryLow"
};

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

NSString *const DCTConnectionControllerDidFinishNotification = @"DCTConnectionControllerDidFinishNotification";
NSString *const DCTConnectionControllerDidFailNotification = @"DCTConnectionControllerDidFailNotification";
NSString *const DCTConnectionControllerDidReceiveResponseNotification = @"DCTConnectionControllerDidReceiveResponseNotification";
NSString *const DCTConnectionControllerWasCancelledNotification = @"DCTConnectionControllerWasCancelledNotification";

@interface DCTConnectionController ()

- (void)dctInternal_reset;
- (void)dctInternal_start;
- (void)dctInternal_setQueued;

@property (nonatomic, readonly) NSSet *dctInternal_responseBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_completionBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_failureBlocks;
@property (nonatomic, readonly) NSSet *dctInternal_cancelationBlocks;

@property (nonatomic, readwrite) DCTConnectionControllerStatus status;
@property (nonatomic, strong, readwrite) NSObject *returnedObject;
@property (nonatomic, strong, readwrite) NSError *returnedError;
@property (nonatomic, strong, readwrite) NSURLResponse *returnedResponse;

- (void)dctInternal_responded;
- (void)dctInternal_failed;
- (void)dctInternal_finished;
- (void)dctInternal_cancelled;
- (void)dctInternal_cleanup;

- (void)dctInternal_sendResponseToDelegate:(NSURLResponse *)response;
- (void)dctInternal_sendCancelationToDelegate:(id<DCTConnectionControllerDelegate>)delegate;
- (void)dctInternal_sendObjectToDelegate:(id)object;
- (void)dctInternal_sendErrorToDelegate:(NSError *)error;

- (void)dctInternal_calculatePercentDownloaded;

@property (nonatomic, readonly) NSSet *dctInternal_dependents;
- (void)dctInternal_addDependent:(DCTConnectionController *)connectionController;
- (void)dctInternal_removeDependent:(DCTConnectionController *)connectionController;
- (void)dctInternal_setURL:(NSURL *)newURL;

@end


@implementation DCTConnectionController {
	__strong NSMutableSet *dependencies;
	__strong NSMutableSet *dependents;
	__strong NSMutableSet *responseBlocks;
	__strong NSMutableSet *completionBlocks;
	__strong NSMutableSet *failureBlocks;
	__strong NSMutableSet *cancelationBlocks;
	
	__strong NSFileHandle *fileHandle; // Used if a path is given.
	float contentLength, downloadedLength;
}

@synthesize status, type, priority, multitaskEnabled, delegate, downloadPath, percentDownloaded;
@synthesize returnedObject, returnedError, returnedResponse;
@synthesize URL, URLRequest, URLConnection;

#pragma mark - NSObject

+ (id)connectionController {
	return [[self alloc] init];
}

- (void)dealloc {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	if ([fileManager fileExistsAtPath:self.downloadPath] && ![fileManager removeItemAtPath:self.downloadPath error:&error])
		NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), error);
	
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	priority = DCTConnectionControllerPriorityMedium;
	percentDownloaded = [[NSNumber alloc] initWithInteger:0];
	
	return self;
}

- (BOOL)isEqual:(id)object {
	
	if (![object isKindOfClass:[DCTConnectionController class]]) return NO;
	
	return [self isEqualToConnectionController:object];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; url = \"%@\"; status = %@; priority = %@>", 
			NSStringFromClass([self class]),
			self,
			self.URL,
			DCTConnectionControllerStatusString[self.status],
			DCTConnectionControllerPriorityString[self.priority]];
}

#pragma mark - DCTConnectionController: Managing the connection

- (void)connect {
		
	DCTConnectionQueue *queue = [DCTConnectionQueue sharedConnectionQueue];
	
	NSUInteger existingConnectionControllerIndex = [queue.connectionControllers indexOfObject:self];
	
	if (existingConnectionControllerIndex != NSNotFound) {
		
		DCTConnectionController *existingConnectionController = [queue.connectionControllers objectAtIndex:existingConnectionControllerIndex];
		
		if (existingConnectionController.priority > self.priority)
			existingConnectionController.priority = self.priority;
		
		self.status = existingConnectionController.status;
		
		[existingConnectionController addResponseHandler:^(NSURLResponse *response) {
			self.returnedResponse = response;
			[self dctInternal_responded];
		}];
		
		__block DCTConnectionController *cc = existingConnectionController;
		
		[existingConnectionController addFinishHandler:^() {
			self.returnedObject = cc.returnedObject;
			[self dctInternal_finished];
		}];
		
		[existingConnectionController addFailureHandler:^(NSError *error) {
			self.returnedError = error;
			[self dctInternal_failed];
		}];
		
		[existingConnectionController addCancelationHandler:^(void) {
			[self dctInternal_cancelled];
		}];
		
		return;
	}
		
	[queue addConnectionController:self];
}

- (void)requeue {
	[[DCTConnectionQueue sharedConnectionQueue] requeueConnectionController:self];
}

- (void)cancel {
	[self.URLConnection cancel];
	[self dctInternal_cancelled];
	URLConnection = nil;
}

#pragma mark - DCTConnectionController: Dependency

- (NSArray *)dependencies {
	return [dependencies allObjects];
}

- (void)addDependency:(DCTConnectionController *)connectionController {
	
	NSAssert(connectionController != nil, @"connectionController is nil");
	
	if (!dependencies) dependencies = [[NSMutableSet alloc] initWithCapacity:1];
	
	[dependencies addObject:connectionController];
	[connectionController dctInternal_addDependent:self];
}

- (void)removeDependency:(DCTConnectionController *)connectionController {
	
	if (![dependencies containsObject:connectionController]) return;
	
	[dependencies removeObject:connectionController];
	[connectionController dctInternal_removeDependent:self];
}

#pragma mark - DCTConnectionController: Subclass methods

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:self.URL];
	[request setHTTPMethod:DCTConnectionControllerTypeString[type]];	
	return request;
}

- (void)connectionDidFinishLoading {	
	// Call to finish here allows subclasses to change whether a connection was successfully or not. 
	// For example if the web service always responds successful, but returns an error in JSON, a 
	// subclass could call receivedError: and this would mean the core connection controller fails.
	[self dctInternal_finished];
}

- (void)connectionDidReceiveResponse:(NSURLResponse *)response {
	self.returnedResponse = response;
}

- (void)connectionDidFailWithError:(NSError *)error {
	self.returnedError = error;
	// Call to finish here allows subclasses to change whether a connection was successfully or not. 
	// For example if the web service always responds successful, but returns an error in JSON, a 
	// subclass could call receivedError: and this would mean the core connection controller fails.
	[self dctInternal_failed];
}

#pragma mark - DCTConnectionController: Setters

- (void)setURLRequest:(NSURLRequest *)newURLRequest {
	
	if (self.started) return;
	
	if ([newURLRequest isEqual:self.URLRequest]) return;
	
	URLRequest = newURLRequest;
	[self dctInternal_setURL:URLRequest.URL];
}

- (void)setURL:(NSURL *)newURL {
	
	if (self.started) return;
	
	[self dctInternal_setURL:newURL];
}

#pragma mark - DCTConnectionController: Getters

- (NSURLConnection *)URLConnection {
	
	if (!URLConnection) {
		URLConnection = [[NSURLConnection alloc] initWithRequest:self.URLRequest delegate:self];
	}
	
	return URLConnection;
}

- (NSURLRequest *)URLRequest {
	
	if (!URLRequest) URLRequest = [[self newRequest] copy];
	
	[self dctInternal_setURL:[URLRequest URL]];
	
	return URLRequest;
}

- (NSObject *)returnedObject {
	
	if (!returnedObject) {
		returnedObject = [[NSData alloc] initWithContentsOfFile:self.downloadPath];
	}
	
	return returnedObject;
}

- (NSString *)downloadPath {
	
	if (!downloadPath) {
		NSString *temporaryDirectory = NSTemporaryDirectory();
		temporaryDirectory = [temporaryDirectory stringByAppendingPathComponent:@"DCTConnectionController"];
		
		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:temporaryDirectory
									   withIntermediateDirectories:YES
														attributes:nil
															 error:&error])
			NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), error);
		
		downloadPath = [temporaryDirectory stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	}
	
	return downloadPath;
}

#pragma mark - DCTConnectionController: Block methods

- (void)addResponseHandler:(DCTConnectionControllerResponseBlock)handler {
	
	if (!responseBlocks) responseBlocks = [[NSMutableSet alloc] initWithCapacity:1];
	
	if (self.didReceiveResponse) handler(self.returnedResponse);
	
	[responseBlocks dct_addBlock:handler];
}

- (void)addFinishHandler:(DCTConnectionControllerFinishBlock)handler {
	
	if (!completionBlocks) completionBlocks = [[NSMutableSet alloc] initWithCapacity:1];
	
	if (self.finished) handler();
	
	[completionBlocks dct_addBlock:handler];
}

- (void)addFailureHandler:(DCTConnectionControllerFailureBlock)handler {
	
	if (!failureBlocks) failureBlocks = [[NSMutableSet alloc] initWithCapacity:1];
	
	if (self.failed) handler(self.returnedError);
	
	[failureBlocks dct_addBlock:handler];
}

- (void)addCancelationHandler:(DCTConnectionControllerCancelationBlock)handler {
	
	if (!cancelationBlocks) cancelationBlocks = [[NSMutableSet alloc] initWithCapacity:1];
	
	if (self.cancelled) handler();
	
	[cancelationBlocks dct_addBlock:handler];
}















#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
	contentLength = (float)[response expectedContentLength];
		
	self.returnedResponse = response;
    [self connectionDidReceiveResponse:response];
	[self dctInternal_responded];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
		
	if (contentLength > 0) {
		downloadedLength += (float)[data length];
		[self dctInternal_calculatePercentDownloaded];
	}
	
	if (!fileHandle) {
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if ([fileManager fileExistsAtPath:self.downloadPath])
			[fileManager removeItemAtPath:self.downloadPath error:nil];
		
		[fileManager createFileAtPath:self.downloadPath
							 contents:nil
						   attributes:nil];
		
		fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.downloadPath];	
	}
	
	[fileHandle seekToEndOfFile];
	[fileHandle writeData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	if ([self.percentDownloaded integerValue] < 1.0) {
		downloadedLength = contentLength;
		[self dctInternal_calculatePercentDownloaded];
	}
	
	if (fileHandle) {
		[fileHandle closeFile];
	}
	
	[connection cancel];
	connection = nil;
	
	SEL oldRecievedDataSelector = @selector(connectionDidReceiveObject:);
	if ([self respondsToSelector:oldRecievedDataSelector])
		[self performSelector:oldRecievedDataSelector withObject:[[NSData alloc] initWithContentsOfFile:self.downloadPath]];
	
    [self connectionDidFinishLoading];
	[self dctInternal_finished];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.returnedError = error;
	
	[connection cancel];
	connection = nil;
	
	SEL oldRecieveErrorSelector = @selector(connectionDidReceiveError:);
	if ([self respondsToSelector:oldRecieveErrorSelector])
		[self performSelector:oldRecieveErrorSelector withObject:error];
	
    [self connectionDidFailWithError:error];
	[self dctInternal_failed];
}

#pragma mark - NSURLConnectionDownloadDelegate
/*
- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
	downloadedLength = (float)totalBytesWritten;
	contentLength = (float)expectedTotalBytes;
	[self dctInternal_calculatePercentDownloaded];
}

- (void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
	downloadedLength = (float)totalBytesWritten;
	contentLength = (float)expectedTotalBytes;
	[self dctInternal_calculatePercentDownloaded];
}

- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL {
	
	NSLog(@"MainThread: %d", [[NSThread currentThread] isMainThread]);
    NSLog(@"Exists: %d", [[NSFileManager defaultManager] fileExistsAtPath:[destinationURL path]]);
    NSLog(@"Data: %@", [NSData dataWithContentsOfFile:[destinationURL path]]);
    NSLog(@"Path: %@", [destinationURL path]);
	
	NSURL *pathURL = [[NSURL alloc] initFileURLWithPath:self.downloadPath];
	
	NSLog(@"destinationURL: %@", destinationURL);
	NSLog(@"downloadPath URL: %@", pathURL);
	
	
	if ([[NSFileManager defaultManager] isReadableFileAtPath:[destinationURL path]])
		NSLog(@"CAN READ");
	else
		NSLog(@"CANNOT READ");
	
	NSError *error = nil;	
	if (![[NSFileManager defaultManager] moveItemAtPath:[destinationURL path] toPath:self.downloadPath error:&error])
		NSLog(@"NOT MOVED!!!!: %@\n\n", error);
	
	[self connectionDidFinishLoading:connection];
}*/

#pragma mark - Internal methods

- (void)dctInternal_start {
	
	[self URLConnection];
	
	self.status = DCTConnectionControllerStatusStarted;
	
	if (!self.URLConnection) [self dctInternal_failed];
}

- (void)dctInternal_setQueued {
	self.status = DCTConnectionControllerStatusQueued;
}

- (void)dctInternal_responded {
	
	NSURLResponse *response = self.returnedResponse;
	
	for (DCTConnectionControllerResponseBlock block in responseBlocks)
		block(response);
	
	[self dctInternal_sendResponseToDelegate:response];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerDidReceiveResponseNotification object:self];
	
	self.status = DCTConnectionControllerStatusResponded;
}

- (void)dctInternal_finished {
	if (self.ended) return;
	
	id object = self.returnedObject;
	
	for (DCTConnectionControllerFinishBlock block in completionBlocks)
		block();
	
	[self dctInternal_sendObjectToDelegate:object];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerDidFinishNotification object:self];
	
	[self dctInternal_cleanup];
	
	self.status = DCTConnectionControllerStatusFinished;
}

- (void)dctInternal_failed {
	if (self.ended) return;
	
	NSError *error = self.returnedError;
	
	for (DCTConnectionControllerFailureBlock block in failureBlocks)
		block(error);
	
	[self dctInternal_sendErrorToDelegate:error];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerDidFailNotification object:self];

	[self dctInternal_cleanup];
	
	self.status = DCTConnectionControllerStatusFailed;
}

- (void)dctInternal_cancelled {
	if (self.ended) return;
	
	for (DCTConnectionControllerCancelationBlock block in cancelationBlocks)
		block();
	
	[self dctInternal_sendCancelationToDelegate:self.delegate];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionControllerWasCancelledNotification object:self];

	[self dctInternal_cleanup];
	
	self.status = DCTConnectionControllerStatusCancelled;
}

- (void)dctInternal_cleanup {
	 delegate = nil;
	
	for (DCTConnectionController *dependent in self.dctInternal_dependents)
		[dependent removeDependency:self];
	
	dependents = nil;
}

- (void)dctInternal_reset {
	[self.URLConnection cancel];
	URLConnection = nil;
	self.returnedResponse = nil;
	self.returnedError = nil;
	self.returnedObject = nil;
	self.status = DCTConnectionControllerStatusNotStarted;
}

- (void)dctInternal_calculatePercentDownloaded {
	[self dct_changeValueForKey:@"percentDownloaded" withChange:^{
		percentDownloaded = [[NSNumber alloc] initWithFloat:(downloadedLength / contentLength)];
	}];
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

#pragma mark - Internal Getters

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

#pragma mark - Internal Setters

- (void)dctInternal_setURL:(NSURL *)newURL {
	
	if ([newURL isEqual:self.URL]) return;
	
	URL = newURL;
}

- (void)dctInternal_addDependent:(DCTConnectionController *)connectionController {
	
	if (!dependents) dependents = [[NSMutableSet alloc] initWithCapacity:1];
	
	[dependents addObject:connectionController];
}

- (void)dctInternal_removeDependent:(DCTConnectionController *)connectionController {
	[dependents removeObject:connectionController];
}

@end
