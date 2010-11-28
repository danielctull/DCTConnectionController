//
//  DCTRESTController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 08/08/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DCTRESTController.h"
#import <objc/runtime.h>
#import "NSString+DTURLEncoding.h"

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

- (NSMutableURLRequest *)newRequest {
	
	NSMutableURLRequest *request = [super newRequest];
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
		return [NSString stringWithFormat:@"%@=%@", key, [value dt_urlEncodedString]];
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
	
	return request;	
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
