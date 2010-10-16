//
//  DTOAuthAccessTokenConnection.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthAccessTokenConnectionController.h"


@implementation DTOAuthAccessTokenConnectionController

- (id)init {
	if (!(self = [super init])) return nil;
	
	NSArray *keys = [NSArray arrayWithObjects:DTOAuthConsumerKeyKey, DTOAuthNonceKey, DTOAuthSignatureMethodKey, DTOAuthTimestampKey, DTOAuthVersionKey, DTOAuthTokenKey, nil];
	
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

@end
