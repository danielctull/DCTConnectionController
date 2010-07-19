//
//  DTConnectionController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnectionController.h"
#import "DTURLConnection.h"

/** @brief Specifies the type of connection to use.
 */
typedef enum {
	DTConnectionControllerTypeGet = 0,	/**< Uses a GET connection. */
	DTConnectionControllerTypePost,		/**< Uses a POST connection. */
	DTConnectionControllerTypePut,		/**< Uses a PUT connection. */
	DTConnectionControllerTypeDelete,		/**< Uses a DELETE connection. */
	DTConnectionControllerTypeOptions,	/**< Uses a OPTIONS connection. */
	DTConnectionControllerTypeHead,		/**< Uses a HEAD connection. */
	DTConnectionControllerTypeTrace,		/**< Uses a TRACE connection. */
	DTConnectionControllerTypeConnect		/**< Uses a CONNECT connection. */
} DTConnectionType;

/** @brief Specifies the different stages of a connection.
 */
typedef enum {
	DTConnectionControllerStatusNotStarted = 0,	/**< The connection has not begun yet, and has not been given to the DTConnectionManager object to perform. */
	DTConnectionControllerStatusQueued,			/**< The connection has been placed in a queue and is awaiting a free slot to perform. */
	DTConnectionControllerStatusStarted,			/**< The request has been sent and a response is being awaited. */
	DTConnectionControllerStatusResponded,		/**< A response has been received by the server and the connection is awaiting completion. */
	DTConnectionControllerStatusComplete,			/**< The connection completed without any errors. */
	DTConnectionControllerStatusFailed,			/**< The connection failed. */
	DTConnectionControllerStatusCancelled			/**< The connection failed. */
} DTConnectionControllerStatus;

/** @brief Specifies the possible priorities for a connection.
 */
typedef enum {
	DTConnectionControllerPriorityVeryHigh = 0,
	DTConnectionControllerPriorityHigh,
	DTConnectionControllerPriorityMedium,
	DTConnectionControllerPriorityLow,
	DTConnectionControllerPriorityVeryLow
} DTConnectionControllerPriority;

/** @brief Name of the notification sent out when the connection has successfully completed.
 */
extern NSString *const DTConnectionControllerCompletedNotification;

/** @brief Name of the notification sent out when the connection has failed.
 */
extern NSString *const DTConnectionControllerFailedNotification;

/** @brief Name of the notification sent out when the connection has recieved a response.
 */
extern NSString *const DTConnectionControllerResponseNotification;

extern NSString *const DTConnectionControllerTypeString[];

@protocol DTConnectionControllerDelegate;

@interface DTConnectionController : NSObject {
	DTConnectionControllerPriority priority;
	NSMutableArray *dependencies;
	DTConnectionType type;
	DTConnectionControllerStatus status;
	DTURLConnection *urlConnection;
	NSURL *URL;
	NSObject *returnedObject;
	NSError *returnedError;
	NSURLResponse *returnedResponse;
}

@property (nonatomic, readonly) DTConnectionControllerStatus status;
@property (nonatomic, assign) DTConnectionControllerPriority priority;

@property (nonatomic, readonly) NSArray *dependencies;

@property (nonatomic, retain, readonly) NSURL *URL;

+ (id)connectionController;

- (void)addDependency:(DTConnectionController *)connectionController;
- (void)removeDependency:(DTConnectionController *)connectionController;

- (void)connect;
- (void)cancel;
- (void)reset

- (void)start;

- (void)setQueued;


#pragma mark -
#pragma mark Setting up the connection details

/** @name Setting up the connection details
 @{
 */

/** @brief The type of connection to use.
 
 Specifies the type of connection to use. DTConnectionType is a typedef enum and possible values can be seen in the header file.
 */
@property (nonatomic, assign) DTConnectionType type;

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
 This is because DTConnectionController uses DTConnectionManager to perform the connection and the connection manager
 must retain its delegates. Because of this the delegate should never retain the connection controller.
 */
@property (nonatomic, retain) id<DTConnectionControllerDelegate> delegate;

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
/** The delegate of DTConnectionController must adopt the DTConnectionControllerDelegate protocol, although all the methods 
 are optional. They allow the delegate to handle only certain types of events, although connectionController:didSucceedWithObject: 
 and connectionController:didFailWithError: should both be handled to take advantage of the data and handle any occuring errors.
 */
@protocol DTConnectionControllerDelegate <NSObject>
@optional
/** @brief Tells the delegate the connection has succeeded.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param object The object returned by the connection.
 */
- (void)connectionController:(DTConnectionController *)connectionController didSucceedWithObject:(NSObject *)object;
/** @brief Tells the delegate the connection has failed.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param error The error received from the server.
 */
- (void)connectionController:(DTConnectionController *)connectionController didFailWithError:(NSError *)error;

/** @brief Tells the delegate the connection was cancelled.
 
 @param connectionController The connection controller informing the delegate of the event.
 */
- (void)connectionControllerWasCancelled:(DTConnectionController *)connectionController;

/** @brief Tells the delegate a response has been received from the server.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param response The received response.
 */
- (void)connectionController:(DTConnectionController *)connectionController didReceiveResponse:(NSURLResponse *)response;
@end
