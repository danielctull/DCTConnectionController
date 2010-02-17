//
//  DTFileCache.h
//  Weather Maps
//
//  Created by Daniel Tull on 24.11.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTFileCache : NSObject {

}

+ (BOOL)hasCacheForKey:(NSString *)key;
+ (BOOL)setData:(NSData *)data forKey:(NSString *)key;
+ (BOOL)deleteDataForKey:(NSString *)key;
+ (NSData *)dataForKey:(NSString *)key;
+ (void)logCache;
@end
