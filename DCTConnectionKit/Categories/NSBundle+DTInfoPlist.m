//
//  NSBundle+DTInfoPlist.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "NSBundle+DTInfoPlist.h"
#import "NSDictionary+DTLocateObjectForKey.h"

@implementation NSBundle (DTInfoPlist)

- (NSObject *)dt_deepObjectForInfoDictionaryKey:(NSString *)key {
	return [[self infoDictionary] dt_locateObjectForKey:key];
}

@end
