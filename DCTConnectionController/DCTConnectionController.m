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
#import "DCTConnectionQueue.h"
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

NSString *const DCTConnectionControllerDidFinishNotification = @"DCTConnectionControllerDidFinishNotification";
NSString *const DCTConnectionControllerDidFailNotification = @"DCTConnectionControllerDidFailNotification";
NSString *const DCTConnectionControllerDidReceiveResponseNotification = @"DCTConnectionControllerDidReceiveResponseNotification";
NSString *const DCTConnectionControllerWasCancelledNotification = @"DCTConnectionControllerWasCancelledNotification";
NSString *const DCTConnectionControllerStatusChangedNotification = @"DCTConnectionControllerStatusChangedNotification";

@implementation DCTConnectionController {
	__weak DCTConnectionQueue *_connectionQueue;
	__strong NSOperationQueue *_operationQueue;
	__strong NSMutableSet *_statusChangeBlocks;
	__strong NSFileHandle *_fileHandle;
	__strong NSFileManager *_fileManager;
	__strong NSURLConnection *_URLConnection;
	__strong NSString *_downloadPath;
	__strong NSURLResponse *_returnedResponse;
	BOOL _isReturnedObjectLoaded;
}

+ (NSString *)path {
	NSString *temporaryDirectory = NSTemporaryDirectory();
	return [temporaryDirectory stringByAppendingPathComponent:@"DCTConnectionController"];
}

+ (void)load {
	@autoreleasepool {
		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:[self path]
									   withIntermediateDirectories:YES
														attributes:nil
															 error:&error])
					NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), [error localizedDescription]);
	}
}

- (void)dealloc {
	[_fileManager removeItemAtPath:self.downloadPath error:nil];
	_fileManager = nil;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)coder {
	if (!(self = [self init])) return nil;
	_type = [coder decodeIntegerForKey:NSStringFromSelector(@selector(type))];
	_priority = [coder decodeIntegerForKey:NSStringFromSelector(@selector(priority))];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInteger:self.type forKey:NSStringFromSelector(@selector(type))];
	[coder encodeInteger:self.priority forKey:NSStringFromSelector(@selector(priority))];
}

- (id)initWithURL:(NSURL *)URL {
	if (!(self = [self init])) return nil;
	NSMutableURLRequest *request = [NSMutableURLRequest new];
	[request setURL:URL];
	[request setHTTPMethod:DCTInternalConnectionControllerTypeString[self.type]];
	_URLRequest = request;
	return self;
}

- (void)performBlock:(void(^)())block {
	[_operationQueue addOperationWithBlock:block];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	_priority = DCTConnectionControllerPriorityMedium;
	_operationQueue = [NSOperationQueue new];
	[_operationQueue setMaxConcurrentOperationCount:1];
	
	[self performBlock:^{
		_statusChangeBlocks = [NSMutableSet new];
		_fileManager = [NSFileManager new];
	}];
		
	[self addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		
			NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
			
			[notificationCenter postNotificationName:DCTConnectionControllerStatusChangedNotification object:connectionController];
			
			switch (status) {
				case DCTConnectionControllerStatusResponded:
					[notificationCenter postNotificationName:DCTConnectionControllerDidReceiveResponseNotification object:connectionController];
					break;
					
				case DCTConnectionControllerStatusCancelled:
					[notificationCenter postNotificationName:DCTConnectionControllerWasCancelledNotification object:connectionController];
					break;
					
				case DCTConnectionControllerStatusFinished:
					[notificationCenter postNotificationName:DCTConnectionControllerDidFinishNotification object:connectionController];
					break;
					
				case DCTConnectionControllerStatusFailed:
					[notificationCenter postNotificationName:DCTConnectionControllerDidFailNotification object:connectionController];
					break;
					
				default:
					break;
			}
		}];
	}];
	
    return self;
}

- (void)connect {
	[self connectOnQueue:[DCTConnectionQueue defaultConnectionQueue]];
}

- (void)connectOnQueue:(DCTConnectionQueue *)connectionQueue {
	
	if (self.status > DCTConnectionControllerStatusNotStarted) return;
	
	_connectionQueue = connectionQueue;
	
	[self performBlock:^{
					
		NSUInteger existingConnectionControllerIndex = [_connectionQueue.connectionControllers indexOfObject:self];
		
		if (existingConnectionControllerIndex == NSNotFound) {
			[_connectionQueue addConnectionController:self];
			[self setStatus:DCTConnectionControllerStatusQueued];
			return;
		}
		
		DCTConnectionController *existingConnectionController = [_connectionQueue.connectionControllers objectAtIndex:existingConnectionControllerIndex];
		
		// If it's the exact same object, lets not add it again. This could happen if -connectOnQueue: is called more than once.
		if (existingConnectionController == self) return;
				
		// Not sure why it's this way around.
		if (existingConnectionController.priority > self.priority)
			existingConnectionController.priority = self.priority;
		
		self.status = existingConnectionController.status;
		
		[existingConnectionController addStatusChangeHandler:^(DCTConnectionController *connectionController, DCTConnectionControllerStatus status) {
						
			switch (status) {
					
				case DCTConnectionControllerStatusResponded:
					_returnedResponse = connectionController.returnedResponse;
					break;
					
				case DCTConnectionControllerStatusFinished:
					_downloadPath = connectionController.downloadPath;
					if (connectionController->_isReturnedObjectLoaded)
						_returnedObject = connectionController.returnedObject;
					break;
					
				case DCTConnectionControllerStatusFailed:
					_returnedError = connectionController.returnedError;
					break;
					
				default:
					break;
			}
			
			[self setStatus:status];
		}];
	}];
}

