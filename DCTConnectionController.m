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
	dispatch_queue_t _dispatchQueue;
	__strong NSMutableSet *_statusChangeBlocks;
	__strong NSFileHandle *_fileHandle;
	__strong NSURLConnection *_URLConnection;
	BOOL _isReturnedObjectLoaded;
}

@synthesize returnedObject = _returnedObject;
@synthesize returnedError = _returnedError;
@synthesize returnedResponse = _returnedResponse;
@synthesize downloadPath = _downloadPath;

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
	dispatch_async(_dispatchQueue, block);
}

- (NSString *)downloadPath {
	
	if (!_downloadPath) {
		NSString *temporaryDirectory = NSTemporaryDirectory();
		temporaryDirectory = [temporaryDirectory stringByAppendingPathComponent:@"DCTConnectionController"];
		
		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:temporaryDirectory
									   withIntermediateDirectories:YES
														attributes:nil
															 error:&error])
			NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), error);
		
		_downloadPath = [temporaryDirectory stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	}
	
	return _downloadPath;
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	_priority = DCTConnectionControllerPriorityMedium;
	_statusChangeBlocks = [NSMutableSet new];
	
	__dct_weak DCTConnectionController *weakSelf = self;
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[self addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		
		[notificationCenter postNotificationName:DCTConnectionControllerStatusChangedNotification object:weakSelf];
		
		switch (status) {
			case DCTConnectionControllerStatusResponded:
				[notificationCenter postNotificationName:DCTConnectionControllerDidReceiveResponseNotification object:weakSelf];
				break;
				
			case DCTConnectionControllerStatusCancelled:
				[notificationCenter postNotificationName:DCTConnectionControllerWasCancelledNotification object:weakSelf];
				break;
				
			case DCTConnectionControllerStatusFinished:
				[notificationCenter postNotificationName:DCTConnectionControllerDidFinishNotification object:weakSelf];
				break;
				
			case DCTConnectionControllerStatusFailed:
				[notificationCenter postNotificationName:DCTConnectionControllerDidFailNotification object:weakSelf];
				break;
				
			default:
				break;
		}
	}];
	
    return self;
}

- (void)connect {
	[self connectOnQueue:[DCTConnectionQueue defaultConnectionQueue]];
}

- (void)connectOnQueue:(DCTConnectionQueue *)connectionQueue {
	
	if (self.status > DCTConnectionControllerStatusNotStarted) return;
	
	_connectionQueue = connectionQueue;
	_dispatchQueue = _connectionQueue.dispatchQueue;
	
	dispatch_async(_dispatchQueue, ^{
				
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
		
		__dct_weak DCTConnectionController *weakExistingConnectionController = existingConnectionController;
		[existingConnectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
			
			__strong DCTConnectionController *strongExistingConnectionController = weakExistingConnectionController;
			
			switch (status) {
					
				case DCTConnectionControllerStatusResponded:
					_returnedResponse = weakExistingConnectionController.returnedResponse;
					break;
					
				case DCTConnectionControllerStatusFinished:
					_downloadPath = weakExistingConnectionController.downloadPath;
					if (strongExistingConnectionController->_isReturnedObjectLoaded)
						_returnedObject = weakExistingConnectionController.returnedObject;
					break;
					
				case DCTConnectionControllerStatusFailed:
					_returnedError = weakExistingConnectionController.returnedError;
					break;
					
				default:
					break;
			}
			
			[self setStatus:status];
		}];
	});
}

- (void)start {
	
	if (self.status >= DCTConnectionControllerStatusStarted) return;
	self.status = DCTConnectionControllerStatusStarted;
	
	dispatch_async(dispatch_get_main_queue(), ^{
				
		_URLConnection = [[NSURLConnection alloc] initWithRequest:self.URLRequest delegate:self startImmediately:YES];
		
		if (!_URLConnection)
			dispatch_async(_dispatchQueue, ^{
				// TODO: GENERATE ERROR
				[self connectionDidFail];
			});
	});
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

- (void)setStatus:(DCTConnectionControllerStatus)status {
	
	if (status <= _status
		&& status != DCTConnectionControllerStatusNotStarted
		&& status != DCTConnectionControllerStatusQueued)
		return;
	
	if (self.ended) return;
	
	[self willChangeValueForKey:@"status"];
	_status = status;
	[self didChangeValueForKey:@"status"];
	
	[_statusChangeBlocks enumerateObjectsUsingBlock:^(void(^block)(DCTConnectionControllerStatus), BOOL *stop) {
		block(_status);
	}];
}

- (void)addStatusChangeHandler:(void(^)(DCTConnectionControllerStatus status))handler {
	NSAssert(handler != NULL, @"Handler is NULL.");
	[_statusChangeBlocks addObject:^(DCTConnectionControllerStatus status) {
		handler(status);
	}];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	dispatch_async(_dispatchQueue, ^{
		_returnedResponse = response;
		[self connectionDidReceiveResponse];
	});
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	
	dispatch_async(_dispatchQueue, ^{
		
		if (!_fileHandle) {
			
			NSString *downloadPath = self.downloadPath;
			
			NSFileManager *fileManager = [NSFileManager new];
			
			if ([fileManager fileExistsAtPath:downloadPath])
				[fileManager removeItemAtPath:downloadPath error:nil];
			
			[fileManager createFileAtPath:downloadPath
								 contents:nil
							   attributes:nil];
			
			_fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:downloadPath];
		}
		
		[_fileHandle seekToEndOfFile];
		[_fileHandle writeData:data];
	});
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	dispatch_async(_dispatchQueue, ^{
		
		[_fileHandle closeFile];
		_fileHandle = nil;
		dispatch_async(dispatch_get_main_queue(), ^{
			[_URLConnection cancel];
			_URLConnection = nil;
		});
		[self connectionDidFinishLoading];
		NSFileManager *fileManager = [NSFileManager new];
		[fileManager removeItemAtPath:self.downloadPath error:nil];
	});
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	dispatch_async(_dispatchQueue, ^{
		[_fileHandle closeFile];
		_fileHandle = nil;
		_returnedError = error;
		dispatch_async(dispatch_get_main_queue(), ^{
			[_URLConnection cancel];
			_URLConnection = nil;
		});
		[self connectionDidFail];
		NSFileManager *fileManager = [NSFileManager new];
		[fileManager removeItemAtPath:self.downloadPath error:nil];
	});
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

@end
