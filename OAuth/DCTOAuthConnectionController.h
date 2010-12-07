//
//  DTOAuthConnectionController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTRESTController.h"
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

@interface DCTOAuthConnectionController : DCTRESTController {
	NSDictionary *oauthParameters;
	DCTOAuthSignature *signature;	
	NSString *timestamp;
}

+ (NSArray *)oauthProperties;



+ (NSDictionary *)oauthDictionaryFromString:(NSString *)string;
- (void)receivedOAuthDictionary:(NSDictionary *)dictionary;

@property (nonatomic, retain) NSString *nonce;
@property (nonatomic, retain) NSString *consumerKey;
@property (nonatomic, retain) NSString *secretConsumerKey;
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSString *secretToken;
@property (nonatomic, retain) NSString *version;


@property (nonatomic, readonly) NSString *timestamp;
@property (nonatomic, readonly) DCTOAuthSignature *signature;

@end
