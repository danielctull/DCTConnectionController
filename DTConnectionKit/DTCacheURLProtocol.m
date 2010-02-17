//
//  DTCacheURLProtocol.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.02.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTCacheURLProtocol.h"
#import "DTFileCache.h"

NSString *const DTCacheURLProtocolString = @"dtcache";

@implementation DTCacheURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	
	if ([[[request URL] scheme] hasPrefix:DTCacheURLProtocolString]) 
		return YES; 
	
	return NO;
}

- (void)stopLoading {
}

- (void)startLoading {
	
	NSURL *URL = [[self request] URL];
	
	NSString *urlStringToLoad = [NSString stringWithFormat:@"http:%@", [URL resourceSpecifier]];
	
	NSData *data = [DTFileCache dataForKey:urlStringToLoad];
	
	NSURLResponse *response = nil;
	
	if (!data) {
		NSURL *url = [NSURL URLWithString:urlStringToLoad];
		
		NSURLRequest *r = [NSURLRequest requestWithURL:url];
		data = [NSURLConnection sendSynchronousRequest:r returningResponse:&response error:nil];
		
		[response retain];
		
		[DTFileCache setData:data forKey:urlStringToLoad];
		
	}
	
	if (!response)
		response = [[NSURLResponse alloc] initWithURL:nil MIMEType:@"" expectedContentLength:-1 textEncodingName:nil];
	
	[[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
	
	[response release];
	
	[[self client] URLProtocol:self didLoadData:data];
	
	[[self client] URLProtocolDidFinishLoading:self];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	NSString *newURLString = [NSString stringWithFormat:@"http:%@", [[request URL] resourceSpecifier]];
	NSURL *newURL = [NSURL URLWithString:newURLString];
	
	NSURLRequest *newRequest = [[NSURLRequest alloc] initWithURL:newURL];
	
	return [newRequest autorelease];
}

@end

