//
//  DTOAuthRequestTokenConnection.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthRequestTokenConnection.h"
#import "DTOAuthSignature.h"
#import "NSString+DTURLEncoding.h"

NSString *const DTOAuthCallBackKey = @"oauth_callback";
NSString *const DTOAuthConsumerKeyKey = @"oauth_consumer_key";
NSString *const DTOAuthNonceKey = @"oauth_nonce";
NSString *const DTOAuthSignatureMethodKey = @"oauth_signature_method";
NSString *const DTOAuthTimestampKey = @"oauth_timestamp";
NSString *const DTOAuthVersionKey = @"oauth_version";
NSString *const DTOAuthSignatureKey = @"oauth_signature";

@implementation DTOAuthRequestTokenConnection

@synthesize secretConsumerKey;

- (id)init {
	if (!(self = [super init])) return nil;
	
	NSArray *theKeys = [NSArray arrayWithObjects:DTOAuthConsumerKeyKey, DTOAuthNonceKey, DTOAuthSignatureMethodKey, DTOAuthTimestampKey, DTOAuthVersionKey, nil];
	keys = [[theKeys sortedArrayUsingSelector:@selector(compare:)] retain];
	
	dictionary = [[NSMutableDictionary alloc] init];
	
	for (NSString *key in keys)
		[dictionary setObject:@"" forKey:key];
	
	self.nonce = [[NSProcessInfo processInfo] globallyUniqueString];
	self.version = @"1.0";
	
	return self;
}

- (void)dealloc {
	[keys release];
	[dictionary release];
	[super dealloc];
}

- (void)setNonce:(NSString *)s {
	[dictionary setObject:s forKey:DTOAuthNonceKey];
}
- (NSString *)nonce {
	return [dictionary objectForKey:DTOAuthNonceKey];
}

- (void)setVersion:(NSString *)s {
	[dictionary setObject:s forKey:DTOAuthVersionKey];
}
- (NSString *)version {
	return [dictionary objectForKey:DTOAuthVersionKey];
}
- (void)setConsumerKey:(NSString *)s {
	[dictionary setObject:s forKey:DTOAuthConsumerKeyKey];
}
- (NSString *)consumerKey {
	return [dictionary objectForKey:DTOAuthConsumerKeyKey];
}

- (NSMutableURLRequest *)newRequest {
	self.type = DTConnectionTypeGet;
	
	NSMutableString *urlString = [[NSMutableString alloc] init];
	
	[urlString appendString:@"https://api.twitter.com/oauth/request_token"];
	
	NSMutableURLRequest *r = [super newRequest];
	
	[r setURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"]];
	
	DTOAuthSignature *signature = [[DTOAuthSignature alloc] init];
	signature.secret = [NSString stringWithFormat:@"%@&", self.secretConsumerKey];
	[dictionary setObject:[signature typeString] forKey:DTOAuthSignatureMethodKey];
	[dictionary setObject:[NSString stringWithFormat:@"%d", [[NSDate date] timeIntervalSince1970]] forKey:DTOAuthTimestampKey];
	NSMutableString *baseString = [[NSMutableString alloc] init];
	[baseString appendString:DTConnectionTypeString[self.type]];
	[baseString appendString:@"&"];
	[baseString appendString:[urlString dt_urlEncodedString]];
	[baseString appendString:@"&"];
	
	for (NSString *key in keys) {
		if (!([keys indexOfObject:key]==0)) [baseString appendString:[[NSString stringWithString:@"&"] dt_urlEncodedString]];
		[baseString appendString:[[self baseStringForKey:key value:[dictionary valueForKey:key]] dt_urlEncodedString]];
	}
	signature.text = baseString;
	
	NSMutableString *oauthString = [NSMutableString stringWithFormat:@"OAuth realm=\"\", "];
	
	[urlString appendString:@"?"];
	
	for (NSString *key in keys) {
		[oauthString appendString:[self stringForKey:key value:[dictionary objectForKey:key]]];
		[oauthString appendString:@", "];
		[urlString appendFormat:@"%@=%@&", key, [dictionary objectForKey:key]];
	}
	[oauthString appendString:[self stringForKey:DTOAuthSignatureKey value:signature.signature]];
	[urlString appendFormat:@"%@=%@", DTOAuthSignatureKey, signature.signature];
	[r setURL:[NSURL URLWithString:urlString]];
	[r addValue:oauthString forHTTPHeaderField:@"Authorization"];
	
	return r;
}

- (void)receivedResponse:(NSURLResponse *)response {
	
	NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
	NSLog(@"%@", [r allHeaderFields]);
	[super receivedResponse:response];
}
										  
- (void)receivedObject:(NSObject *)object {
	NSString *string = [[NSString alloc] initWithData:(NSData *)object encoding:NSUTF8StringEncoding];
	NSLog(@"%@", string);
	[super receivedObject:object];
}

- (NSString *)stringForKey:(NSString *)key value:(NSString *)value {
	return [NSString stringWithFormat:@"%@=\"%@\"", key, value];
}

- (NSString *)baseStringForKey:(NSString *)key value:(NSString *)value {
 return [NSString stringWithFormat:@"%@=%@", key, value];
}
@end
