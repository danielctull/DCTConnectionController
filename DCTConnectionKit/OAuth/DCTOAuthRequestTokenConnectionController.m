//
//  DTOAuthRequestTokenConnectionController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTOAuthRequestTokenConnectionController.h"

@implementation DCTOAuthRequestTokenConnectionController

- (id)init {
	if (!(self = [super init])) return nil;
	
	NSArray *keys = [NSArray arrayWithObjects:DCTOAuthConsumerKeyKey, DCTOAuthNonceKey, DCTOAuthSignatureMethodKey, DCTOAuthTimestampKey, DCTOAuthVersionKey, nil];
	
	for (NSString *key in keys) [self setValue:@"" forParameter:key];
	
	return self;
}

@end
