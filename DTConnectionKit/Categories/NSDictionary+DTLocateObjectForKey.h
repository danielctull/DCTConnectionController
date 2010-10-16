//
//  NSDictionary+DTLocateObjectForKey.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (DTLocateObjectForKey)
- (NSObject *)dt_locateObjectForKey:(NSObject *)key;
@end
