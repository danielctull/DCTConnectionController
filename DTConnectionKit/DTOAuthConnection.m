//
//  DTOAuthConnection.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthConnection.h"

NSString *const DTOAuthCallBackKey = @"oauth_callback";
NSString *const DTOAuthConsumerKeyKey = @"oauth_consumer_key";
NSString *const DTOAuthNonceKey = @"oauth_nonce";
NSString *const DTOAuthSignatureMethodKey = @"oauth_signature_method";
NSString *const DTOAuthTimestampKey = @"oauth_timestamp";
NSString *const DTOAuthVersionKey = @"oauth_version";
NSString *const DTOAuthSignatureKey = @"oauth_signature";

@implementation DTOAuthConnection

@synthesize secretConsumerKey, URL=mutableURL;

- (id)init {
	if (!(self = [super init])) return nil;
	
	NSArray *keys = [NSArray arrayWithObjects:DTOAuthConsumerKeyKey, DTOAuthNonceKey, DTOAuthSignatureMethodKey, DTOAuthTimestampKey, DTOAuthVersionKey, nil];
	
	parameters = [[NSMutableDictionary alloc] init];
	
	for (NSString *key in keys) [parameters setObject:@"" forKey:key];
	
	self.nonce = [[NSProcessInfo processInfo] globallyUniqueString];
	self.version = @"1.0";
	
	return self;
}

- (void)dealloc {
	[parameters release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessor methods

- (void)setValue:(NSString *)value forParameter:(NSString *)parameterName {
	[parameters setObject:value forKey:parameterName];
}
- (void)valueForParameter:(NSString *)parameterName {
	[parameters objectForKey:parameterName];
}

- (void)setNonce:(NSString *)s {
	[parameters setObject:s forKey:DTOAuthNonceKey];
}
- (NSString *)nonce {
	return [parameters objectForKey:DTOAuthNonceKey];
}

- (void)setVersion:(NSString *)s {
	[parameters setObject:s forKey:DTOAuthVersionKey];
}
- (NSString *)version {
	return [parameters objectForKey:DTOAuthVersionKey];
}
- (void)setConsumerKey:(NSString *)s {
	[parameters setObject:s forKey:DTOAuthConsumerKeyKey];
}
- (NSString *)consumerKey {
	return [parameters objectForKey:DTOAuthConsumerKeyKey];
}

@end
