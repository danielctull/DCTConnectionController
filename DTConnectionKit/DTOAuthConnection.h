//
//  DTOAuthConnection.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnection.h"

extern NSString *const DTOAuthCallBackKey;
extern NSString *const DTOAuthConsumerKeyKey;
extern NSString *const DTOAuthNonceKey;
extern NSString *const DTOAuthSignatureMethodKey;
extern NSString *const DTOAuthTimestampKey;
extern NSString *const DTOAuthVersionKey;
extern NSString *const DTOAuthSignatureKey;

@interface DTOAuthConnection : DTConnection {
	NSMutableDictionary *parameters;
}

- (void)valueForParameter:(NSString *)parameterName;
- (void)setValue:(NSString *)value forParameter:(NSString *)parameterName;

@property (nonatomic, retain) NSString *nonce;
@property (nonatomic, retain) NSString *consumerKey;
@property (nonatomic, retain) NSString *secretConsumerKey;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSURL *URL;

@end
