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

#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_4_3
	#warning "This library uses ARC which is only available in iOS SDK 4.3 and later."
#endif

#if !defined dct_weak && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0
	#define dct_weak weak
	#define __dct_weak __weak
	#define dct_nil(x)
#elif !defined dct_weak && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_3
	#define dct_weak unsafe_unretained
	#define __dct_weak __unsafe_unretained
	#define dct_nil(x) x = nil
#endif

#import <Foundation/Foundation.h>

#ifndef dctconnectioncontroller
#define dctconnectioncontroller_1_0     10000
#define dctconnectioncontroller_2_0     20000
#define dctconnectioncontroller_2_0_1   20001
#define dctconnectioncontroller_2_1     20100
#define dctconnectioncontroller         dctconnectioncontroller_2_1
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
} DCTConnectionType;

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

typedef void (^DCTConnectionControllerResponseBlock) (NSURLResponse *response);
typedef void (^DCTConnectionControllerFailureBlock) (NSError *error);
typedef void (^DCTConnectionControllerCancelationBlock) ();
typedef void (^DCTConnectionControllerCompletionBlock) (id returnedObject);
typedef void (^DCTConnectionControllerStatusBlock) (DCTConnectionControllerStatus status);

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

@protocol DCTConnectionControllerDelegate;



/** A class to handle one connection.
 
 This class is an abstract class, which should always be subclassed in order to work.
 Included is a simple subclass, DCTURLConnectionController, which loads the given URL.
 
 Benefits to using a connection controller over using an NSURLConnection directly include:
 
 * Easy ability to split up funtionality.
 
 * Setting up connections in a queue.
 
 * Adding dependencies, so that connections only start once all dependencies are complete,
 useful for when a connection is dependent on a login connection for example.
 
 * Queueing duplicate connection controllers to one already queued or active, will 
 cause the duplicates to "piggy back" the existing connection controller. This way the application
 could need fewer connections without having to check each time you make the connection.
 
 * Automatic benefits when DCTConnectionController is improved!
 
 Most of the time when working with connection controllers, you will want to have a separate 
 controller for different calls. You may have one for fetching all tweets and another for fetching
 tweets from a particular user. The benefits here are that in the different implmenetations 
 you know that one class does just the one task, meaning a lot less conditional statements.
 
 It also allows you to build clever class hierarchies, for instance you may want to have another
 abstract class used for all Twitter calls (for example TwitterConnectionController), where if it
 fails due to an authentication issue, it starts a login connection controller, requeues itself and 
 adds the login controller to its dependencies. All connection controllers inheriting from
 TwitterConnectionController would then gain the ability to authenticate when they receive an
 authentication challenge.
 
 Many web services respond succesfully with error codes for the API in the returned data. Because 
 a connection controller represents the higher level web service more than the actual connection, 
 these failures should be reported as such. To achieve this, the subclass implementation of 
 `receivedObject:` should look for error codes and if one is found, call `receivedError:` with an NSError
 created from the data from the web service. This allows delegates to be informed correctly, the 
 correct blocks to be called and the correct `status` to be set. Again, with the right class
 hierarchy, this will likely only have to be done once.
 
 *General Usage*
 
 An example of how you may use a connection controller:

	DCTConnectionController *cc = [DCTConnectionController connectionController];
	
	cc.delegate = self;
	cc.priority = DCTConnectionControllerPriorityHigh;
	
	[cc addCompletionBlock:^(NSObject *o) {
		NSLog(@"Connection Controller: %@ returned object: %@", cc, o);
	}];
	
	[cc connect]; 
 
 *Connection Controller Piggy Backing*
 
 Connection Controllers have a built in proceedure for piggy backing onto other connection controllers
 that are fetching the same data. To achieve this, when a connection controller is asked to `connect`, it 
 will check with the `DCTConnectionQueue` to see if a connection controller exists that is equal to iself.
 By default two connection controllers are equal if they are of the same class, are connecting to the same `URL`, 
 have the same `type` and have the same properties; In this way, for the majority of subclasses this will remain
 true as `isEqualToConnectionController:` checks properties defined in all classes.

 For this reason it is a good idea for subclasses to define their parameters as properties, that way each will get
 checked for equality by `isEqualToConnectionController:`. In the future the implementation of
 `isEqualToConnectionController:` may change to one a little more concrete, but so far this has worked well for me. 
 */
@interface DCTConnectionController : NSObject

#pragma mark - Setting up the connection details

/// @name Setting up the connection details

/** Sets the connection as multitask enabled for the iOS platform.
 */
@property (nonatomic, assign) BOOL multitaskEnabled;

