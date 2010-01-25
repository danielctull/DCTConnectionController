//
//  DTConnectionController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 13.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnectionManager.h"

/** @brief Specifies the type of connection to use.
 */
typedef enum {
	DTConnectionTypeGet = 0,	/**< Uses a GET connection. */
	DTConnectionTypePost,		/**< Uses a POST connection. */
	DTConnectionTypePut,		/**< Uses a PUT connection. */
	DTConnectionTypeDelete,		/**< Uses a DELETE connection. */
	DTConnectionTypeOptions,	/**< Uses a OPTIONS connection. */
	DTConnectionTypeHead,		/**< Uses a HEAD connection. */
	DTConnectionTypeTrace,		/**< Uses a TRACE connection. */
	DTConnectionTypeConnect		/**< Uses a CONNECT connection. */
} DTConnectionType;

typedef enum {
	DTConnectionCacheTypeNone			= 0,		/*!< Uses a GET connection. */
	DTConnectionCacheTypeMemory			= 1 << 1,	/*!< Uses a POST connection. */
	DTConnectionCacheTypeDisk			= 1 << 2,	/*!< Uses a DELETE connection. */
	DTConnectionCacheTypeConditionalGet = 1 << 3	/*!< Uses a PUT connection. */
} DTConnectionCacheType;

/** @brief Specifies the different stages of a connection.
 */
typedef enum {
	DTConnectionStatusNotStarted = 0,	/**< The connection has not begun yet, and has not been given to the DTConnectionManager object to perform. */
	DTConnectionStatusQueued,			/**< The connection has been placed in a queue and is awaiting a free slot to perform. */
	DTConnectionStatusStarted,			/**< The request has been sent and a response is being awaited. */
	DTConnectionStatusResponded,		/**< A response has been received by the server and the connection is awaiting completion. */
	DTConnectionStatusComplete,			/**< The connection completed without any errors. */
	DTConnectionStatusFailed			/**< The connection failed. */
} DTConnectionStatus;

/** @brief Name of the notification sent out when the connection has successfully completed.
 */
extern NSString *const DTConnectionControllerCompletedNotification;

/** @brief Name of the notification sent out when the connection has failed.
 */
extern NSString *const DTConnectionControllerFailedNotification;

/** @brief Name of the notification sent out when the connection has recieved a response.
 */
extern NSString *const DTConnectionControllerResponseNotification;

#pragma mark -
@protocol DTConnectionControllerDelegate;

#pragma mark -
/** This is an abstract class for handling API calls to web services, where you should handle the reponse and returned data in subclasses.
 On receiving the data, subclasses should process it, optionally (though ideally) converting it to Cocoa model objects.
 */
@interface DTConnectionController : NSObject {
	NSObject<DTConnectionControllerDelegate> *delegate;
	DTConnectionType type;
	NSObject *returnedObject;
	NSError *returnedError;
	NSURLResponse *returnedResponse;
	NSHTTPURLResponse *httpResponse;
	DTConnectionStatus status;
	BOOL enableCaching;
}

@property (nonatomic, assign) BOOL enableCaching;

#pragma mark -
#pragma mark Starting a connection

/** @name Starting a connection
 @{
 */

/** @brief This method starts the connection.
 
 Calling this uses the request returned from -newRequest to pass to DTConnectionManager. 

 */
- (void)start;

/**
 @}
 */

#pragma mark -
#pragma mark Setting up the connection details

/** @name Setting up the connection details
 @{
 */

/** @brief The type of connection to use.
 
 Specifies the type of connection to use. DTConnectionType is a typedef enum and possible values can be seen in the header file.
 */
@property (nonatomic, readonly) DTConnectionType type;

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
@property (nonatomic, readonly) NSURLResponse *returnedResponse;

/** @brief The object, if there is one, returned from the connection.
 
 This holds the object given to the notifyDelegateAndObserversOfReturnedObject: method, for observers to access.
 */
@property (nonatomic, readonly) NSObject *returnedObject;

/** @brief The error, if there is one, returned from the connection.
 
 This holds the error given to the notifyDelegateAndObserversOfReturnedError: method, for observers to access.
 */
@property (nonatomic, readonly) NSError *returnedError;

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
@property (nonatomic, retain) NSObject<DTConnectionControllerDelegate> *delegate;

/**
 @}
 */

#pragma mark -
#pragma mark Checking the status of a connection

/** @name Checking the status of a connection
 @{
 */

/** @brief The current status of the connection.
 
 This property can be observed to show progress of a connection. DTConnectionStatus is a typedef enum and possible values can be seen in the header file.
 */
@property (nonatomic, readonly) DTConnectionStatus status;
/*
 @}
 */

@end

#pragma mark -
/** The delegate of DTConnectionController must adopt the DTConnectionControllerDelegate protocol, although all the methods 
 are optional. They allow the delegate to handle only certain types of events, although connectionController:didSucceedWithObject: 
 and connectionController:didFailWithError: should both be handled to take advantage of the data and handle any occuring errors.
 */
@protocol DTConnectionControllerDelegate
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
- (void)connectionController:(DTConnectionController *)connectionController	didFailWithError:(NSError *)error;
/** @brief Tells the delegate a response has been received from the server.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param response The received response.
 */
- (void)connectionController:(DTConnectionController *)connectionController didReceiveResponse:(NSURLResponse *)response;
@end
