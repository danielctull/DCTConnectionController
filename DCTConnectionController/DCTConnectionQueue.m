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

NSString *const DCTConnectionQueueConnectionCountChangedNotification = @"DCTConnectionQueueConnectionCountChangedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountChangedNotification = @"DCTConnectionQueueActiveConnectionCountChangedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountIncreasedNotification = @"DCTConnectionQueueActiveConnectionCountIncreasedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountDecreasedNotification = @"DCTConnectionQueueActiveConnectionCountDecreasedNotification";

@implementation DCTConnectionQueue {
	__strong NSMutableArray *_connectionControllers;
}

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
	self.maxConcurrentOperationCount = 5;
	[self setName:[NSString stringWithFormat:@"uk.co.danieltull.DCTConnectionQueue.%@", name]];
	return self;
}

- (id)init {
	return [self initWithName:@"defaultConnectionQueue"];
}

#pragma mark - DCTConnectionQueue

- (NSArray *)connectionControllers {
	return self.operations;
}

- (void)_addOperation:(DCTConnectionController *)connectionController {
	__unsafe_unretained DCTConnectionQueue *weakSelf = self;

	[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {

		if (status <= DCTConnectionControllerStatusResponded) return;

		[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountDecreasedNotification
															object:weakSelf];
	}];

	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountIncreasedNotification object:self];
	[super addOperation:connectionController];
}

- (void)addOperation:(DCTConnectionController *)connectionController {
	[connectionController enqueueOnQueue:self];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; name = \"%@\">",
			NSStringFromClass([self class]),
			self,
			self.name];
}

@end