/** The type of connection to use.
 
 Specifies the type of connection to use. Types include:
 
 * `DCTConnectionControllerTypeGet` for GET requests
 * `DCTConnectionControllerTypePost` for POST requests
 * `DCTConnectionControllerTypePut` for PUT requests
 * `DCTConnectionControllerTypeDelete` for DELETE requests
 * `DCTConnectionControllerTypeOptions` for OPTIONS requests
 * `DCTConnectionControllerTypeHead` for HEAD requests
 * `DCTConnectionControllerTypeTrace` for TRACE requests
 * `DCTConnectionControllerTypeConnect` for CONNECT requests
 
 */
@property (nonatomic, assign) DCTConnectionType type;


/** The priority of the connection controller.
 
 Connection controllers will be sorted in order of their priority and as such high priority connections will be 
 handled first. If two connections are in the queue with equal priorities, then they will be started in the order 
 they were added to the conneciton queue. Generally it's a good idea to use the highest priority free for login
 connections and lowest priority for connections the user didn't directly initiate.
 
 Priorities include:
 
 * `DCTConnectionControllerPriorityVeryHigh`
 * `DCTConnectionControllerPriorityHigh`
 * `DCTConnectionControllerPriorityMedium`
 * `DCTConnectionControllerPriorityLow`
 * `DCTConnectionControllerPriorityVeryLow`
 
 */
@property (nonatomic, assign) DCTConnectionControllerPriority priority;



/** The delegate for the connection controller.
 
 Setting this will cause the connection controller to call the methods defined in DCTConnectionControllerDelegate,
 when the appropriate events occur.
 */
@property (nonatomic, strong) id<DCTConnectionControllerDelegate> delegate;

/** The URL the connection controller is managing.
 */
@property (nonatomic, strong) NSURL *URL;

/** The URLRequest the connection controller is managing.
 */
@property (nonatomic, strong) NSURLRequest *URLRequest;


#pragma mark - Dependencies

/// @name Dependencies

/** The dependencies for this connection controller.
 */
@property (nonatomic, readonly) NSArray *dependencies;


/** Adds a connection controller that needs to finish before the receiver can start.
 
 Currently, the depended connection controller just needs to be removed from the queue before the receiver starts, 
 whether the depended connection controller finishes with success or failure. This will be looked into for future 
 versions.
 
 @param connectionController The connection controller that should be complete before the receiver starts.
 */
- (void)addDependency:(DCTConnectionController *)connectionController;


/** Removes the given connection controller from the list of depended connection controllers.
 
 If the given connection controller is not in the list of dependencies, this is a no-op.
 
 @param connectionController The connection controller to be removed from the dependency list.
 */
- (void)removeDependency:(DCTConnectionController *)connectionController;



#pragma mark - Event Blocks

/// @name Event Blocks

/** Adds a response block.
 
 DCTConnectionControllerResponseBlock is defined as such:
 
 `typedef void (^DCTConnectionControllerResponseBlock) (NSURLResponse *response);`
 
 @param responseHandler The response block to add.
 */
- (void)addResponseHandler:(DCTConnectionControllerResponseBlock)responseHandler;

/** Adds a completion block.
 
 DCTConnectionControllerCompletionBlock is defined as such:
 
 `typedef void (^DCTConnectionControllerCompletionBlock) (id object);`
 
 Where the object is the returnedObject of the reciever.
 
 @param completionHandler The completion block to add.
 */
- (void)addCompletionHandler:(DCTConnectionControllerCompletionBlock)completionHandler;



/** Adds a failure block.
 
 DCTConnectionControllerFailureBlock is defined as such:
 
 `typedef void (^DCTConnectionControllerFailureBlock) (NSError *error);`
 
 @param failureHandler The failure block to add.
 */
- (void)addFailureHandler:(DCTConnectionControllerFailureBlock)failureHandler;

/** Adds a completion block.
 
 DCTConnectionControllerCancelationBlock is defined as such:
 
 `typedef void (^DCTConnectionControllerCancelationBlock) ();`
 
 @param cancelationHandler The cancelation block to add.
 */
- (void)addCancelationHandler:(DCTConnectionControllerCancelationBlock)cancelationHandler;


/** Adds a status change handler.
 
 DCTConnectionControllerStatusBlock is defined as such:
 
 `typedef void (^DCTConnectionControllerStatusBlock) ();`
 
 @param statusChangeHandler The cancelation block to add.
 */
- (void)addStatusChangeHandler:(DCTConnectionControllerStatusBlock)statusChangeHandler;









#pragma mark - Managing the Connection

/// @name Managing the Connection

/** Adds the connection controller to the given queue, checking to make sure it is unique and if not, 
 returning the duplicate that is already queued.
 
 If there is a connection controller in the queue or already running that exists with the same details as
 the receiver, instead of calling to `DCTConnectionQueue` to enqueue itself, the connection controller will
 register some blocks with the existing connection controller. This uses `isEqualToConnectionController:` to 
 determine equality, which checks the `URL` of the desitnation, the `type` and each property added by subclasses.
 
 In the case that an existing connection controller is already running, the receiver will never be queued.
 It will pass through, in all the usual ways of delegation, KVO, NSNotifications and block calling, the results
 of the existing connection controller.
 
 @param queue The queue to add the receiver to.
 */
