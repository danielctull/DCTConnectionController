//
//  NSURL+DomainString.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 21.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "NSURL+DomainString.h"

@implementation NSURL (DomainString)

- (NSString *)domainString {
	NSString *urlString = [self absoluteString];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"www." withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".com/" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".co.uk/" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".com" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".co.uk" withString:@""];
	return urlString;
	
}

@end
