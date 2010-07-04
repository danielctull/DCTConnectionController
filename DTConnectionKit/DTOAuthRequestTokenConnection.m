//
//  DTOAuthRequestTokenConnection.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthRequestTokenConnection.h"
#import "DTOAuthSignature.h"

NSString *const DTOAuthCallBackKey = @"oauth_callback";
NSString *const DTOAuthConsumerKeyKey = @"oauth_consumer_key";
NSString *const DTOAuthNonceKey = @"oauth_nonce";
NSString *const DTOAuthSignatureMethodKey = @"oauth_signature_method";
NSString *const DTOAuthTimestampKey = @"oauth_timestamp";
NSString *const DTOAuthVersionKey = @"oauth_version";
NSString *const DTOAuthSignatureKey = @"oauth_signature";

@implementation DTOAuthRequestTokenConnection
@synthesize nonce, consumerKey, version;

- (NSString *)nonce {
	if (!nonce) {
		self.nonce = [[NSProcessInfo processInfo] globallyUniqueString];
	}
	return nonce;
}

- (NSString *)version {
	if (!version) {
		self.version = @"1.0";
	}
	return version;
}

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *r = [super newRequest];
	
	[r setURL:[NSURL URLWithString:@"http://api.twitter.com/oauth/request_token"]];
	
	/* oauth_callback
	 - http://localhost:3005/the_dance/process_callback?service_provider_id=11
	 oauth_consumer_key
	 - GDdmIQH6jhtmLUypg82g
	 oauth_nonce
	 - QP70eNmVz8jvdPevU3oJD2AfF7R7odC2XJcn4XlZJqk
	 oauth_signature_method
	 - HMAC-SHA1
	 oauth_timestamp
	 - 1272323042
	 oauth_version
	 - 1.0*/
	
	/*	Authorization: OAuth realm="", oauth_nonce="92673243246",
	 oauth_timestamp="12642432725", oauth_consumer_key="9874239869",
	 oauth_signature_method="HMAC-SHA1", oauth_version="1.0",
	 oauth_signature="l%2FXBqib2y423432LCYwby3kCk%3D"*/
	
	DTOAuthSignature *signature = [[DTOAuthSignature alloc] init];
	signature.secret = self.consumerKey;
	signature.text = @"";
	
	NSMutableString *oauthString = [NSMutableString stringWithFormat:@"Authorization: OAuth realm="", "];
	
	[oauthString appendString:[self nonceString]];
	[oauthString appendString:@", "];
	[oauthString appendString:[self timestampString]];
	[oauthString appendString:@", "];
	[oauthString appendString:[self consumerKeyString]];
	[oauthString appendString:@", "];
	[oauthString appendString:[self signatureMethodStringForMethod:[signature typeString]]];
	[oauthString appendString:@", "];
	[oauthString appendString:[self versionString]];
	[oauthString appendString:@", "];
	[oauthString appendString:[self stringForKey:DTOAuthSignatureKey value:signature.signature]];
	
	NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), oauthString);
	
	return r;
}

- (NSString *)versionString {
	return [self stringForKey:DTOAuthVersionKey value:self.version];
}
- (NSString *)nonceString {
	return [self stringForKey:DTOAuthNonceKey value:self.nonce];
}
- (NSString *)consumerKeyString {
	return [self stringForKey:DTOAuthConsumerKeyKey	value:self.consumerKey];
}
- (NSString *)signatureMethodStringForMethod:(NSString *)method {
	return [self stringForKey:DTOAuthSignatureMethodKey	value:method];
}
- (NSString *)timestampString {
	return [self stringForKey:DTOAuthTimestampKey value:[NSString stringWithFormat:@"%d", [[NSDate date] timeIntervalSince1970]]];
}
- (NSString *)stringForKey:(NSString *)key value:(NSString *)value {
	return [NSString stringWithFormat:@"%@=\"%@\", ", key, value];
}

@end
