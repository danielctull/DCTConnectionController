//
//  DTOAuthConnectionController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTOAuthConnectionController.h"
#import "NSString+DTURLEncoding.h"

NSString *const DCTOAuthCallBackKey = @"oauth_callback";
NSString *const DCTOAuthConsumerKeyKey = @"oauth_consumer_key";
NSString *const DCTOAuthNonceKey = @"oauth_nonce";
NSString *const DCTOAuthSignatureMethodKey = @"oauth_signature_method";
NSString *const DCTOAuthTimestampKey = @"oauth_timestamp";
NSString *const DCTOAuthVersionKey = @"oauth_version";
NSString *const DCTOAuthSignatureKey = @"oauth_signature";
NSString *const DCTOAuthTokenKey = @"oauth_token";
NSString *const DCTOAuthVerifierKey = @"oauth_token_secret";
NSString *const DTOAuthVerifierKey = @"oauth_verifier";


@interface DCTOAuthConnectionController ()
- (NSString *)dt_stringForKey:(NSString *)key value:(NSString *)value;
- (NSString *)dt_baseStringForKey:(NSString *)key value:(NSString *)value;
- (NSString *)dctInternal_authorizationHeader;
- (NSArray *)dctInternal_sortedParameterKeys;
- (NSString *)dctInternal_baseSignatureString;
@property (nonatomic, readonly) NSDictionary *dctInternal_parameters;
@end

@implementation DCTOAuthConnectionController

@synthesize nonce, consumerKey, secretConsumerKey, secretToken, version, timestamp, token;

#pragma mark -
#pragma mark NSObject

- (id)init {
	if (!(self = [super init])) return nil;
		
	self.consumerKey = @"";
	self.token = @"";
	self.secretToken = @"";
	self.secretConsumerKey = @"";
	self.nonce = [[NSProcessInfo processInfo] globallyUniqueString];
	self.version = @"1.0";
	
	NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
	NSInteger timeInteger = (NSInteger)timeInterval;
	timestamp = [[NSString stringWithFormat:@"%i", timeInteger] copy];
	
	return self;
}

- (void)dealloc {
	[timestamp release];
	[oauthParameters release];
	[super dealloc];
}

#pragma mark -
#pragma mark DCTConnectionController

- (void)receivedObject:(NSObject *)object {
	
	if (![object isKindOfClass:[NSData class]]) return [super receivedObject:object];
	
	NSString *string = [[[NSString alloc] initWithData:(NSData *)object encoding:NSUTF8StringEncoding] autorelease];
	
	NSDictionary *d = [DCTOAuthConnectionController oauthDictionaryFromString:string];
	
	if (!d) return [super receivedObject:object];
	
	[self receivedOAuthDictionary:d];
	[super receivedObject:object];
}

+ (NSArray *)queryProperties {
	return nil;
}

+ (NSArray *)bodyProperties {
	return nil;
}

+ (NSArray *)headerProperties {
	return [NSArray arrayWithObject:@"Authorization"];
}


#pragma mark -
#pragma mark DCTOAuthConnectionController

- (DCTOAuthSignature *)signature {
	
	if (!signature) {
		signature = [[DCTOAuthSignature alloc] init];
		signature.secret = [NSString stringWithFormat:@"%@&%@", self.secretConsumerKey, self.secretToken];
		signature.text = [self dctInternal_baseSignatureString];
	}
	
	return [[signature retain] autorelease];
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

+ (NSArray *)oauthProperties {
	return nil;
}

- (id)valueForKey:(NSString *)key {
	
	if ([key isEqualToString:@"Authorization"])
		return [self dctInternal_authorizationHeader];
	
	return [super valueForKey:key];	
}

- (void)receivedOAuthDictionary:(NSDictionary *)dictionary {}

#pragma mark -
#pragma mark Internal methods

- (NSString *)dt_stringForKey:(NSString *)key value:(NSString *)value {
	return [NSString stringWithFormat:@"%@=\"%@\"", key, value];
}

- (NSString *)dt_baseStringForKey:(NSString *)key value:(NSString *)value {
	return [NSString stringWithFormat:@"%@=%@", key, value];
}

- (NSString *)dctInternal_authorizationHeader {
	
	NSMutableArray *authorizationArray = [NSMutableArray arrayWithCapacity:7];
	
	[authorizationArray addObject:[self dt_baseStringForKey:@"OAuth realm" value:[self baseURLString]]];
	
	NSDictionary *parameters = [self dctInternal_parameters];
	
	for (NSString *key in [self dctInternal_sortedParameterKeys]) {
		
		NSString *s = [self dt_stringForKey:key value:[parameters objectForKey:key]];
		[authorizationArray addObject:s];
	}
	
	[authorizationArray addObject:[self dt_stringForKey:DCTOAuthSignatureKey value:self.signature.signature]];
	
	return [authorizationArray componentsJoinedByString:@", "];	
}

- (NSDictionary *)dctInternal_parameters {
	
	if (!oauthParameters) {
		NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:7];
		
		[d setObject:self.consumerKey forKey:DCTOAuthConsumerKeyKey];
		[d setObject:self.token forKey:DCTOAuthTokenKey];
		[d setObject:self.nonce forKey:DCTOAuthNonceKey];
		[d setObject:self.timestamp forKey:DCTOAuthTimestampKey];
		[d setObject:self.signature.method forKey:DCTOAuthSignatureMethodKey];
		[d setObject:self.version forKey:DCTOAuthVersionKey];
		
		Class class = [self class];
		while ([class isSubclassOfClass:[DCTOAuthConnectionController class]] && ![[DCTOAuthConnectionController class] isSubclassOfClass:class]) {
			for (NSString *key in [class oauthProperties])
				[d setObject:[self valueForKey:key] forKey:key];
			
			class = [class superclass];
		}
		
		oauthParameters = [[NSDictionary alloc] initWithDictionary:d];
	}
	
	return oauthParameters;
}

- (NSArray *)dctInternal_sortedParameterKeys {
	return [[[self dctInternal_parameters] allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSString *)dctInternal_coreOAuthString {
	
	NSMutableArray *coreArray = [NSMutableArray arrayWithCapacity:7];
	
	NSDictionary *params = [self dctInternal_parameters];
	NSArray *keys = [[params allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	for (NSString *key in keys)
		[coreArray addObject:[self dt_baseStringForKey:key value:[params valueForKey:key]]];
	
	return [coreArray componentsJoinedByString:@"&"];
}

- (NSString *)dctInternal_baseSignatureString {
	
	NSMutableArray *baseArray = [NSMutableArray arrayWithCapacity:3];
	
	[baseArray addObject:[DCTConnectionControllerTypeString[self.type] dt_urlEncodedString]];
	[baseArray addObject:[[self baseURLString] dt_urlEncodedString]];
	[baseArray addObject:[[self dctInternal_coreOAuthString] dt_urlEncodedString]];
	
	NSLog(@"%@:%@ BASE STRING: \n\n%@\n\n", self, NSStringFromSelector(_cmd), [baseArray componentsJoinedByString:@"&"]);
	
	return [baseArray componentsJoinedByString:@"&"];
}

@end
