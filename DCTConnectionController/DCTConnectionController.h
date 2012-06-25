/*
 DCTConnectionController.h
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

#import <Foundation/Foundation.h>

#ifndef dctconnectioncontroller
#define dctconnectioncontroller_1_0     10000
#define dctconnectioncontroller_2_0     20000
#define dctconnectioncontroller_2_0_1   20001
#define dctconnectioncontroller_2_1     20100
#define dctconnectioncontroller_2_2     20200
#define dctconnectioncontroller         dctconnectioncontroller_2_2
#endif

@class DCTConnectionQueue;

/** Specifies the type of connection to use.
 */
typedef enum {
	DCTConnectionControllerTypeGet = 0,		/**< Uses a GET connection. */
	DCTConnectionControllerTypePost,		/**< Uses a POST connection. */
	DCTConnectionControllerTypePut,			/**< Uses a PUT connection. */
	DCTConnectionControllerTypeDelete,		/**< Uses a DELETE connection. */
	DCTConnectionControllerTypeOptions,		/**< Uses a OPTIONS connection. */
	DCTConnectionControllerTypeHead,		/**< Uses a HEAD connection. */
	DCTConnectionControllerTypeTrace,		/**< Uses a TRACE connection. */
	DCTConnectionControllerTypeConnect,
	DCTConnectionControllerTypePatch
} DCTConnectionControllerType;

/** Specifies the different stages of a connection.
 */
typedef enum {
	DCTConnectionControllerStatusNotStarted = 0,	/**< The connection has not begun yet, and has not been given to the DTConnectionManager object to perform. */
	DCTConnectionControllerStatusQueued,			/**< The connection has been placed in a queue and is awaiting a free slot to perform. */
	DCTConnectionControllerStatusStarted,			/**< The request has been sent and a response is being awaited. */
	DCTConnectionControllerStatusResponded,			/**< A response has been received by the server and the connection is awaiting completion. */
	DCTConnectionControllerStatusFinished,			/**< The connection completed without any errors. */
	DCTConnectionControllerStatusFailed,			/**< The connection failed. */
	DCTConnectionControllerStatusCancelled,			/**< The connection was cancelled. */
} DCTConnectionControllerStatus;

/** Specifies the possible priorities for a connection.
 */
typedef enum {
	DCTConnectionControllerPriorityVeryHigh = 0,
	DCTConnectionControllerPriorityHigh,
	DCTConnectionControllerPriorityMedium,
	DCTConnectionControllerPriorityLow,
	DCTConnectionControllerPriorityVeryLow
} DCTConnectionControllerPriority;

/** Name of the notification sent out when the connection has successfully completed.
 */
extern NSString *const DCTConnectionControllerDidFinishNotification;

/** Name of the notification sent out when the connection has failed.
 */
extern NSString *const DCTConnectionControllerDidFailNotification;

/** Name of the notification sent out when the connection has recieved a response.
 */
extern NSString *const DCTConnectionControllerDidReceiveResponseNotification;

extern NSString *const DCTConnectionControllerWasCancelledNotification;

extern NSString *const DCTConnectionControllerStatusChangedNotification;

extern NSString *const DCTConnectionControllerTypeString[];

@interface DCTConnectionController : NSObject <NSCoding,NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, assign) DCTConnectionControllerType type;
@property (nonatomic, assign) DCTConnectionControllerPriority priority;
@property (nonatomic, strong) NSURLRequest *URLRequest;

- (id)initWithURL:(NSURL *)URL;

- (void)performBlock:(void(^)())block;

#pragma mark - Managing the Connection

- (void)connect;
- (void)connectOnQueue:(DCTConnectionQueue *)queue;

#pragma mark - Methods to use in Subclasses

- (void)loadURLRequest;
- (void)connectionDidReceiveResponse;
- (void)connectionDidFinishLoading;
- (void)connectionDidFail;

#pragma mark - Connection Status

@property (nonatomic, strong) id returnedObject;
@property (nonatomic, strong) NSError *returnedError;
@property (nonatomic, readonly) NSURLResponse *returnedResponse;
@property (nonatomic, readonly) NSString *downloadPath;

@property (nonatomic, readonly) DCTConnectionControllerStatus status;
- (void)addStatusChangeHandler:(void(^)(DCTConnectionController *connectionController, DCTConnectionControllerStatus status))handler;

- (NSString *)fullDescription;





/*
@property (nonatomic, strong, readonly) NSNumber *percentDownloaded;
- (void)addPercentDownloadedChangeHandler:(void(^)(NSNumber *percentDownloaded))handler;
*/

@property (nonatomic, readonly) DCTConnectionQueue *connectionQueue;

/// @name For the queue's use only
- (void)start;

@end

#import "DCTConnectionController+BlockHandlers.h"
#import "DCTRESTConnectionController.h"
#import "DCTConnectionQueue.h"
