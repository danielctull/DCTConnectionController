//
//  DTGenericRestCommand.m
//  Tesco
//
//  Created by Daniel Tull on 07.10.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import "DTGenericRestCommand.h"


@implementation DTGenericRestCommand

- (id)initWithDelegate:(NSObject<DTRestCommandDelegate> *)aDelegate urlString:(NSString *)aUrlString {
	
	if (!(self = [super initWithDelegate:aDelegate type:DTRestCommandTypeGet])) return nil;
	
	urlString = [aUrlString copy];
	
	[self startRequest];
	
	return self;
	
}

- (void)dealloc {
	[urlString release];
	[super dealloc];
}

+ (DTGenericRestCommand *)restCommandWithDelegate:(NSObject<DTRestCommandDelegate> *)aDelegate urlString:(NSString *)aUrlString {
	return [[[DTGenericRestCommand alloc] initWithDelegate:aDelegate urlString:aUrlString] autorelease];
}

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [super newRequest];
	[request setURL:[NSURL URLWithString:urlString]];
	return request;
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connectionDidFinishLoading:(DTURLConnection *)connection {
	[self sendObjectToDelegate:connection.data];
}

@end
