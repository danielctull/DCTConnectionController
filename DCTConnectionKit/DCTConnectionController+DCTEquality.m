//
//  DCTConnectionController+DCTEquality.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09/11/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController+DCTEquality.h"
#import <objc/runtime.h>

@interface DCTConnectionController ()
- (NSArray *)dctInternal_propertiesOfClass:(Class)class;
- (NSArray *)dctInternal_properties;
@end

@implementation DCTConnectionController (DCTEquality)

- (BOOL)isEqualToConnectionController:(DCTConnectionController *)connectionController {
	
	//if ([self isEqual:connectionController]) return YES;
	
	if (![connectionController isKindOfClass:[self class]]) return NO;
	
	NSArray *properties = [self dctInternal_properties];
	
	for (NSString *key in properties) {
		
		id selfObject = [self valueForKey:key];
		id connectionControllerObject = [connectionController valueForKey:key];
		
		if (![selfObject isEqual:connectionControllerObject]) return NO;
	}
	
	return YES;
}

- (NSArray *)dctInternal_properties {
	
	Class aClass = [self class];
	
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	while ([aClass isSubclassOfClass:[DCTConnectionController class]]
		   && ![DCTConnectionController isSubclassOfClass:aClass]) {
		
		[array addObjectsFromArray:[self dctInternal_propertiesOfClass:aClass]];
		aClass = [aClass superclass];
	}
	
	return [array autorelease];
}

- (NSArray *)dctInternal_propertiesOfClass:(Class)class {
	
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	NSUInteger outCount;
	
	objc_property_t *properties = class_copyPropertyList(class, &outCount);
	
	for (NSUInteger i = 0; i < outCount; i++) {
		objc_property_t property = properties[i];
		const char *propertyName = property_getName(property);
		NSString *nameString = [[[NSString alloc] initWithCString:propertyName] autorelease];
		[array addObject:nameString];
	}
	
	free(properties);
	
	return [array autorelease];
	
}

@end
