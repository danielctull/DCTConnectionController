//
//  DTOAuthConnectionController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"
#import "DCTOAuthSignature.h"

extern NSString *const DCTOAuthCallBackKey;
extern NSString *const DCTOAuthConsumerKeyKey;
extern NSString *const DCTOAuthNonceKey;
extern NSString *const DCTOAuthSignatureMethodKey;
extern NSString *const DCTOAuthTimestampKey;
extern NSString *const DCTOAuthVersionKey;
extern NSString *const DCTOAuthSignatureKey;
extern NSString *const DCTOAuthTokenKey;
extern NSString *const DCTOAuthVerifierKey;
extern NSString *const DTOAuthVerifierKey;

@interface DCTOAuthConnectionController : DCTConnectionController {
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