- (void)connectOnQueue:(DCTConnectionQueue *)queue;


/** Cancels the connection.
 
 Canceling the connection causes any cancelation blocks to be called and sends connectionControllerWasCancelled:
 to its delegates.
 */
- (void)cancel;


/** Requeues the connection.
 */
- (void)requeue;



#pragma mark - Methods to use in Subclasses

/// @name Methods to use in Subclasses

/** This method should be used in subclasses to give custom requests.
 
 Calling super from the subclass will generate a request of type 'type', this is the prefered way 
 to setup an initial request object in subclasses.
 */
- (void)loadURLRequest;

/** This method should be used in subclasses to handle the returned response.
 
 Subclasses should handle the response, taking any course of action given in the API documentation.
 The default implementation of this method notifies the delegate and observers of the response, so at
 the end of this method subclasses should call the super implementation.
 */
- (void)connectionDidReceiveResponse;

/** This method should be used in subclasses to handle the returned data.
 
 Subclasses should handle the incoming data, creating a wrapper or data object for the delegate
 and observers to use. The default implementation of this method notifies the delegate and observers
 of the new data. Therefore, at the end of this method subclasses should call the super implementation
 with the handled data object as the parameter.
 
 If connecting to a web service always responds successful, but returns it's error in JSON, a 
 subclass can call receivedError: from its implementation of this method and this would propigate up
 and the status of the connection controller would be reported as DCTConnectionControllerStatusFailed.
 As well as this, instead of notifying delgates and observers that it had succeeded, it would report as
 failed and again would call the failureBlocks rather than the completionBlocks.
 
 @see connectionDidFail
 */
- (void)connectionDidFinishLoading;

/** This method should be used in subclasses to handle the returned error.
 
 Subclasses should handle the error, taking any course of action given in the API documentation.
 The default implementation of this method notifies the delegate and observers of the error, so at
 the end of this method subclasses should call the super implementation. This could be provided with
 a new error message created specifically for delegates and observers or just passing the error 
 returned from the connection.
 
 @see connectionDidFinishLoading
 */
- (void)connectionDidFail;







#pragma mark - Connection Status

/// @name Connection Status

/** The status of the connection controller.
 
 Possible statuses include:
 
 * `DCTConnectionControllerStatusNotStarted` When the connection has not started. It is also currently in 
 this state if it has not been queued up due to an existing connection controller being equal existing.
 
 * `DCTConnectionControllerStatusQueued` The connection controller has been queued up by the DCTConnectionQueue 
 and it is waiting to be started.
 
 * `DCTConnectionControllerStatusStarted` The connection controller has started and is awaiting a response.
 
 
 * `DCTConnectionControllerStatusResponded` A repsonse has been received.
 
 * `DCTConnectionControllerStatusComplete` The connection controller has completed successfully.
 
 * `DCTConnectionControllerStatusFailed` The connection controller has failed at some point, either due to a connection 
 issue or an issue with the API usage.
 
 * `DCTConnectionControllerStatusCancelled`	The connection was cancelled by an external entity.
 
 A connection controller is never gauranteed to be `Queued`; If an equal connection controller exists, the DCTConnectionQueue won't
 queue up the duplicate. I'd imagine a new status will be born for this later on.
 
 Generally a finished connection controller will only ever be `Complete`, `Failed` or `Cancelled`. That is to say that a completed 
 connection controller won't become failed or cancelled later on.
 
 Currently, connection controllers generally go through `NotStarted`, `Responded` and (`Complete`|`Failed`|`Cancelled`) statuses, 
 though it is probably not wise to use this as a way of listening for events.
 
 */
@property (nonatomic, readonly) DCTConnectionControllerStatus status;

@property (nonatomic, strong, readonly) NSNumber *percentDownloaded;

/** The URL connection that is being run by the connection controller;
 */
@property (nonatomic, strong, readonly) NSURLConnection *URLConnection;

/** The location where the connection controller is temporarily storing the downloaded data. 
 */
@property (nonatomic, strong, readonly) NSString *downloadPath;

/** The response returned from the connection.
 
 This holds the response given to the notifyDelegateAndObserversOfResponse: method, for observers to access.
 */
@property (nonatomic, strong) NSURLResponse *returnedResponse;

/** The object, if there is one, returned from the connection.
 
 This holds the object given to the notifyDelegateAndObserversOfReturnedObject: method, for observers to access.
 */
@property (nonatomic, strong) id returnedObject;

/** The error, if there is one, returned from the connection.
 
 This holds the error given to the notifyDelegateAndObserversOfReturnedError: method, for observers to access.
 */
@property (nonatomic, strong) NSError *returnedError;


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
 @param object The object returned by the connection.
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

#import "DCTConnectionController+Deprecated.h"
