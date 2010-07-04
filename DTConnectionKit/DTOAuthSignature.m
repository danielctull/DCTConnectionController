//
//  DTOAuthSignature.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthSignature.h"
#import "NSData+Base64.h"
#import <CommonCrypto/CommonHMAC.h>

NSString * const DTOAuthSignatureTypeString[] = {
	@"HMAC-SHA1"
};

@implementation DTOAuthSignature
@synthesize type, secret, text;

- (NSString *)typeString {
	return DTOAuthSignatureTypeString[self.type];
}

- (NSString *)signature {
	
	NSData *secretData = [self.secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *textData = [self.text dataUsingEncoding:NSUTF8StringEncoding];
	
	uint8_t result[CC_SHA1_DIGEST_LENGTH] = {0};
	
	CCHmacContext hmacContext;
	CCHmacInit(&hmacContext, kCCHmacAlgSHA1, secretData.bytes, secretData.length);
	CCHmacUpdate(&hmacContext, textData.bytes, textData.length);
	CCHmacFinal(&hmacContext, result);
	
	NSData *theData = [NSData dataWithBytes:result length:CC_SHA1_DIGEST_LENGTH];
	
	return [theData base64EncodedString];
}

@end
