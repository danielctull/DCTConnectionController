//
//  DTConnectionController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 13.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnectionManager.h"

typedef enum {
	DTConnectionTypeGet = 0,
	DTConnectionTypePost,
	DTConnectionTypePut,
	DTConnectionTypeDelete
} DTConnectionType;

typedef enum {
	DTConnectionStatusNotStarted = 0,
	DTConnectionStatusQueued,
	DTConnectionStatusStarted,
	DTConnectionStatusResponded,
	DTConnectionStatusComplete,
	DTConnectionStatusFailed
} DTConnectionStatus;

extern NSString *const DTConnectionControllerCompletedNotification;
extern NSString *const DTConnectionControllerFailedNotification;
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

@property (nonatomic, retain) NSObject<DTConnectionControllerDelegate> *delegate;
@property (nonatomic, readonly) DTConnectionType type;
@property (nonatomic, readonly) NSObject *returnedObject;
@property (nonatomic, readonly) NSError *returnedError;
@property (nonatomic, readonly) NSURLResponse *returnedResponse;
@property (nonatomic, readonly) DTConnectionStatus status;



#pragma mark -
#pragma mark For external classes to use

- (id)initWithType:(DTConnectionType)aType delegate:(NSObject<DTConnectionControllerDelegate> *)aDelegate;
- (id)initWithType:(DTConnectionType)aType;
- (void)start;

#pragma mark -
#pragma mark For subclasses to use

- (NSMutableURLRequest *)newRequest;

- (void)notifyDelegateAndObserversOfReturnedObject:(NSObject *)object;
- (void)notifyDelegateAndObserversOfReturnedError:(NSError *)error;
- (void)notifyDelegateAndObserversOfResponse:(NSURLResponse *)response;

@end

#pragma mark -


@protocol DTConnectionControllerDelegate
@optional
- (void)connectionController:(DTConnectionController *)connectionController didSucceedWithObject:(id)object;
- (void)connectionController:(DTConnectionController *)connectionController didFailWithError:(NSError *)error;
- (void)connectionController:(DTConnectionController *)connectionController didReceiveResponse:(NSURLResponse *)response;
@end
