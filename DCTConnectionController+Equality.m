/*
 DCTConnectionController+Equality.m
 DCTConnectionController
 
 Created by Daniel Tull on 9.11.2010.
 
 
 
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

#import "DCTConnectionController+Equality.h"
#import <objc/runtime.h>

@interface DCTConnectionController (EqualityInternal)
- (NSArray *)dctEqualityInternal_propertiesOfClass:(Class)class;
- (NSArray *)dctEqualityInternal_properties;
@end

@implementation DCTConnectionController (Equality)

- (BOOL)isEqualToConnectionController:(DCTConnectionController *)connectionController {
	
	if (![connectionController isKindOfClass:[self class]]) return NO;
	
	if (connectionController.type != self.type) return NO;
	
	if (![connectionController.URL isEqual:self.URL]) return NO;
	
	NSArray *properties = [self dctEqualityInternal_properties];
	
	for (NSString *key in properties) {
		
		id selfObject = [self valueForKey:key];
		id connectionControllerObject = [connectionController valueForKey:key];
		
		if (![selfObject isEqual:connectionControllerObject]) return NO;
	}
	
	return YES;
}

@end

@implementation DCTConnectionController (EqualityInternal)

- (NSArray *)dctEqualityInternal_properties {
	
	Class aClass = [self class];
	
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	while ([aClass isSubclassOfClass:[DCTConnectionController class]]
		   && ![DCTConnectionController isSubclassOfClass:aClass]) {
		
		[array addObjectsFromArray:[self dctEqualityInternal_propertiesOfClass:aClass]];
		aClass = [aClass superclass];
	}
	
	return array;
}

- (NSArray *)dctEqualityInternal_propertiesOfClass:(Class)class {
	
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	NSUInteger outCount;
	
	objc_property_t *properties = class_copyPropertyList(class, &outCount);
	
	for (NSUInteger i = 0; i < outCount; i++) {
		objc_property_t property = properties[i];
		const char *propertyName = property_getName(property);
		NSString *nameString = [[NSString alloc] initWithCString:propertyName encoding:NSUTF8StringEncoding];
		[array addObject:nameString];
	}
	
	free(properties);
	
	return array;
	
}

@end
