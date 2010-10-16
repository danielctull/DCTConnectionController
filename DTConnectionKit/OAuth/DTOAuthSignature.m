//
//  DTOAuthSignature.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthSignature.h"
#import "NSData+Base64.h"
#import "NSString+DTURLEncoding.h"
#import <CommonCrypto/CommonHMAC.h>

NSString * const DTOAuthSignatureTypeString[] = {
	@"HMAC-SHA1",
	@"PLAINTEXT"
};

@implementation DTOAuthSignature
@synthesize type, secret, text;

- (NSString *)typeString {
	return DTOAuthSignatureTypeString[DTOAuthSignatureTypeHMAC_SHA1];
	
	// PLAIN TEXT NOT WORKING
	return DTOAuthSignatureTypeString[self.type];
}

- (NSString *)signature {
	
	if (self.type == DTOAuthSignatureTypePlaintext) {
		// NOT WORKING CURRENTLY
		// return [self.secret dt_urlEncodedString];
	}
		
	NSData *secretData = [self.secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *textData = [self.text dataUsingEncoding:NSUTF8StringEncoding];
	
	unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, textData.bytes, textData.length, result);
	
	NSData *theData = [NSData dataWithBytes:result length:20];
	
	return [[theData base64EncodedString] dt_urlEncodedString];
}

@end
