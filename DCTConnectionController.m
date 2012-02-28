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
#import "DCTRESTConnectionController.h"

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

typedef void (^DCTConnectionControllerStatusBlock) (DCTConnectionControllerStatus status);
typedef void (^DCTConnectionControllerPercentBlock) (NSNumber *percentDownloaded);

@interface DCTConnectionController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
- (void)dctInternal_reset;

@property (nonatomic, readwrite) DCTConnectionControllerStatus status;
@property (nonatomic, readonly) NSString *dctInternal_downloadPath;

- (void)dctInternal_nilURLConnection;
- (void)dctInternal_calculatePercentDownloaded;
@end

@implementation DCTConnectionController {
	__strong NSString *dctInternal_downloadPath;
	__strong NSMutableSet *dependencies;
	__strong NSMutableArray *statusChangeBlocks;
	__strong NSMutableArray *percentChangeBlocks;
	__strong NSFileHandle *fileHandle;
	float contentLength;
	float downloadedLength;
}

@synthesize queue;
@synthesize status;
@synthesize type;
@synthesize priority;
@synthesize percentDownloaded;
@synthesize returnedObject;
@synthesize returnedError;
@synthesize returnedResponse;
@synthesize URL;
@synthesize URLRequest;
@synthesize URLConnection;

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


- (NSString *)fullDescription {
	
	NSDictionary *headers = self.URLRequest.allHTTPHeaderFields;
	__block NSString *headersString = @"";
	if ([headers count] > 0) {
		headersString = @"\n    headers = ";
		
		[headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			headersString = [headersString stringByAppendingFormat:@"\n        %@ = %@", key, obj];
		}];
	}
	
	NSString *bodyString = @"";
	if (self.type == DCTConnectionControllerTypePost) {
		NSString *body = [[NSString alloc] initWithData:self.URLRequest.HTTPBody encoding:NSUTF8StringEncoding];
		if ([body length] > 0)
			bodyString = [NSString stringWithFormat:@"\n    body = \n        %@", body];
	}
	
	return [NSString stringWithFormat:@"\n<%@: %p;\n    url = \"%@\";\n    type = %@;%@%@\n    status = %@;\n    priority = %@\n>", 
			NSStringFromClass([self class]),
			self,
			self.URL,
			DCTInternalConnectionControllerTypeString[self.type],
			headersString,
			bodyString,
			DCTInternalConnectionControllerStatusString[self.status],
			DCTInternalConnectionControllerPriorityString[self.priority]];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; url = \"%@\"; type = %@; status = %@; priority = %@>", 
			NSStringFromClass([self class]),
			self,
			self.URL,
			DCTInternalConnectionControllerTypeString[self.type],
			DCTInternalConnectionControllerStatusString[self.status],
			DCTInternalConnectionControllerPriorityString[self.priority]];
}

#pragma mark - DCTConnectionController: Managing the connection

- (void)connectOnQueue:(DCTConnectionQueue *)theQueue {
	
	queue = theQueue;
	
	NSUInteger existingConnectionControllerIndex = [queue.connectionControllers indexOfObject:self];
	
	if (existingConnectionControllerIndex == NSNotFound) {
		[queue addConnectionController:self];
		self.status = DCTConnectionControllerStatusQueued;
		return;	
	}
	
	DCTConnectionController *existingConnectionController = [queue.connectionControllers objectAtIndex:existingConnectionControllerIndex];
		
	// If it's the exact same object, lets not add it again. This could happen if -connectOnQueue: is called more than once.
	if (existingConnectionController == self) return;
	
	// Not sure why it's this way around.
	if (existingConnectionController.priority > self.priority)
		existingConnectionController.priority = self.priority;
	
	self.status = existingConnectionController.status;
	
	__dct_weak DCTConnectionController *weakCC = existingConnectionController;
	[existingConnectionController addStatusChangeHandler:^(DCTConnectionControllerStatus existingConnectionControllerStatus) {
		
		switch (existingConnectionControllerStatus) {
				
			case DCTConnectionControllerStatusResponded:
				self.returnedResponse = weakCC.returnedResponse;
				break;
				
			case DCTConnectionControllerStatusFinished:
				dctInternal_downloadPath = weakCC.dctInternal_downloadPath;
				if ([weakCC isReturnedObjectLoaded]) 
					self.returnedObject = weakCC.returnedObject;
				break;
				
			case DCTConnectionControllerStatusFailed:
				self.returnedError = weakCC.returnedError;
				break;
				
			default:
				break;
		}
		
		self.status = existingConnectionControllerStatus;
	}];
}

- (void)requeue {
	[queue removeConnectionController:self];
	[self dctInternal_reset];
	[self connectOnQueue:queue];
}

- (void)cancel {
	[self dctInternal_nilURLConnection];
	self.status = DCTConnectionControllerStatusCancelled;
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
	self.status = DCTConnectionControllerStatusFinished;
}

- (void)connectionDidReceiveResponse {
	self.status = DCTConnectionControllerStatusResponded;
}

- (void)connectionDidFail {
	self.status = DCTConnectionControllerStatusFailed;
}

#pragma mark - DCTConnectionController: Setters

- (void)setURLRequest:(NSURLRequest *)newURLRequest {
	
	if (self.started) return;
	
	if (newURLRequest == URLRequest) return; // If you use isEqual: it will match for a similar set of parameters
	
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

- (NSURLRequest *)URLRequest {
	
	if (!URLRequest) [self loadURLRequest];
	
	return URLRequest;
}

- (id)returnedObject {
	
	if (!returnedObject)
		returnedObject = [[NSData alloc] initWithContentsOfFile:self.dctInternal_downloadPath];
	
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

#pragma mark - DCTConnectionController: Status

- (void)setStatus:(DCTConnectionControllerStatus)newStatus {
	
	if (newStatus <= status
		&& newStatus != DCTConnectionControllerStatusNotStarted
		&& newStatus != DCTConnectionControllerStatusQueued)
		return;
	
	if (self.ended) return;
	
	[self willChangeValueForKey:@"status"];
	status = newStatus;
	[self didChangeValueForKey:@"status"];
	
	for (DCTConnectionControllerStatusBlock block in statusChangeBlocks)
		block(newStatus);
}

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
	
	[self willChangeValueForKey:@"percentDownloaded"];
	percentDownloaded = [[NSNumber alloc] initWithFloat:(downloadedLength / contentLength)];
	[self didChangeValueForKey:@"percentDownloaded"];
	
	for (DCTConnectionControllerPercentBlock block in percentChangeBlocks)
		block(percentDownloaded);
}

- (void)addPercentDownloadedChangeHandler:(DCTConnectionControllerPercentBlock)handler {
	NSAssert(handler != nil, @"Handler should not be nil.");
	
	if (!percentChangeBlocks) percentChangeBlocks = [[NSMutableArray alloc] initWithCapacity:1];
	
	[percentChangeBlocks addObject:[handler copy]];
}

@end
