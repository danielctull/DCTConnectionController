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
#import "DTConnectionQueue.h"

NSString *const DTCacheURLProtocolString = @"dtcache";

static NSMutableArray *consultedAboutURLs = nil;

@implementation DTCacheURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	
	if (!consultedAboutURLs) consultedAboutURLs = [[NSMutableArray alloc] init];
	
	NSString *urlString = [[request URL] absoluteString];
	
	if ([consultedAboutURLs containsObject:urlString]) return NO;
	
	if ([urlString hasSuffix:@"jpg"] || [urlString hasSuffix:@"gif"] || [urlString hasSuffix:@"png"] || [urlString hasSuffix:@"jpeg"])
		return YES;
	
	return NO;
}

- (void)stopLoading {
}

- (void)startLoading {
		
	NSString *urlStringToLoad = [[[self request] URL] absoluteString];
		
	NSData *data = [DTFileCache dataForKey:urlStringToLoad];
	
	NSURLResponse *response = nil;
	NSError *error = nil;
	
	if (!data) {
		DTConnectionQueue *connectionQueue = [DTConnectionQueue sharedConnectionQueue];
		
		[consultedAboutURLs addObject:urlStringToLoad];
		[connectionQueue incrementExternalConnectionCount];
		data = [NSURLConnection sendSynchronousRequest:[self request] returningResponse:&response error:&error];		
		[connectionQueue decrementExternalConnectionCount];
		[consultedAboutURLs removeObject:urlStringToLoad];
		
		[response retain];
		
		[DTFileCache setData:data forKey:urlStringToLoad];
	}
	
	response = [[NSURLResponse alloc] initWithURL:nil MIMEType:@"" expectedContentLength:-1 textEncodingName:nil];
	
	[[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];	

	[response release];
		
	if (error) 
		[[self client] URLProtocol:self didFailWithError:error];
	else
		[[self client] URLProtocol:self didLoadData:data];
	
	[[self client] URLProtocolDidFinishLoading:self];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

@end

