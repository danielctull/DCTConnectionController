//
//  DTOAuthRequestTokenConnection.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthRequestTokenConnection.h"

@implementation DTOAuthRequestTokenConnection

- (id)init {
	if (!(self = [super init])) return nil;
	
	NSArray *keys = [NSArray arrayWithObjects:DTOAuthConsumerKeyKey, DTOAuthNonceKey, DTOAuthSignatureMethodKey, DTOAuthTimestampKey, DTOAuthVersionKey, nil];
	
	parameters = [[NSMutableDictionary alloc] init];
	
	for (NSString *key in keys) [self setValue:@"" forParameter:key];
	
	return self;
}

@end
