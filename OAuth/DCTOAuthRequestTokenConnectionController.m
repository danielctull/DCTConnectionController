//
//  DTOAuthRequestTokenConnectionController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTOAuthRequestTokenConnectionController.h"

@implementation DCTOAuthRequestTokenConnectionController

@synthesize callback;

- (id)init {
	if (!(self = [super init])) return nil;
	
	self.callback = @"";
	
	return self;
}

+ (NSArray *)oauthProperties {
	return [NSArray arrayWithObject:DCTOAuthCallBackKey];
}

- (id)valueForKey:(NSString *)key {
	if ([key isEqualToString:DCTOAuthCallBackKey])
		return self.callback;
	
	return [super valueForKey:key];
}

@end
