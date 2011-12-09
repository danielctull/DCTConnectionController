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
#import "NSObject+DCTKVOExtras.h"
#import "DCTRESTConnectionController.h"

#if !defined(dctfoundation) || !defined(dctfoundation_2_0_1) || dctfoundation < dctfoundation_2_0_1
#warning "DCTFoundation 2.0.1 is required with this version of DCTConnectionController. Update at https://github.com/danielctull/DCTFoundation"
#endif

NSString * const DCTInternalConnectionControllerStatusString[] = {
	@"NotStarted",
	@"Queued",
	@"Started",
	@"Responded",
	@"Finished",
	@"Failed",
	@"Cancelled"
};

NSString * const DCTInternalConnectionControllerPriorityString[] = {
	@"VeryHigh",
	@"High",
	@"Medium",
	@"Low",
	@"VeryLow"
};

NSString * const DCTInternalConnectionControllerTypeString[] = {
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

@interface DCTConnectionController (DCTConnectionQueue)
- (void)dctConnectionQueue_setQueued;
@end

@interface DCTConnectionController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
- (void)dctInternal_reset;

@property (nonatomic, readwrite) DCTConnectionControllerStatus status;

- (void)dctInternal_connectionDidRespond;
- (void)dctInternal_connectionDidFail;
- (void)dctInternal_connectionDidFinishLoading;
- (void)dctInternal_connectionDidGetCancelled;
- (void)dctInternal_nilURLConnection; //clean up

- (void)dctInternal_calculatePercentDownloaded;

@property (nonatomic, readonly) NSString *dctInternal_downloadPath;

@end


@implementation DCTConnectionController {
	
	__strong NSMutableSet *dependencies;
	__strong NSMutableArray *statusChangeBlocks;
	
	__dct_weak DCTConnectionQueue *queue;
	
	__strong NSFileHandle *fileHandle; // Used if a path is given.
	float contentLength, downloadedLength;
	
	__strong NSString *dctInternal_downloadPath;
}

@synthesize status, type, priority, percentDownloaded;
@synthesize returnedObject, returnedError, returnedResponse;
@synthesize URL, URLRequest, URLConnection;

static NSMutableArray *initBlocks = nil;
static NSMutableArray *deallocBlocks = nil;

+ (void)addInitBlock:(void(^)(DCTConnectionController *))block {
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		initBlocks = [[NSMutableArray alloc] initWithCapacity:1];
	});
	[initBlocks addObject:[block copy]];
}

+ (void)addDeallocBlock:(void(^)(DCTConnectionController *))block {
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		deallocBlocks = [[NSMutableArray alloc] initWithCapacity:1];
	});
	[deallocBlocks addObject:[block copy]];
}

#pragma mark - NSObject

- (void)dealloc {
	
	dct_nil(queue);
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	if ([fileManager fileExistsAtPath:self.dctInternal_downloadPath] && ![fileManager removeItemAtPath:self.dctInternal_downloadPath error:&error])
		NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), error);
	
	for (void(^block)(DCTConnectionController *) in deallocBlocks)
		block(self);
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	priority = DCTConnectionControllerPriorityMedium;
	percentDownloaded = [[NSNumber alloc] initWithInteger:0];
	
	for (void(^block)(DCTConnectionController *) in initBlocks)
		block(self);
	
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
			DCTInternalConnectionControllerStatusString[self.status],
			DCTInternalConnectionControllerPriorityString[self.priority]];
}

#pragma mark - DCTConnectionController: Managing the connection

- (void)connectOnQueue:(DCTConnectionQueue *)theQueue {
	queue = theQueue;
	[queue addConnectionController:self];
}

- (void)requeue {
	[queue removeConnectionController:self];
	[self dctInternal_reset];
	[self connectOnQueue:queue];
}

- (void)cancel {
	[self dctInternal_nilURLConnection];
	[self dctInternal_connectionDidGetCancelled];
}

- (void)start {
	if (self.started || URLConnection) return;
	
	URLConnection = [[NSURLConnection alloc] initWithRequest:self.URLRequest delegate:self];
	
	self.status = DCTConnectionControllerStatusStarted;
	
	if (!URLConnection) {
		// TODO: GENERATE ERROR
		[self connectionDidFail];
	}
}

- (BOOL)shouldStartWithExistingConnectionControllerInQueue:(DCTConnectionController *)existingConnectionController {
	
	if (existingConnectionController.priority > self.priority)
		existingConnectionController.priority = self.priority;
	
	self.status = existingConnectionController.status;
	
	[existingConnectionController addResponseHandler:^(NSURLResponse *response) {
		self.returnedResponse = response;
		[self dctInternal_connectionDidRespond];
	}];
	
	__dct_weak DCTConnectionController *cc = existingConnectionController;
	
	[existingConnectionController addFinishHandler:^() {
		dctInternal_downloadPath = cc.dctInternal_downloadPath;
		
		if ([cc isReturnedObjectLoaded])
			self.returnedObject = cc.returnedObject;
		
		[self dctInternal_connectionDidFinishLoading];
	}];
	
	[existingConnectionController addFailureHandler:^(NSError *error) {
		self.returnedError = error;
		[self dctInternal_connectionDidFail];
	}];
	
	[existingConnectionController addCancelationHandler:^(void) {
		[self dctInternal_connectionDidGetCancelled];
	}];
	
	return NO;
}

#pragma mark - DCTConnectionController: Dependency

- (NSArray *)dependencies {
	return [dependencies allObjects];
}

