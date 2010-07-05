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

- (NSMutableURLRequest *)newRequest {
	
	NSMutableURLRequest *request = [super newRequest];
	
	[request setURL:self.URL];
	
	// Setting up the signature.
	DTOAuthSignature *signature = [[DTOAuthSignature alloc] init];
	signature.secret = [NSString stringWithFormat:@"%@&", self.secretConsumerKey];
	
	[parameters setObject:[signature typeString] forKey:DTOAuthSignatureMethodKey];
	
	NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
	NSInteger timeStamp = (NSInteger)timeInterval;
	
	[parameters setObject:[NSString stringWithFormat:@"%i", timeStamp] forKey:DTOAuthTimestampKey];
	NSMutableString *baseString = [[NSMutableString alloc] init];
	[baseString appendString:DTConnectionTypeString[self.type]];
	[baseString appendString:@"&"];
	[baseString appendString:[[request.URL absoluteString] dt_urlEncodedString]];
	[baseString appendString:@"&"];
	
	NSArray *keys = [[parameters allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	for (NSString *key in keys) {
		
		if ([keys indexOfObject:key]!=0) [baseString appendString:[[NSString stringWithString:@"&"] dt_urlEncodedString]];
		
		[baseString appendString:[[self dt_baseStringForKey:key value:[parameters valueForKey:key]] dt_urlEncodedString]];
	}
	signature.text = baseString;
	
	// Setting up the header string.
	
	NSMutableString *oauthString = [NSMutableString stringWithFormat:@"OAuth realm=\"\", "];
	
	for (NSString *key in keys) {
		[oauthString appendString:[self dt_stringForKey:key value:[parameters objectForKey:key]]];
		[oauthString appendString:@", "];
	}
	[oauthString appendString:[self dt_stringForKey:DTOAuthSignatureKey value:signature.signature]];
	
	[request addValue:oauthString forHTTPHeaderField:@"Authorization"];
	
	return request;
}

- (void)receivedResponse:(NSURLResponse *)response {
	//NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
	//NSLog(@"%@", [r allHeaderFields]);
	[super receivedResponse:response];
}

- (void)receivedObject:(NSObject *)object {
	NSString *string = [[NSString alloc] initWithData:(NSData *)object encoding:NSUTF8StringEncoding];
	
	NSArray *parts = [string componentsSeparatedByString:@"&"];
	
	NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
	
	for (NSString *s in parts) {
		NSArray *p = [s componentsSeparatedByString:@"="];
		
		if ([p count] == 2) [dict setObject:[p objectAtIndex:1] forKey:[p objectAtIndex:0]];
	}
	
	NSLog(@"%@", dict);
	[super receivedObject:dict];
}

#pragma mark -
#pragma mark Accessor methods

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

#pragma mark -
#pragma mark Private methods

- (NSString *)dt_stringForKey:(NSString *)key value:(NSString *)value {
	return [NSString stringWithFormat:@"%@=\"%@\"", key, value];
}

- (NSString *)dt_baseStringForKey:(NSString *)key value:(NSString *)value {
	return [NSString stringWithFormat:@"%@=%@", key, value];
}
@end
