//
//  DCTRESTController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 08/08/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DCTRESTController.h"
#import <objc/runtime.h>

@implementation DCTRESTController

+ (NSArray *)bodyProperties {
	return [NSArray array];
}

+ (NSArray *)queryProperties {
	
	NSUInteger outCount;
	
	objc_property_t *properties = class_copyPropertyList([self class], &outCount);
	
	NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
	
	for (NSUInteger i = 0; i < outCount; i++) {
		objc_property_t property = properties[i];
		const char *propertyName = property_getName(property);
		NSString *nameString = [[[NSString alloc] initWithCString:propertyName] autorelease];
		[array addObject:nameString];
	}
	
	//NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), array);
	
	free(properties);
	
	return array;
}

- (NSString *)baseURLString {
	return @"";	
}

- (NSMutableURLRequest *)newRequest {
	
	NSMutableURLRequest *request = [super newRequest];
	
	NSMutableString *url = [[[self baseURLString] mutableCopy] autorelease];
	
	Class class = [self class];
	
	NSMutableArray *queries = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *bodies = [[[NSMutableArray alloc] init] autorelease];
	
	while ([class isSubclassOfClass:[DCTRESTController class]] && ![[DCTRESTController class] isSubclassOfClass:class]) {
		
		NSArray *classQueries = [class queryProperties];
		if (classQueries)
			[queries addObjectsFromArray:classQueries];
		
		NSArray *classBodies = [class bodyProperties];		
		if (classBodies) 
			[bodies addObjectsFromArray:classBodies];
		
		class = class_getSuperclass(class);
	}
	
	BOOL firstPass = YES;
	
	for (NSString *key in queries) {
		
		id value = [self valueForKey:key];
		
		if (value) {
			
			firstPass ? [url appendString:@"?"] : [url appendString:@"&"];
			
			[url appendFormat:@"%@=%@", key, value];
			
			firstPass = NO;
		}
		
	}
	
	[request setURL:[NSURL URLWithString:url]];
	
	NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), url);
	
	NSMutableString *bodyString = [[[NSMutableString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
	
	for (NSString *key in bodies) {
		
		id value = [self valueForKey:key];
		
		if (value) {
			[bodyString length] == 0 ? : [bodyString appendString:@"&"];
			
			[bodyString appendFormat:@"%@=%@", key, value];
		}
	}
	
	[request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
	
	return request;	
}


@end
