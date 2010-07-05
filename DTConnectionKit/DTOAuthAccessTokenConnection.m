//
//  DTOAuthAccessTokenConnection.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthAccessTokenConnection.h"


@implementation DTOAuthAccessTokenConnection

- (id)init {
	if (!(self = [super init])) return nil;
	
	NSArray *keys = [NSArray arrayWithObjects:DTOAuthConsumerKeyKey, DTOAuthNonceKey, DTOAuthSignatureMethodKey, DTOAuthTimestampKey, DTOAuthVersionKey, DTOAuthVerifierKey, DTOAuthTokenKey, nil];
	
	parameters = [[NSMutableDictionary alloc] init];
	
	for (NSString *key in keys) [self setValue:@"" forParameter:key];
	
	return self;
}

#pragma mark -
#pragma mark Accessor methods

- (void)setToken:(NSString *)s {
	[parameters setObject:s forKey:DTOAuthTokenKey];
}
- (NSString *)token {
	return [parameters objectForKey:DTOAuthTokenKey];
}
- (void)setVerifier:(NSString *)s {
	[parameters setObject:s forKey:DTOAuthVerifierKey];
}
- (NSString *)verifier {
	return [parameters objectForKey:DTOAuthVerifierKey];
}

@end
