//
//  DTURLConnection.m
//	DTKit
//
//  Created by Daniel Tull on 03.03.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import "DTURLConnection.h"

@interface DTURLConnection ()
@property (readwrite, copy) NSData *data;
@end

@implementation DTURLConnection

@synthesize data, identifier, URL;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately {
	
	if (!(self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately]))
		return nil;
	
	data = [[NSData alloc] init];
	
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	identifier = (NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	
	URL = [[request URL] retain];
		
	return self;
	
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate {
	return [self initWithRequest:request delegate:delegate startImmediately:YES];
}

+ (id)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate {
	return [[[DTURLConnection alloc] initWithRequest:request delegate:delegate] autorelease];
}

- (void)dealloc {
    [data release];
    [identifier release];
	[URL release];
    [super dealloc];
}

- (void)resetDataLength {
	NSMutableData *mData = [self.data mutableCopy];
	[mData setLength:0];
	self.data = mData;
	[mData release];
}

- (void)appendData:(NSData *)someData {
	NSMutableData *mData = [self.data mutableCopy];
	[mData appendData:someData];
	self.data = (NSData *)mData;
	[mData release];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<DTURLConnection> (id: %@ url: %@)", self.identifier, self.URL];
}

- (NSObject *)copyWithZone:(NSObject *)ob {
	return nil;
}

@end
