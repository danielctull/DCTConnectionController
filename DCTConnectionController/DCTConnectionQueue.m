/*
 DCTConnectionQueue.m
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

#import "DCTConnectionQueue.h"
#import "DCTConnectionController.h"
#import "DCTConnectionController+UsefulChecks.h"
#import "DCTConnectionGroup.h"

NSComparisonResult (^compareConnections)(id obj1, id obj2) = ^(id obj1, id obj2) {
	
	if (![obj1 isKindOfClass:[DCTConnectionController class]] || ![obj2 isKindOfClass:[DCTConnectionController class]]) return (NSComparisonResult)NSOrderedSame;
	
	DCTConnectionController *con1 = (DCTConnectionController *)obj1;
	DCTConnectionController *con2 = (DCTConnectionController *)obj2;
	
	if (con1.priority > con2.priority) return (NSComparisonResult)NSOrderedDescending;
	
	if (con1.priority < con2.priority) return (NSComparisonResult)NSOrderedAscending;
	
	return (NSComparisonResult)NSOrderedSame;
};

NSString *const DCTConnectionQueueConnectionCountChangedNotification = @"DCTConnectionQueueConnectionCountChangedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountChangedNotification = @"DCTConnectionQueueActiveConnectionCountChangedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountIncreasedNotification = @"DCTConnectionQueueActiveConnectionCountIncreasedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountDecreasedNotification = @"DCTConnectionQueueActiveConnectionCountDecreasedNotification";

@implementation DCTConnectionQueue {
	__strong NSMutableArray *_connectionControllers;
}
@synthesize dispatchQueue = _dispatchQueue;

+ (DCTConnectionQueue *)defaultConnectionQueue {
	static DCTConnectionQueue *sharedInstance = nil;
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

- (id)initWithName:(NSString *)name {
	if (!(self = [super init])) return nil;
	_connectionControllers = [NSMutableArray new];
	_maxConnections = 5;
	NSString *queueName = [NSString stringWithFormat:@"uk.co.danieltull.DCTConnectionQueue.%@", name];
	_dispatchQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
	return self;
}

- (id)init {
	return [self initWithName:@"defaultConnectionQueue"];
}

#pragma mark - DCTConnectionQueue

- (NSArray *)connectionControllers {
	dispatch_queue_t callingQueue = dispatch_get_current_queue();
	
	if (callingQueue == _dispatchQueue)
		return [_connectionControllers copy];
	
	__block NSArray *connectionControllers = nil;
	dispatch_sync(_dispatchQueue, ^{
		connectionControllers = [_connectionControllers copy];
	});
	return connectionControllers;
}

- (void)addConnectionController:(DCTConnectionController *)connectionController {
	
	dispatch_async(_dispatchQueue, ^{
		
		__dct_weak DCTConnectionController *weakConnectionController = connectionController;
		__dct_weak DCTConnectionQueue *weakSelf = self;
		
		[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
			if (status <= DCTConnectionControllerStatusResponded) return;
			
			[weakSelf removeConnectionController:weakConnectionController];
			[weakSelf _runNextConnection];
			[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountDecreasedNotification object:self];
		}];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountIncreasedNotification object:self];
		[_connectionControllers addObject:connectionController];
		[self _runNextConnection];
	});
}

- (void)removeConnectionController:(DCTConnectionController *)connectionController {
	dispatch_async(_dispatchQueue, ^{
		[_connectionControllers removeObject:connectionController];
		[self _runNextConnection];
	});
}

#pragma mark - Internals

- (void)_runNextConnection {
	
	[_connectionControllers enumerateObjectsUsingBlock:^(DCTConnectionController *connectionController, NSUInteger i, BOOL *stop) {
		
		if (i+1 >= _maxConnections) {
			*stop = YES;
			return;
		}
		
		if (connectionController.status > DCTConnectionControllerStatusQueued) return;
		
		[connectionController start];		
	}];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; dispatchQueue = \"%s\">",
			NSStringFromClass([self class]),
			self,
			dispatch_queue_get_label(self.dispatchQueue)];
}

@end
