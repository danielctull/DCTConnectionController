//
//  DTOAuthConnectionController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"
#import "DCTOAuthSignature.h"

extern NSString *const DTOAuthCallBackKey;
extern NSString *const DTOAuthConsumerKeyKey;
extern NSString *const DTOAuthNonceKey;
extern NSString *const DTOAuthSignatureMethodKey;
extern NSString *const DTOAuthTimestampKey;
extern NSString *const DTOAuthVersionKey;
extern NSString *const DTOAuthSignatureKey;
extern NSString *const DTOAuthTokenKey;
extern NSString *const DTOAuthTokenSecretKey;
extern NSString *const DTOAuthVerifierKey;

@interface DTOAuthConnectionController : DCTConnectionController {
	NSMutableDictionary *parameters;
}

- (NSString *)valueForParameter:(NSString *)parameterName;
- (void)setValue:(NSString *)value forParameter:(NSString *)parameterName;

- (DCTOAuthSignature *)signature;

- (void)receivedOAuthDictionary:(NSDictionary *)dictionary;

+ (NSDictionary *)oauthDictionaryFromString:(NSString *)string;

@property (nonatomic, retain) NSString *nonce;
@property (nonatomic, retain) NSString *consumerKey;
@property (nonatomic, retain) NSString *secretConsumerKey;
@property (nonatomic, retain) NSString *secretToken;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSURL *URL;

@end
