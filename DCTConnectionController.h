//
//  DCTConnectionController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTConnectionController.h"
#import "DCTURLConnection.h"

/** @brief Specifies the type of connection to use.
 */
typedef enum {
	DCTConnectionControllerTypeGet = 0,		/**< Uses a GET connection. */
	DCTConnectionControllerTypePost,		/**< Uses a POST connection. */
	DCTConnectionControllerTypePut,			/**< Uses a PUT connection. */
	DCTConnectionControllerTypeDelete,		/**< Uses a DELETE connection. */
	DCTConnectionControllerTypeOptions,		/**< Uses a OPTIONS connection. */
	DCTConnectionControllerTypeHead,		/**< Uses a HEAD connection. */
	DCTConnectionControllerTypeTrace,		/**< Uses a TRACE connection. */
	DCTConnectionControllerTypeConnect		/**< Uses a CONNECT connection. */
} DCTConnectionType;

/** @brief Specifies the different stages of a connection.
 */
typedef enum {
	DCTConnectionControllerStatusNotStarted = 0,	/**< The connection has not begun yet, and has not been given to the DTConnectionManager object to perform. */
	DCTConnectionControllerStatusQueued,			/**< The connection has been placed in a queue and is awaiting a free slot to perform. */
	DCTConnectionControllerStatusStarted,			/**< The request has been sent and a response is being awaited. */
	DCTConnectionControllerStatusResponded,			/**< A response has been received by the server and the connection is awaiting completion. */
	DCTConnectionControllerStatusComplete,			/**< The connection completed without any errors. */
	DCTConnectionControllerStatusFailed,			/**< The connection failed. */
	DCTConnectionControllerStatusCancelled			/**< The connection was cancelled. */
} DCTConnectionControllerStatus;

/** @brief Specifies the possible priorities for a connection.
 */
typedef enum {
	DCTConnectionControllerPriorityVeryHigh = 0,
	DCTConnectionControllerPriorityHigh,
	DCTConnectionControllerPriorityMedium,
	DCTConnectionControllerPriorityLow,
	DCTConnectionControllerPriorityVeryLow
} DCTConnectionControllerPriority;

typedef void (^DCTConnectionControllerResponseBlock) (NSURLResponse *response);
typedef void (^DCTConnectionControllerCompletionBlock) (NSObject *object);
typedef void (^DCTConnectionControllerFailureBlock) (NSError *error);
typedef void (^DCTConnectionControllerCancelationBlock) ();

/** @brief Name of the notification sent out when the connection has successfully completed.
 */
extern NSString *const DCTConnectionControllerCompletedNotification;

/** @brief Name of the notification sent out when the connection has failed.
 */
extern NSString *const DCTConnectionControllerFailedNotification;

/** @brief Name of the notification sent out when the connection has recieved a response.
 */
extern NSString *const DCTConnectionControllerResponseNotification;

extern NSString *const DCTConnectionControllerTypeString[];

@protocol DCTConnectionControllerDelegate;



/** @brief A class to handle one connection.
 
 This class is an abstract class, which should always be subclassed in order to work.
 Included is a simple subclass, DCTURLLoadingConnectionController, which loads the given URL.
 
 Benefits to using a connection controller over using an NSURLConnection directly include:
 - Easy ability to split up funtionality
 - Setting up connections in a queue
 - Adding dependencies, so that connections only start once all dependencies are complete
 (useful for when a connection is dependent on a login connection for example)
 - Ability to merge identical connections, again useful for login connections.
 
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
 receivedObject: should look for error codes and if one is found, call receivedError: with an NSError
 created from the data from the web service. This allows delegates to be informed correctly, the 
 correct blocks to be called and the correct status to be set. Again, with the right class
 hierarchy, this will likely only have to be done once.
 */
@interface DCTConnectionController : NSObject {
	DCTConnectionControllerPriority priority;
	
	//NSMutableArray *dependencies;
	
	NSMutableSet *dependencies, *dependents;
	
	
	DCTConnectionType type;
	DCTConnectionControllerStatus status;
	DCTURLConnection *urlConnection;
	NSURL *URL;
	NSMutableSet *delegates;
	NSMutableSet *observationInfos;
	
