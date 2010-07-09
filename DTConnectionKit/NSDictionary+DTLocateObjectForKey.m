//
//  NSDictionary+DTLocateObjectForKey.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "NSDictionary+DTLocateObjectForKey.h"

@interface NSArray (DTLocateObjectForKey)
- (NSObject *)dt_locateObjectForKey:(NSObject *)key;
@end

@implementation NSArray (DTLocateObjectForKey)

- (NSObject *)dt_locateObjectForKey:(NSObject *)key {
	
	for (NSObject *o in self) {
		
		if ([o isKindOfClass:[NSDictionary class]]) {
			NSObject *ob = [(NSDictionary *)o dt_locateObjectForKey:key];
			if (ob) return ob;		
		}
		
	}
	return nil;
}

@end




@implementation NSDictionary (DTLocateObjectForKey)

- (NSObject *)dt_locateObjectForKey:(NSObject *)key {
	
	NSObject *o = [self objectForKey:key];
	
	if (o) return o;
	
	for (id k in self) {
		
		o = [self objectForKey:k];
		
		if ([o isKindOfClass:[NSDictionary class]]) {
			NSObject *ob = [self dt_locateObjectForKey:key];
			if (ob) return ob;		
		}
		
		if ([o isKindOfClass:[NSArray class]]) {
			NSObject *ob = [(NSArray *)o dt_locateObjectForKey:key];
			if (ob) return ob;		
		}
	}
	
	return nil;
}

@end
