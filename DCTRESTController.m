/*
 DCTRESTController.m
 DCTConnectionController
 
 Created by Daniel Tull on 8.8.2010.
 
 
 
 Copyright (c) 2010 Daniel Tull. All rights reserved.
 
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

#import "DCTRESTController.h"
#import <objc/runtime.h>
#import "NSString+DCTURLEncoding.h"

typedef id (^DCTInternalRESTControllerKeyValueStringConvertor) (id, id);

@interface DCTRESTController ()
- (NSArray *)dctInternal_keyValueStringsForKeys:(NSSet *)keys stringConvertor:(DCTInternalRESTControllerKeyValueStringConvertor)convertor;
@end

@implementation DCTRESTController

+ (NSArray *)headerProperties {
	return nil;
}

+ (NSArray *)bodyProperties {
	return nil;
}

+ (NSArray *)queryProperties {
	return nil;
}

- (NSString *)baseURLString {
	return @"";	
}

- (void)loadURLRequest {
	
	[super loadURLRequest];
	
	NSMutableURLRequest *request = [self.URLRequest mutableCopy];
	NSMutableSet *queries = [NSMutableSet set];
	NSMutableSet *bodies = [NSMutableSet set];
	NSMutableSet *headers = [NSMutableSet set];
	
	Class class = [self class];
	while ([class isSubclassOfClass:[DCTRESTController class]] && ![[DCTRESTController class] isSubclassOfClass:class]) {
		
		NSArray *classQueries = [class queryProperties];
		if (classQueries) [queries addObjectsFromArray:classQueries];
		
		NSArray *classBodies = [class bodyProperties];		
		if (classBodies) [bodies addObjectsFromArray:classBodies];
		
		NSArray *classHeaders = [class headerProperties];
		if (classHeaders) [headers addObjectsFromArray:classHeaders];
		
		class = class_getSuperclass(class);
	}
	
	DCTInternalRESTControllerKeyValueStringConvertor convertor = ^(id key, id value) {
		return [NSString stringWithFormat:@"%@=%@", key, [value dct_urlEncodedString]];
	};
	
	if ([queries count] == 0) {
		[request setURL:[NSURL URLWithString:[self baseURLString]]];
	} else {
		NSArray *queryKeyValues = [self dctInternal_keyValueStringsForKeys:queries stringConvertor:convertor];	
		NSString *queryString = [queryKeyValues componentsJoinedByString:@"&"];
		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [self baseURLString], queryString]]];
	}
	
	NSArray *bodyKeyValues = [self dctInternal_keyValueStringsForKeys:bodies stringConvertor:convertor];
	NSString *bodyString = [bodyKeyValues componentsJoinedByString:@"&"];
	[request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
		
	[self dctInternal_keyValueStringsForKeys:headers stringConvertor:^(id key, id value){
		[request addValue:value forHTTPHeaderField:key];
		return [NSString stringWithFormat:@"%@: %@", key, value];
	}];
	
	self.URLRequest = request;
}

- (NSArray *)dctInternal_keyValueStringsForKeys:(NSSet *)keys stringConvertor:(DCTInternalRESTControllerKeyValueStringConvertor)convertor {
	
	NSMutableArray *strings = [NSMutableArray arrayWithCapacity:[keys count]];
	
	for (NSString *key in keys) {
		
		id value = [self valueForKey:key];
				
		if (value && [value isKindOfClass:[NSString class]])
			[strings addObject:convertor(key, value)];
	}
	return [NSArray arrayWithArray:strings];
}
		 


@end
