/*
 DCTConnectionGroup.h
 DCTConnectionController
 
 Created by Daniel Tull on 18.11.2011.
 
 
 
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

#import <Foundation/Foundation.h>
#import "DCTConnectionController.h"
#import "DCTConnectionQueue.h"

typedef void (^DCTConnectionGroupCompletionBlock) (NSArray *finishedConnectionControllers, NSArray *failedConnectionControllers, NSArray *cancelledConnectionControllers);

/** A class to group together come connection controllers and be notified when they have all ended, through success, failure or cancellation.
 
 The following is an example of how you would set it up with two connection controllers:
 
	DCTConnectionGroup *group = [DCTConnectionGroup new];
 
	DCTConnectionController *cc1 = [DCTConnectionController new];
	// Setup cc1
	[group addConnectionController:cc1];
 
	DCTConnectionController *cc2 = [DCTConnectionController new];
	// Setup cc2
	[group addConnectionController:cc2];
 
 
	[group addCompletionHandler:^(NSArray *finishedCCs, NSArray *failedCCs, NSArray *cancelledCCs) {
 
		if ([failedCCs count] == 0 && [cancelledCCs count] == 0)
			// handle success
		
		else if ([failedCCs count] == 0)
			// handle cancellations
		
		else
			// handle failure
	}];
 
	[group connect];
 
 */
@interface DCTConnectionGroup : NSObject

/** The connection controllers in the group.
 */
@property (nonatomic, readonly) NSArray *connectionControllers;

/** Adds a connection controller to the group.
 
 @param connectionController The connection controller to add.
 */
- (void)addConnectionController:(DCTConnectionController *)connectionController;

/** Adds a completion handler to the group.
 
 Blocks added are run when all of the connections have ended, through success, failure or cancellation.
 
 DCTConnectionGroupCompletionBlock is defined as the following:
 
	typedef void (^DCTConnectionGroupCompletionBlock) (NSArray *finishedCCs, NSArray *failedCCs, NSArray *cancelledCCs);
 
 It gives you three arrays, once for the connection controllers that have 
 successfully finished, one for failures and one for those which have been cancelled.
 
 @param completionBlock A block to run when all the connection controllers have ended.
 */
- (void)addCompletionHandler:(DCTConnectionGroupCompletionBlock)completionBlock;

/** Adds this group to a queue.
 
 The queue will call [connectOnQueue:]([DCTConnectionController connectOnQueue:]) on 
 all the connection controllers within this group.
 
 @param queue The queue on which to add the group (and the connection controllers).
 */
- (void)connectOnQueue:(DCTConnectionQueue *)queue;

@end





@interface DCTConnectionQueue (DCTConnectionGroup)
@property (nonatomic, readonly) NSArray *connectionGroups;
@end