	NSMutableSet *responseBlocks, *completionBlocks, *failureBlocks, *cancelationBlocks;
}

@property (nonatomic, retain, readonly) NSURL *URL;

@property (nonatomic, readonly) DCTConnectionControllerStatus status;

/** @brief Creates and returns an autoreleased connection controller. 
 */
+ (id)connectionController;



/** @brief Adds the connection controller to the queue, checking to make sure it is unique and if not, 
 returning the duplicate that is already queued.
 
 If there is a connection controller in the queue or already running that exists with the same details as
 the receiver, this will merge accross the delegate, completeion blocks, KVO and notification observers, then
 return with the connection controller that already exists. This uses isEqualToConnectionController: to determine
 equality, which checks the URL of the desitnation and each property added by subclasses.
 
 In the case that a connection controller is already running, delegates and completion blocks will be 
 called as soon as they are added to the existing connection controller. Due to this, it may be wise to
 
 Connection controllers with dependencies do not currently get merged into an existing 
 
 @return The actual connection controller that is added to the queue or already running.
 */
- (DCTConnectionController *)connect;


/** @brief Cancels the connection.
 
 Canceling the connection causes any cancelation blocks to be called and sends connectionControllerWasCancelled:
 to its delegates.
 */
- (void)cancel;



- (void)reset;




- (void)requeue;



- (void)start;

- (void)setQueued;

@property (nonatomic, assign) BOOL multitaskEnabled;

#pragma mark -
#pragma mark Setting up the connection details
/// @name    Setting up the connection details

/** @brief The type of connection to use.
 
 Specifies the type of connection to use. DTConnectionType is a typedef enum and possible values can be seen in the header file.
 */
@property (nonatomic, assign) DCTConnectionType type;


/** @brief The priority of the connection controller.
 
 Connection controllers will be sorted in order of their priority and as such high priority connections will be 
 handled first. If two connections are in the queue with equal priorities, then they will be started in the order 
 they were added to the conneciton queue. Generally it's a good idea to use the highest priority free for login
 connections and lowest priority for connections the user didn't directly initiate.
 */
@property (nonatomic, assign) DCTConnectionControllerPriority priority;






/** @brief This method should be used in subclasses to give custom requests.
 
 Calling super from the subclass will give a mutable request of type 'type', this is the prefered way 
 to get the request object in subclasses.
 
 @return A URL request which will form the connection.
 */
- (NSMutableURLRequest *)newRequest;



/** @brief The dependencies for this connection controller.
 */
@property (nonatomic, readonly) NSArray *dependencies;


/** @brief Adds a connection controller that needs to finish before the receiver can start.
 
 Currently, the depended connection controller just needs to be removed from the queue before the receiver starts, 
 whether the depended connection controller finishes with success or failure. This will be looked into for future 
 versions.
 
 @param connectionController The connection controller that should be complete before the receiver starts.
 */
- (void)addDependency:(DCTConnectionController *)connectionController;


/** @brief Removes the given connection controller from the list of depended connection controllers.
 
 If the given connection controller is not in the list of dependencies, this is a no-op.
 
 @param connectionController The connection controller to be removed from the dependency list.
 */
- (void)removeDependency:(DCTConnectionController *)connectionController;



#pragma mark -
#pragma mark Setting up the delegate
//     @name Setting up the delegate

/** @brief The object that acts as the delegate of the receiving connection controller.
 
 Unlike the usual behaviour of delegates in Cocoa, the delegate is retained by the connection controller. 
 This is because DCTConnectionController uses DTConnectionManager to perform the connection and the connection manager
 must retain its delegates. Because of this the delegate should never retain the connection controller.
 
 @deprecated This property is now deprecated because connection controllers can now have multiple delegates as
 the connection system can merge a connection controller at a whim, merging the delegates. It does this to 
 save bandwidth for identical connections happening. See the DCTEquality category for details on the new equality
 checking. Use -addDelegate: and -delegates instead.
 */
- (void)addDelegate:(id<DCTConnectionControllerDelegate>)delegate;
- (void)removeDelegate:(id<DCTConnectionControllerDelegate>)delegate;
- (NSSet *)delegates;



#pragma mark -
#pragma mark Managing event blocks
///    @name Managing event blocks

