/*
 DCTURLConnection.m
 DCTConnectionController
 
 Created by Daniel Tull on 3.3.2009.
 
 
 
 Copyright (c) 2009 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DCTURLConnection.h"

@interface DCTURLConnection ()
@property (readwrite, copy) NSData *data;
@property (readwrite, copy) NSString *identifier;
@end

@implementation DCTURLConnection

@synthesize data, identifier, URL;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately {
	
	if (!(self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately])) return nil;
	
	data = [[NSData alloc] init];
	self.identifier = [[NSProcessInfo processInfo] globallyUniqueString];
	URL = [request URL];
		
	return self;
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate identifier:(NSString *)anIdentifier {
	if (!(self = [self initWithRequest:request delegate:delegate startImmediately:YES])) return nil;
	
	if (anIdentifier) self.identifier = anIdentifier;
	
	return self;
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate {
	return [self initWithRequest:request delegate:delegate startImmediately:YES];
}

+ (id)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate {
	return [[DCTURLConnection alloc] initWithRequest:request delegate:delegate];
}


- (void)resetDataLength {
	NSMutableData *mData = [self.data mutableCopy];
	[mData setLength:0];
	self.data = mData;
}

- (void)appendData:(NSData *)someData {
	NSMutableData *mData = [self.data mutableCopy];
	[mData appendData:someData];
	self.data = (NSData *)mData;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ id:%@ url:%@>", [self class], self.identifier, self.URL];
}

- (NSObject *)copyWithZone:(NSObject *)ob {
	return nil;
}

@end