- (void)start {
	
	if (self.status >= DCTConnectionControllerStatusStarted) return;
	[self setStatus:DCTConnectionControllerStatusStarted];
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			
		_URLConnection = [[NSURLConnection alloc] initWithRequest:self.URLRequest delegate:self startImmediately:YES];
		
		if (!_URLConnection)
			[self performBlock:^{
				// TODO: GENERATE ERROR
				[self connectionDidFail];
			}];
	}];
}

- (NSURLRequest *)URLRequest {
	
	if (!_URLRequest) [self loadURLRequest];
	
	return _URLRequest;
}

#pragma mark - Subclass Methods

- (void)loadURLRequest {
	NSMutableURLRequest *request = [NSMutableURLRequest new];
	[request setHTTPMethod:DCTInternalConnectionControllerTypeString[self.type]];	
	self.URLRequest = request;
}

- (void)connectionDidFinishLoading {
	[self setStatus:DCTConnectionControllerStatusFinished];
}

- (void)connectionDidReceiveResponse {
	[self setStatus:DCTConnectionControllerStatusResponded];
}

- (void)connectionDidFail {
	[self setStatus:DCTConnectionControllerStatusFailed];
}

- (id)returnedObject {
	
	if (!_returnedObject) {
		_returnedObject = [[NSData alloc] initWithContentsOfFile:self.downloadPath];
		_isReturnedObjectLoaded = YES;
	}
	return _returnedObject;
}

- (NSString *)downloadPath {
	
	if (!_downloadPath)
		_downloadPath = [[[self class] path] stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	
	return _downloadPath;
}

- (NSURLResponse *)returnedResponse {
	return _returnedResponse;
}

- (void)setStatus:(DCTConnectionControllerStatus)status {

	[self performBlock:^{
		if (status <= _status
			&& status != DCTConnectionControllerStatusNotStarted
			&& status != DCTConnectionControllerStatusQueued)
			return;
		
		if (self.ended) return;
		
		[self willChangeValueForKey:@"status"];
		_status = status;
		[self didChangeValueForKey:@"status"];

		[_statusChangeBlocks enumerateObjectsUsingBlock:^(void(^block)(DCTConnectionController *connectionController, DCTConnectionControllerStatus), BOOL *stop) {
			block(self, _status);
		}];
	}];
}

- (void)addStatusChangeHandler:(void(^)(DCTConnectionController *connectionController, DCTConnectionControllerStatus status))handler {
	NSAssert(handler != NULL, @"Handler is NULL.");
	[self performBlock:^{
		[_statusChangeBlocks addObject:handler];
	}];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[self performBlock:^{
		_returnedResponse = response;
		[self connectionDidReceiveResponse];
	}];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	
	[self performBlock:^{
				
		if (!_fileHandle) {
			
			NSString *downloadPath = self.downloadPath;
			
			if ([_fileManager fileExistsAtPath:downloadPath])
				[_fileManager removeItemAtPath:downloadPath error:nil];
			
			[_fileManager createFileAtPath:downloadPath
								  contents:nil
								attributes:nil];
						
			_fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:downloadPath];
		}
		
		[_fileHandle seekToEndOfFile];
		[_fileHandle writeData:data];
	}];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	[self performBlock:^{
		[_fileHandle closeFile];
		_fileHandle = nil;
		
		[self connectionDidFinishLoading];
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[_URLConnection cancel];
			_URLConnection = nil;
		}];
	}];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self performBlock:^{
		[_fileHandle closeFile];
		_fileHandle = nil;
		_returnedError = error;
		
		[self connectionDidFail];
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[_URLConnection cancel];
			_URLConnection = nil;
		}];
	}];
}

#pragma mark - Internal

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
	
	return [NSString stringWithFormat:@"\n<%@: %p;\n    URL = \"%@\";\n    type = %@;%@%@\n    status = %@;\n    priority = %@\n>", 
			NSStringFromClass([self class]),
			self,
			self.URLRequest.URL,
			DCTInternalConnectionControllerTypeString[self.type],
			headersString,
			bodyString,
			DCTInternalConnectionControllerStatusString[self.status],
			DCTInternalConnectionControllerPriorityString[self.priority]];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; URL = \"%@\"; type = %@; status = %@; priority = %@>", 
			NSStringFromClass([self class]),
			self,
			self.URLRequest.URL,
			DCTInternalConnectionControllerTypeString[self.type],
			DCTInternalConnectionControllerStatusString[self.status],
			DCTInternalConnectionControllerPriorityString[self.priority]];
}

- (BOOL)isEqual:(id)object {
	return [self isEqualToConnectionController:object];
}

- (NSString *)_domainStringFromURL:(NSURL *)URL {
	NSString *urlString = [URL absoluteString];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"www." withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".com/" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".co.uk/" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".com" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".co.uk" withString:@""];
	return urlString;
	
}

@end
