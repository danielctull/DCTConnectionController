//
//  DTRESTController.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 08/08/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DTRESTController.h"


@implementation DTRESTController


- (id)init {
    if (!(self = [super init])) return nil;
	
	queryParameters = [[NSMutableDictionary alloc] init];
	bodyParameters = [[NSMutableDictionary alloc] init];
    
	return self;
}

- (void)dealloc {
    [queryParameters release], queryParameters = nil;
	[bodyParameters release], bodyParameters = nil;
    [super dealloc];
}

- (NSMutableURLRequest *)newRequest {
	
	NSMutableURLRequest *request = [super newRequest];
	
	NSMutableString *url = [[[[self URL] absoluteString] mutableCopy] autorelease];
	
	BOOL firstPass = YES;
	
	for (NSString *key in queryParameters) {
		
		firstPass ? [url appendString:@"?"] : [url appendString:@"&"];
		
		[url appendFormat:@"%@=%@", key, [self queryParameterForKey:key]];
		
		firstPass = NO;
		
	}
	
	NSMutableString *bodyString = [[[NSMutableString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
	
	for (NSString *key in bodyParameters) {
	
		[bodyString length] == 0 ? : [bodyString appendString:@"&"];
		
		[bodyString appendFormat:@"%@=%@", key, [self bodyParameterForKey:key]];
	}
	
	[request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
	
	return request;	
}

- (void)setQueryParameter:(NSString *)parameter forKey:(NSString *)key {
    [queryParameters setObject:parameter forKey:key];
}
- (void)removeQueryParameterForKey:(NSString *)key {
    [queryParameters removeObjectForKey:key];
}
- (NSString *)queryParameterForKey:(NSString *)key {
	return [queryParameters objectForKey:key];
}

- (void)setBodyParameter:(NSString *)parameter forKey:(NSString *)key {
    [bodyParameters setObject:parameter forKey:key];
}
- (NSString *)bodyParameterForKey:(NSString *)key {
	return [bodyParameters objectForKey:key];
}
- (void)removeBodyParameterForKey:(NSString *)key {
    [bodyParameters removeObjectForKey:key];
}

@end
