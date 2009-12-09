//
//  DTRestCommand.h
//  DTKit
//
//  Created by Daniel Tull on 05.10.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnectionManager.h"

typedef enum {
	DTRestCommandTypeGet = 0,
	DTRestCommandTypePost,
	DTRestCommandTypePut,
	DTRestCommandTypeDelete
} DTRestCommandType;

extern NSString *const DTRestCommandCompletedSuccessfullyNotification;
extern NSString *const DTRestCommandFailedWithErrorNotification;

@protocol DTRestCommandDelegate;

@interface DTRestCommand : NSObject <DTConnectionManagerDelegate> {
	NSObject<DTRestCommandDelegate> *delegate;
	DTRestCommandType type;
	NSObject *returnedData;
	NSError *error;
}

@property (nonatomic, retain) NSObject<DTRestCommandDelegate> *delegate;
@property (nonatomic, readonly) DTRestCommandType type;
@property (nonatomic, readonly) NSObject *returnedData;
@property (nonatomic, readonly) NSError *error;

- (id)initWithDelegate:(NSObject<DTRestCommandDelegate> *)aDelegate type:(DTRestCommandType)aType;
- (id)initWithType:(DTRestCommandType)aType;

- (void)start;
- (void)startRequest;
- (NSMutableURLRequest *)newRequest;

- (BOOL)delegateRespondsToFailureSelector;
- (BOOL)delegateRespondsToReturnedObjectsSelector;
- (BOOL)delegateRespondsToReturnedObjectSelector;

- (BOOL)sendObjectToDelegate:(id)object;
- (BOOL)sendObjectsToDelegate:(NSArray *)array;
- (BOOL)sendErrorToDelegate:(NSError *)error;
@end

@protocol DTRestCommandDelegate
@optional
- (void)restCommand:(DTRestCommand *)restCommand didSucceedWithObjects:(NSArray *)objects;
- (void)restCommand:(DTRestCommand *)restCommand didSucceedWithObject:(id)object;
- (void)restCommand:(DTRestCommand *)restCommand didFailWithError:(NSError *)error;
@end
