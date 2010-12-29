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


/** A DCTConnectionController to make loading OAuth connections easier.
 */
@interface DCTOAuthConnectionController : DCTRESTController {
	NSDictionary *oauthParameters;
	DCTOAuthSignature *signature;	
	NSString *timestamp;
}

/// @name Methods to subclass

/**
 
 @see [DCTRESTController queryProperties] 
 @see [DCTRESTController headerProperties] 
 @see [DCTRESTController bodyProperties]
 */
+ (NSArray *)oauthProperties;



+ (NSDictionary *)oauthDictionaryFromString:(NSString *)string;
- (void)receivedOAuthDictionary:(NSDictionary *)dictionary;

/// @name OAuth Properties

/** The nonce.
 */
@property (nonatomic, retain) NSString *nonce;

/** Consumer key.
 */
@property (nonatomic, retain) NSString *consumerKey;

/** Secret consumer key.
 */
@property (nonatomic, retain) NSString *secretConsumerKey;

/** Token.
 */
@property (nonatomic, retain) NSString *token;

/** Secret token, if available.
 */
@property (nonatomic, retain) NSString *secretToken;

/** Version.
 */
@property (nonatomic, retain) NSString *version;

/** The timestamp.
 */
@property (nonatomic, readonly) NSString *timestamp;

/** The generated signature.
 */
@property (nonatomic, readonly) DCTOAuthSignature *signature;

@end
