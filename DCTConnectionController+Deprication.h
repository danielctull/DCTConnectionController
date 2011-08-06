//
//  DCTConnectionController+Deprication.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 06.08.2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//


#import "DCTConnectionController.h"

extern NSString *const DCTConnectionControllerDidReceiveObjectNotification;
extern NSString *const DCTConnectionControllerDidReceiveErrorNotification;
typedef void (^DCTConnectionControllerCompletionBlock) (NSObject *object);

#define DCTConnectionControllerStatusComplete DCTConnectionControllerStatusFinished

@interface DCTConnectionController (Deprication)

- (void)setDownloadPath:(NSString *)downloadPath;

- (void)addResponseBlock:(DCTConnectionControllerResponseBlock)responseBlock;
- (void)addFailureBlock:(DCTConnectionControllerFailureBlock)failureBlock;
- (void)addCompletionBlock:(DCTConnectionControllerCompletionBlock)completionBlock;
- (void)addCancelationBlock:(DCTConnectionControllerCancelationBlock)cancelationBlock;

@end
