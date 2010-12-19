//
//  DTOAuthSignature.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	DCTOAuthSignatureTypeHMAC_SHA1 = 0,
	DCTOAuthSignatureTypePlaintext
} DCTOAuthSignatureType;

/** Class to generate the OAuth Signature.
 */
@interface DCTOAuthSignature : NSObject {
}

/// @name Properties

/** Signature type.
 
 Possible handled types are:
 
 * `DCTOAuthSignatureTypeHMAC_SHA1` Uses the HMAC-SHA1 method.
 * `DCTOAuthSignatureTypePlaintext` Uses plaintext method.
 */
@property (nonatomic, assign) DCTOAuthSignatureType type;

/** Secret.
 */
@property (nonatomic, copy) NSString *secret;

/** Text.
 */
@property (nonatomic, copy) NSString *text;



/// @name Generated Properties

/** Generated signature.
 */
@property (nonatomic, readonly) NSString *signature;

/** String representing the method used.
 */
@property (nonatomic, readonly) NSString *method;


// Depricated
- (NSString *)typeString;

@end
