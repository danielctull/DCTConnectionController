//
//  DTCacheURLProtocol.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.02.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTCacheURLProtocol.h"
#import "DTFileCache.h"
#import "DTURLLoadingConnection.h"

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
	
	if (data) {
	
		NSURLResponse *response = [[NSURLResponse alloc] initWithURL:nil MIMEType:@"" expectedContentLength:-1 textEncodingName:nil];
		
		[[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
		
		[response release];
		
		[[self client] URLProtocol:self didLoadData:data];
		
		[[self client] URLProtocolDidFinishLoading:self];
		
		return;	
	}
	
	
	DTURLLoadingConnection *connection = [[DTURLLoadingConnection alloc] init];
	connection.URL = [NSURL URLWithString:urlStringToLoad];
	[connection connect];
	[connection release];	
	
	NSPort *aPort = [NSPort port];
	NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    [currentRunLoop addPort:aPort forMode:NSRunLoopCommonModes];
    
	while (!connectionHasReturned)
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	NSString *newURLString = [NSString stringWithFormat:@"http:%@", [[request URL] resourceSpecifier]];
	NSURL *newURL = [NSURL URLWithString:newURLString];
	
	NSURLRequest *newRequest = [[NSURLRequest alloc] initWithURL:newURL];
	
	return [newRequest autorelease];
}


#pragma mark -
#pragma mark DTConnection delegates

- (void)dtconnection:(DTConnection *)connection didSucceedWithObject:(NSObject *)object {
	
	if (![object isKindOfClass:[NSData class]]) return;
	
	NSData *data = (NSData *)object;
	
	[[self client] URLProtocol:self didLoadData:data];
	
	connectionHasReturned = YES;
}

- (void)dtconnection:(DTConnection *)connection didFailWithError:(NSError *)error {
	[[self client] URLProtocol:self didFailWithError:error];
}

- (void)dtconnection:(DTConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}


@end