- (void)addResponseBlock:(DCTConnectionControllerResponseBlock)responseBlock;

- (void)addCompletionBlock:(DCTConnectionControllerCompletionBlock)completionBlock;

- (void)addFailureBlock:(DCTConnectionControllerFailureBlock)failureBlock;

- (void)addCancelationBlock:(DCTConnectionControllerCancelationBlock)cancelationBlock;



#pragma mark -
#pragma mark Handling connection responses
///    @name Handling connection responses

/** @brief This method should be used in subclasses to handle the returned response.
 
 Subclasses should handle the response, taking any course of action given in the API documentation.
 The default implementation of this method notifies the delegate and observers of the response, so at
 the end of this method subclasses should call the super implementation.
 
 @param response The response returned from the connection.
 */
- (void)receivedResponse:(NSURLResponse *)response;

/** @brief This method should be used in subclasses to handle the returned data.
 
 Subclasses should handle the incoming data, creating a wrapper or data object for the delegate
 and observers to use. The default implementation of this method notifies the delegate and observers
 of the new data. Therefore, at the end of this method subclasses should call the super implementation
 with the handled data object as the parameter.
 
 If connecting to a web service always responds successful, but returns it's error in JSON, a 
 subclass can call receivedError: from its implementation of this method and this would propigate up
 and the status of the connection controller would be reported as DCTConnectionControllerStatusFailed.
 As well as this, instead of notifying delgates and observers that it had succeeded, it would report as
 failed and again would call the failureBlocks rather than the completionBlocks.
 
 @param object The data object returned from the connection.
 */
- (void)receivedObject:(NSObject *)object;

/** @brief This method should be used in subclasses to handle the returned error.
 
 Subclasses should handle the error, taking any course of action given in the API documentation.
 The default implementation of this method notifies the delegate and observers of the error, so at
 the end of this method subclasses should call the super implementation. This could be provided with
 a new error message created specifically for delegates and observers or just passing the error 
 returned from the connection.
 
 @param response The response returned from the connection.
 
 @see receivedObject:
 */
- (void)receivedError:(NSError *)error;

#pragma mark -
#pragma mark Returned connection objects
///    @name Returned connection objects

/** @brief The response returned from the connection.
 
 This holds the response given to the notifyDelegateAndObserversOfResponse: method, for observers to access.
 */
@property (nonatomic, retain, readonly) NSURLResponse *returnedResponse;

/** @brief The object, if there is one, returned from the connection.
 
 This holds the object given to the notifyDelegateAndObserversOfReturnedObject: method, for observers to access.
 */
@property (nonatomic, retain, readonly) NSObject *returnedObject;

/** @brief The error, if there is one, returned from the connection.
 
 This holds the error given to the notifyDelegateAndObserversOfReturnedError: method, for observers to access.
 */
@property (nonatomic, retain, readonly) NSError *returnedError;

/**
 @}
 */

@end

#pragma mark -
/** @brief Protocol for delegates of DCTConnectionController to conform to.
 
 The delegate of DCTConnectionController must adopt the DCTConnectionControllerDelegate protocol, although all the methods 
 are optional. They allow the delegate to handle only certain types of events, although connectionController:didSucceedWithObject: 
 and connectionController:didFailWithError: should both be handled to take advantage of the data and handle any occuring errors.
 */
@protocol DCTConnectionControllerDelegate <NSObject>
@optional
/** @brief Tells the delegate the connection has succeeded.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param object The object returned by the connection.
 */
- (void)connectionController:(DCTConnectionController *)connectionController didSucceedWithObject:(NSObject *)object;
/** @brief Tells the delegate the connection has failed.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param error The error received from the server.
 */
- (void)connectionController:(DCTConnectionController *)connectionController didFailWithError:(NSError *)error;

/** @brief Tells the delegate the connection was cancelled.
 
 @param connectionController The connection controller informing the delegate of the event.
 */
- (void)connectionControllerWasCancelled:(DCTConnectionController *)connectionController;

/** @brief Tells the delegate a response has been received from the server.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param response The received response.
 */
- (void)connectionController:(DCTConnectionController *)connectionController didReceiveResponse:(NSURLResponse *)response;
@end