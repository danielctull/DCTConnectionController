/*
 DCTConnectionController+Delegate.m
 DCTConnectionController
 
 Created by Daniel Tull on 22.11.2011.
 
 
 
 Copyright (c) 2011 Daniel Tull. All rights reserved.
 
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

#import "DCTConnectionController+Delegate.h"
#import <objc/runtime.h>

@interface DCTConnectionController ()
- (void)dctInternal_setupBlockCallbacks;
@end

@implementation DCTConnectionController (Delegate)

- (void)setDelegate:(id<DCTConnectionControllerDelegate>)delegate {
	[self dctInternal_setupBlockCallbacks];
	objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<DCTConnectionControllerDelegate>)delegate {
	return objc_getAssociatedObject(self, _cmd);
}

- (void)dctInternal_setupBlockCallbacks {
	
	if (objc_getAssociatedObject(self, _cmd))
		return;
	
	objc_setAssociatedObject(self, _cmd, @"hasSetupDelegateBlocks", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	__dct_weak DCTConnectionController *weakself = self;
	
	[self addResponseHandler:^(NSURLResponse *response) {
		if ([weakself.delegate respondsToSelector:@selector(connectionController:didReceiveResponse:)])
			[weakself.delegate connectionController:weakself didReceiveResponse:response];
	}];
	
	[self addCancelationHandler:^{
		if ([weakself.delegate respondsToSelector:@selector(connectionControllerWasCancelled:)])
			[weakself.delegate connectionControllerWasCancelled:weakself];
	}];
	
	[self addFinishHandler:^{
		if ([weakself.delegate respondsToSelector:@selector(connectionControllerDidFinish:)])
			[weakself.delegate connectionControllerDidFinish:weakself];
		
		if ([weakself.delegate respondsToSelector:@selector(connectionController:didReceiveObject:)])
			[weakself.delegate connectionController:weakself didReceiveObject:weakself.returnedObject];
	}];
	
	[self addFailureHandler:^(NSError *error) {
		if ([weakself.delegate respondsToSelector:@selector(connectionController:didReceiveError:)])
			[weakself.delegate connectionController:weakself didReceiveError:error];
	}];
}

@end
