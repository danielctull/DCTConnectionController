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

@interface DTOAuthRequestTokenConnection ()
- (NSString *)dt_stringForKey:(NSString *)key value:(NSString *)value;
- (NSString *)dt_baseStringForKey:(NSString *)key value:(NSString *)value;
@end


@implementation DTOAuthRequestTokenConnection

@synthesize secretConsumerKey, URL=d;

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

- (NSMutableURLRequest *)newRequest {
	self.type = DTConnectionTypeGet;
	
	NSMutableURLRequest *r = [super newRequest];
	
	[r setURL:[NSURL URLWithString:@"http://api.twitter.com/oauth/request_token"]];
	
	// Setting up the signature.
	DTOAuthSignature *signature = [[DTOAuthSignature alloc] init];
	signature.secret = [NSString stringWithFormat:@"%@&", self.secretConsumerKey];
	
	[dictionary setObject:[signature typeString] forKey:DTOAuthSignatureMethodKey];
	
	NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
	NSInteger timeStamp = (NSInteger)timeInterval;
	
	[dictionary setObject:[NSString stringWithFormat:@"%i", timeStamp] forKey:DTOAuthTimestampKey];
	NSMutableString *baseString = [[NSMutableString alloc] init];
	[baseString appendString:DTConnectionTypeString[self.type]];
	[baseString appendString:@"&"];
	[baseString appendString:[[r.URL absoluteString] dt_urlEncodedString]];
	[baseString appendString:@"&"];
	
	for (NSString *key in keys) {
		if (!([keys indexOfObject:key]==0)) 
			[baseString appendString:[[NSString stringWithString:@"&"] dt_urlEncodedString]];
		
		[baseString appendString:[[self dt_baseStringForKey:key value:[dictionary valueForKey:key]] dt_urlEncodedString]];
	}
	signature.text = baseString;
	
	
	// Setting up the header string.
	
	NSMutableString *oauthString = [NSMutableString stringWithFormat:@"OAuth realm=\"\", "];
	
	for (NSString *key in keys) {
		[oauthString appendString:[self dt_stringForKey:key value:[dictionary objectForKey:key]]];
		[oauthString appendString:@", "];
	}
	
	[oauthString appendString:[self dt_stringForKey:DTOAuthSignatureKey value:signature.signature]];
	
	[r addValue:oauthString forHTTPHeaderField:@"Authorization"];
	/*
	NSLog(@"%@", dictionary);
	NSLog(@"%@ = %@", DTOAuthSignatureKey, signature.signature);
	
	NSLog(@"Authorization: %@", oauthString);
	NSLog(@"base string = %@", baseString);
	*/
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

- (NSString *)dt_stringForKey:(NSString *)key value:(NSString *)value {
	return [NSString stringWithFormat:@"%@=\"%@\"", key, value];
}

- (NSString *)dt_baseStringForKey:(NSString *)key value:(NSString *)value {
 return [NSString stringWithFormat:@"%@=%@", key, value];
}
@end
