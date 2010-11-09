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
	DCTConnectionControllerTypeGet = 0,	/**< Uses a GET connection. */
	DCTConnectionControllerTypePost,		/**< Uses a POST connection. */
	DCTConnectionControllerTypePut,		/**< Uses a PUT connection. */
	DCTConnectionControllerTypeDelete,		/**< Uses a DELETE connection. */
	DCTConnectionControllerTypeOptions,	/**< Uses a OPTIONS connection. */
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
	DCTConnectionControllerStatusResponded,		/**< A response has been received by the server and the connection is awaiting completion. */
	DCTConnectionControllerStatusComplete,			/**< The connection completed without any errors. */
	DCTConnectionControllerStatusFailed,			/**< The connection failed. */
	DCTConnectionControllerStatusCancelled			/**< The connection failed. */
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

@interface DCTConnectionController : NSObject {
	DCTConnectionControllerPriority priority;
	NSMutableArray *dependencies;
	DCTConnectionType type;
	DCTConnectionControllerStatus status;
	DCTURLConnection *urlConnection;
	NSURL *URL;
	NSObject *returnedObject;
	NSError *returnedError;
	NSURLResponse *returnedResponse;
	NSMutableArray *delegates;
	NSMutableSet *observationInfos;
}


@property (nonatomic, copy) DCTConnectionControllerResponseBlock responseBlock;
@property (nonatomic, copy) DCTConnectionControllerCompletionBlock completionBlock;
@property (nonatomic, copy) DCTConnectionControllerFailureBlock failureBlock;
@property (nonatomic, copy) DCTConnectionControllerCancelationBlock cancelationBlock;

@property (nonatomic, readonly) DCTConnectionControllerStatus status;
@property (nonatomic, assign) DCTConnectionControllerPriority priority;

@property (nonatomic, readonly) NSArray *dependencies;

@property (nonatomic, retain, readonly) NSURL *URL;

+ (id)connectionController;

- (void)addDependency:(DCTConnectionController *)connectionController;
- (void)removeDependency:(DCTConnectionController *)connectionController;

- (DCTConnectionController *)connect;
- (void)cancel;
- (void)reset;
- (void)requeue;

- (void)start;

- (void)setQueued;

@property (nonatomic, assign) BOOL multitaskEnabled;

#pragma mark -
#pragma mark Setting up the connection details

/** @name Setting up the connection details
 @{
 */

/** @brief The type of connection to use.
 
 Specifies the type of connection to use. DTConnectionType is a typedef enum and possible values can be seen in the header file.
 */
@property (nonatomic, assign) DCTConnectionType type;

/** @brief This method should be used in subclasses to give custom requests.
 
 Calling super from the subclass will give a mutable request of type 'type', this is the prefered way 
 to get the request object in subclasses.
 
 @return A URL request which will form the connection.
 */
- (NSMutableURLRequest *)newRequest;

/**
 @}
 */


#pragma mark -
#pragma mark Setting up the delegate

/** @name Setting up the delegate
 @{
 */

/** @brief The object that acts as the delegate of the receiving connection controller.
 
 Unlike the usual behaviour of delegates in Cocoa, the delegate is retained by the connection controller. 
 This is because DCTConnectionController uses DTConnectionManager to perform the connection and the connection manager
 must retain its delegates. Because of this the delegate should never retain the connection controller.
 
 @deprecated This property is now deprecated because connection controllers can now have multiple delegates as
 the connection system can merge a connection controller at a whim, merging the delegates. It does this to 
 save bandwidth for identical connections happening. See the DCTEquality category for details on the new equality
 checking. Use -addDelegate: and -delegates instead.
 */
@property (nonatomic, retain) id<DCTConnectionControllerDelegate> delegate;


- (void)addDelegate:(id<DCTConnectionControllerDelegate>)delegate;
- (void)addDelegates:(NSArray *)delegateArray;
- (void)removeDelegate:(id<DCTConnectionControllerDelegate>)delegate;
- (void)removeDelegates:(NSArray *)delegates;
- (NSArray *)delegates;
- (NSSet *)observationInformation;

/**
 @}
 */

#pragma mark -
#pragma mark Handling connection events

/** @name Handling connection events
 @{
 */

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
 */
- (void)receivedError:(NSError *)error;

/**
 @}
 */

#pragma mark -
#pragma mark Returned connection objects

/** @name Returned connection objects 
 @{
 */

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
/** The delegate of DCTConnectionController must adopt the DCTConnectionControllerDelegate protocol, although all the methods 
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
