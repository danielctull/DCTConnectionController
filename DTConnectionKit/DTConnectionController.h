//
//  DTConnectionController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 13.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnectionManager.h"

/*!
 Specifies the type of connection to use.
 */
typedef enum {
	DTConnectionTypeGet = 0,	/*!< Uses a GET connection. */
	DTConnectionTypePost,		/*!< Uses a POST connection. */
	DTConnectionTypePut,		/*!< Uses a PUT connection. */
	DTConnectionTypeDelete,		/*!< Uses a DELETE connection. */
	DTConnectionTypeOptions,	/*!< Uses a OPTIONS connection. */
	DTConnectionTypeHead,		/*!< Uses a HEAD connection. */
	DTConnectionTypeTrace,		/*!< Uses a TRACE connection. */
	DTConnectionTypeConnect		/*!< Uses a CONNECT connection. */
} DTConnectionType;

/*!
 Specifies the different stages of a connection.
 */
typedef enum {
	DTConnectionStatusNotStarted = 0,	/*!< The connection has not begun yet, and has not been given to the DTConnectionManager object to perform. */
	DTConnectionStatusQueued,			/*!< The connection has been placed in a queue and is awaiting a free slot to perform. */
	DTConnectionStatusStarted,			/*!< The request has been sent and a response is being awaited. */
	DTConnectionStatusResponded,		/*!< A response has been received by the server and the connection is awaiting completion. */
	DTConnectionStatusComplete,			/*!< The connection completed without any errors. */
	DTConnectionStatusFailed			/*!< The connection failed. */
} DTConnectionStatus;

/*!
 Name of the notification sent out when the connection has successfully completed.
 */
extern NSString *const DTConnectionControllerCompletedNotification;

/*!
 Name of the notification sent out when the connection has failed.
 */
extern NSString *const DTConnectionControllerFailedNotification;

/*!
 Name of the notification sent out when the connection has recieved a response.
 */
extern NSString *const DTConnectionControllerResponseNotification;

#pragma mark -
@protocol DTConnectionControllerDelegate;

#pragma mark -
@interface DTConnectionController : NSObject <DTConnectionManagerDelegate> {
	NSObject<DTConnectionControllerDelegate> *delegate;
	DTConnectionType type;
	NSObject *returnedObject;
	NSError *returnedError;
	NSURLResponse *returnedResponse;
	DTConnectionStatus status;
}

/*!
 The object that acts as the delegate of the receiving connection controller.
 
 Unlike the usual behaviour of delegates in Cocoa, the delegate is retained by the connection controller. 
 This is because DTConnectionController uses DTConnectionManager to perform the connection and the connection manager
 must retain its delegates. Because of this the delegate should never retain the connection controller.
 */
@property (nonatomic, retain) NSObject<DTConnectionControllerDelegate> *delegate;

/*!
 Specifies the type of connection to use.
 */
@property (nonatomic, readonly) DTConnectionType type;

/*!
 This holds the object given to the notifyDelegateAndObserversOfReturnedObject: method, for observers to access.
 */
@property (nonatomic, readonly) NSObject *returnedObject;

/*!
 This holds the error given to the notifyDelegateAndObserversOfReturnedError: method, for observers to access.
 */
@property (nonatomic, readonly) NSError *returnedError;

/*!
 This holds the response given to the notifyDelegateAndObserversOfResponse: method, for observers to access.
 */
@property (nonatomic, readonly) NSURLResponse *returnedResponse;

/*!
 Shows the current status of the connection. This property can be observed to show progress of a connection.
 */
@property (nonatomic, readonly) DTConnectionStatus status;



#pragma mark -
#pragma mark For external classes to use

/** Initialises a newly created DTConnectionController with the given type and delegate.

 jdsfkljskldfjsjfklsjf

 @param aType The type required for the connection.
 @param aDelegate The delegate for the connection.
 @return A DTConnectionController object initialised with type, aType and delegate, aDelegate.

 */
- (id)initWithType:(DTConnectionType)aType delegate:(NSObject<DTConnectionControllerDelegate> *)aDelegate;

/** Initialises a newly created DTConnectionController with the given type.
 
 @param aType The type required for the connection.
 @return A DTConnectionController object initialised with aType.
 
 */
- (id)initWithType:(DTConnectionType)aType;

/** This method starts the connection.
 
 Calling this uses the request returned from -newRequest to pass to DTConnectionManager. 

 */
- (void)start;

#pragma mark -
#pragma mark For subclasses to use

/**
 This method should be used in subclasses to give custom requests.
 
 Calling super from the subclass will give a mutable request of type 'type', this is the prefered way 
 to get the request object in subclasses.
 
 @return A URL request which will form the connection.
 */
- (NSMutableURLRequest *)newRequest;

/** Sends the delegate a message that the conenction has returned this object and sends out a notification.￼

 Subclasses should handle the incoming data, creating a wrapper or data object for it for the delegate and observers to use and then call this method with that created object.

 @param object The object to be sent to the delegate and stored in returnedObject.

*/
- (void)notifyDelegateAndObserversOfReturnedObject:(NSObject *)object;

/** Sends the delegate a message that the conenction has failed, with the given error.
 
 By default this is called when an error returns from DTConnectionManager. Subclasses could utilise this
 by interpretating the error from the connection and packaging an error more meaningful to the delegate and observers.
 
 @param error The error to be sent to the delegate and stored in returnedError.
 */
- (void)notifyDelegateAndObserversOfReturnedError:(NSError *)error;

/** Sends the delegate a message that the conenction has received a response, with the given URL response.
 
By default this is called when a response returns from DTConnectionManager.
 @param response The URL response to be sent to the delegate and stored in returnedResponse.
 
 */
- (void)notifyDelegateAndObserversOfResponse:(NSURLResponse *)response;

@end

#pragma mark -
/** The delegate of DTConnectionController must adopt the DTConnectionControllerDelegate protocol, although all the methods 
 are optional. They allow the delegate to handle only certain types of events, although connectionController:didSucceedWithObject: 
 and connectionController:didFailWithError: should both be handled to take advantage of the data and handle any occuring errors.
 */
@protocol DTConnectionControllerDelegate
@optional
/** Tells the delegate the connection has succeeded.
 @param connectionController The connection controller informing the delegate of the event.
 @param object The object returned by the connection.
 */
- (void)connectionController:(DTConnectionController *)connectionController didSucceedWithObject:(id)object;
/** Tells the delegate the connection has failed.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param error The error received from the server.
 */
- (void)connectionController:(DTConnectionController *)connectionController	didFailWithError:(NSError *)error;
/** Tells the delegate a response has been received from the server.
 
 @param connectionController The connection controller informing the delegate of the event.
 @param response The received response.
 */
- (void)connectionController:(DTConnectionController *)connectionController didReceiveResponse:(NSURLResponse *)response;
@end
