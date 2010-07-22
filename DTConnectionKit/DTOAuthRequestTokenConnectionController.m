//
//  DTOAuthRequestTokenConnectionController.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthRequestTokenConnectionController.h"

@implementation DTOAuthRequestTokenConnectionController

- (id)init {
	if (!(self = [super init])) return nil;
	
	NSArray *keys = [NSArray arrayWithObjects:DTOAuthConsumerKeyKey, DTOAuthNonceKey, DTOAuthSignatureMethodKey, DTOAuthTimestampKey, DTOAuthVersionKey, nil];
	
	for (NSString *key in keys) [self setValue:@"" forParameter:key];
	
	return self;
}

@end
