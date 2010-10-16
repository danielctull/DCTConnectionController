//
//  DTOAuthConnectionController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthConnectionController.h"
#import "NSString+DTURLEncoding.h"

NSString *const DTOAuthCallBackKey = @"oauth_callback";
NSString *const DTOAuthConsumerKeyKey = @"oauth_consumer_key";
NSString *const DTOAuthNonceKey = @"oauth_nonce";
NSString *const DTOAuthSignatureMethodKey = @"oauth_signature_method";
NSString *const DTOAuthTimestampKey = @"oauth_timestamp";
NSString *const DTOAuthVersionKey = @"oauth_version";
NSString *const DTOAuthSignatureKey = @"oauth_signature";
NSString *const DTOAuthTokenKey = @"oauth_token";
NSString *const DTOAuthTokenSecretKey = @"oauth_token_secret";
NSString *const DTOAuthVerifierKey = @"oauth_verifier";


@interface DTOAuthConnectionController ()
- (NSString *)dt_stringForKey:(NSString *)key value:(NSString *)value;
- (NSString *)dt_baseStringForKey:(NSString *)key value:(NSString *)value;
@end

@implementation DTOAuthConnectionController

@synthesize secretConsumerKey, secretToken, URL=mutableURL;

- (id)init {
	if (!(self = [super init])) return nil;
	
	parameters = [[NSMutableDictionary alloc] init];
	
	self.nonce = [[NSProcessInfo processInfo] globallyUniqueString];
	self.version = @"1.0";
	
	return self;
}

- (void)dealloc {
	[parameters release];
	[super dealloc];
}

- (DCTOAuthSignature *)signature {
	return [[[DCTOAuthSignature alloc] init] autorelease];
}

- (NSMutableURLRequest *)newRequest {
	
	NSMutableURLRequest *request = [super newRequest];
	
	[request setURL:self.URL];
	
	// Setting up the signature.
	DCTOAuthSignature *signature = [self signature];
	
	if (!self.secretToken) self.secretToken = @"";
	if (!self.secretConsumerKey) self.secretConsumerKey = @"";
	
	signature.secret = [NSString stringWithFormat:@"%@&%@", self.secretConsumerKey, self.secretToken];
	
	[parameters setObject:[signature typeString] forKey:DTOAuthSignatureMethodKey];
	
	NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
	NSInteger timeStamp = (NSInteger)timeInterval;
	
	[parameters setObject:[NSString stringWithFormat:@"%i", timeStamp] forKey:DTOAuthTimestampKey];
	NSMutableString *baseString = [[NSMutableString alloc] init];
	[baseString appendString:DCTConnectionControllerTypeString[self.type]];
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
	
	/*NSLog(@"%@ %@", [self class], parameters);
	NSLog(@"%@ %@\n", [self class], signature.signature);
	NSLog(@"%@ \n\n%@\n\n", [self class], baseString);
	*/
	return request;
}

- (void)receivedResponse:(NSURLResponse *)response {
	//NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
	//NSLog(@"%@ %@", [self class], [r allHeaderFields]);
	[super receivedResponse:response];
}

- (void)receivedObject:(NSObject *)object {
	
	if (![object isKindOfClass:[NSData class]]) return;
	
	NSString *string = [[[NSString alloc] initWithData:(NSData *)object encoding:NSUTF8StringEncoding] autorelease];
	//NSLog(@"%@ %@", [self class], string);
	
	NSDictionary *d = [DTOAuthConnectionController oauthDictionaryFromString:string];
	
	if (!d) {
		[self receivedError:nil];
		return;
	}
	
	[self receivedOAuthDictionary:d];
	[super receivedObject:d];
}

+ (NSDictionary *)oauthDictionaryFromString:(NSString *)string {
	
	NSArray *parts = [string componentsSeparatedByString:@"&"];
	
	if ([parts count] == 0) return nil;
	
	NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
	
	for (NSString *s in parts) {
		NSArray *p = [s componentsSeparatedByString:@"="];
		
		if ([p count] == 2) [dict setObject:[p objectAtIndex:1] forKey:[p objectAtIndex:0]];
	}
	
	if ([[dict allKeys] count] == 0) return nil;
	
	return dict;
	
}

#pragma mark -
#pragma mark Accessor methods

- (void)setValue:(NSString *)value forParameter:(NSString *)parameterName {
	
	if ([value isEqualToString:@""] && [[parameters allKeys] containsObject:parameterName]) return;
	
	//NSLog(@"%@:%@", parameterName, value);
	
	[parameters setObject:value forKey:parameterName];
}
- (NSString *)valueForParameter:(NSString *)parameterName {
	return [parameters objectForKey:parameterName];
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
#pragma mark -
#pragma mark Private methods

- (NSString *)dt_stringForKey:(NSString *)key value:(NSString *)value {
	return [NSString stringWithFormat:@"%@=\"%@\"", key, value];
}

- (NSString *)dt_baseStringForKey:(NSString *)key value:(NSString *)value {
	return [NSString stringWithFormat:@"%@=%@", key, value];
}

- (void)receivedOAuthDictionary:(NSDictionary *)dictionary {}

@end
