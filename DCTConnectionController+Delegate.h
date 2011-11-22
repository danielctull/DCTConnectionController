/*
 DCTConnectionController+Delegate.h
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

#import "DCTConnectionController.h"

@protocol DCTConnectionControllerDelegate;

@interface DCTConnectionController (Delegate)

/** The delegate for the connection controller.
 
 Setting this will cause the connection controller to call the methods defined in DCTConnectionControllerDelegate,
 when the appropriate events occur.
 */
@property (nonatomic, strong) id<DCTConnectionControllerDelegate> delegate;

@end

#pragma mark

/** Protocol for delegates of DCTConnectionController to conform to.
 
 The delegate of DCTConnectionController must adopt the DCTConnectionControllerDelegate protocol, although all the methods 
 are optional. They allow the delegate to handle only certain types of events, although connectionController:didSucceedWithObject: 
 and connectionController:didFailWithError: should both be handled to take advantage of the data and handle any occuring errors.
 */
@protocol DCTConnectionControllerDelegate <NSObject>
@optional

/** Tells the delegate the connection has succeeded.
 
 @param connectionController The connection controller informing the delegate of the event.
 */
- (void)connectionControllerDidFinish:(DCTConnectionController *)connectionController;

/** Tells the delegate the connection has succeeded.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param object The object returned by the connection.
 
 @deprecated Use connectionControllerDidFinish: instead.
 
 @see connectionControllerDidFinish: 
 */
- (void)connectionController:(DCTConnectionController *)connectionController didReceiveObject:(NSObject *)object;
/** Tells the delegate the connection has failed.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param error The error received from the server.
 */
- (void)connectionController:(DCTConnectionController *)connectionController didReceiveError:(NSError *)error;

/** Tells the delegate the connection was cancelled.
 
 @param connectionController The connection controller informing the delegate of the event.
 */
- (void)connectionControllerWasCancelled:(DCTConnectionController *)connectionController;

/** Tells the delegate a response has been received from the server.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param response The received response.
 */
- (void)connectionController:(DCTConnectionController *)connectionController didReceiveResponse:(NSURLResponse *)response;
@end