- (void)addDependency:(DCTConnectionController *)connectionController {
	
	NSAssert(connectionController != nil, @"connectionController is nil");
	
	[dependencies addObject:connectionController];
	
	__weak DCTConnectionController *weakCC = connectionController;
	[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		if (weakCC.ended)
			[self removeDependency:weakCC];
	}];
}

- (void)removeDependency:(DCTConnectionController *)connectionController {
	
	NSAssert(connectionController != nil, @"connectionController is nil");
	
	if (![dependencies containsObject:connectionController]) return;
	
	[dependencies removeObject:connectionController];
}

#pragma mark - DCTConnectionController: Subclass methods

- (void)loadURLRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:self.URL];
	[request setHTTPMethod:DCTInternalConnectionControllerTypeString[self.type]];	
	self.URLRequest = request;
}

- (void)connectionDidFinishLoading {
	[self dctInternal_connectionDidFinishLoading];
}

- (void)connectionDidReceiveResponse {
	[self dctInternal_connectionDidRespond];
}

- (void)connectionDidFail {
	[self dctInternal_connectionDidFail];
}

#pragma mark - DCTConnectionController: Setters

- (void)setStatus:(DCTConnectionControllerStatus)newStatus {
	
	if (newStatus == status) return;
	
	if (self.ended) return; 
	
	[self dct_changeValueForKey:@"status" withChange:^{
		status = newStatus;
	}];
	
	[statusChangeBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
		DCTConnectionControllerStatusBlock block = obj;
		block(newStatus);
	}];
}

- (void)setURLRequest:(NSURLRequest *)newURLRequest {
	
	if (self.started) return;
	
	if ([newURLRequest isEqual:URLRequest]) return;
	
	URLRequest = [newURLRequest copy];
	self.URL = URLRequest.URL;
}

- (void)setURL:(NSURL *)newURL {
	
	if (self.started) return;
	
	URL = newURL;
}

#pragma mark - DCTConnectionController: Getters

- (BOOL)isReturnedObjectLoaded {
	return (returnedObject != nil);
}

- (DCTConnectionQueue *)queue {
	return queue;
}

- (NSURLRequest *)URLRequest {
	
	if (!URLRequest) [self loadURLRequest];
	
	return URLRequest;
}

- (id)returnedObject {
	
	if (!returnedObject) {
		returnedObject = [[NSData alloc] initWithContentsOfFile:self.dctInternal_downloadPath];
	}
	
	return returnedObject;
}

- (NSString *)dctInternal_downloadPath {
	
	if (!dctInternal_downloadPath) {
		NSString *temporaryDirectory = NSTemporaryDirectory();
		temporaryDirectory = [temporaryDirectory stringByAppendingPathComponent:@"DCTConnectionController"];
		
		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:temporaryDirectory
									   withIntermediateDirectories:YES
														attributes:nil
															 error:&error])
			NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), error);
		
		dctInternal_downloadPath = [temporaryDirectory stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	}
	
	return dctInternal_downloadPath;
}

#pragma mark - DCTConnectionController: Block methods

- (void)addStatusChangeHandler:(DCTConnectionControllerStatusBlock)handler {
	
	NSAssert(handler != nil, @"Handler should not be nil.");
	
	if (!statusChangeBlocks) statusChangeBlocks = [[NSMutableArray alloc] initWithCapacity:1];
	
	[statusChangeBlocks addObject:[handler copy]];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
	contentLength = (float)[response expectedContentLength];
	
	self.returnedResponse = response;
    [self connectionDidReceiveResponse];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
		
	if (contentLength > 0) {
		downloadedLength += (float)[data length];
		[self dctInternal_calculatePercentDownloaded];
	}
	
	if (!fileHandle) {
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if ([fileManager fileExistsAtPath:self.dctInternal_downloadPath])
			[fileManager removeItemAtPath:self.dctInternal_downloadPath error:nil];
		
		[fileManager createFileAtPath:self.dctInternal_downloadPath
							 contents:nil
						   attributes:nil];
		
		fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.dctInternal_downloadPath];	
	}
	
	[fileHandle seekToEndOfFile];
	[fileHandle writeData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	if ([self.percentDownloaded integerValue] < 1.0) {
		downloadedLength = contentLength;
		[self dctInternal_calculatePercentDownloaded];
	}
	
	[fileHandle closeFile];
	[self dctInternal_nilURLConnection];
	[self connectionDidFinishLoading];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.returnedError = error;
	[self dctInternal_nilURLConnection];
    [self connectionDidFail];
}

#pragma mark - Internal methods

- (void)dctInternal_connectionDidRespond {
	self.status = DCTConnectionControllerStatusResponded;
}

- (void)dctInternal_connectionDidFinishLoading {
	
	if (self.ended) return;
	
	self.status = DCTConnectionControllerStatusFinished;
}

- (void)dctInternal_connectionDidFail {
	
	if (self.ended) return;
	
	self.status = DCTConnectionControllerStatusFailed;
}

- (void)dctInternal_connectionDidGetCancelled {
	
	if (self.ended) return;
	
	self.status = DCTConnectionControllerStatusCancelled;
}

- (void)dctInternal_nilURLConnection {
	[self.URLConnection cancel];
	URLConnection = nil;
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
	
	if (downloadedLength > contentLength) downloadedLength = contentLength;
	
	[self dct_changeValueForKey:@"percentDownloaded" withChange:^{
		percentDownloaded = [[NSNumber alloc] initWithFloat:(downloadedLength / contentLength)];
	}];
}

@end

@implementation DCTConnectionController (DCTConnectionQueue)

- (void)dctConnectionQueue_setQueued {
	self.status = DCTConnectionControllerStatusQueued;
}

@end
