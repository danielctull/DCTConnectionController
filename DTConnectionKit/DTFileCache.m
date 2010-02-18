//
//  DTFileCache.m
//  Weather Maps
//
//  Created by Daniel Tull on 24.11.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import "DTFileCache.h"

NSString *const DTFileCachePath = @"DTDiskCache";
NSString *const DTFileCacheDictionaryPath = @"DTDiskCacheDictionary";

@interface DTFileCache ()
+ (NSDictionary *)cacheDictionary;
+ (NSString *)pathForKey:(NSString *)key;
+ (NSString *)pathForFilename:(NSString *)filename;
+ (NSString *)baseDirectoryPath;
+ (NSString *)cacheDictionaryPath;
@end

@implementation DTFileCache

+ (BOOL)hasCacheForKey:(NSString *)key {
	if ([[self cacheDictionary] objectForKey:key])
		return YES;
	
	return NO;
}

+ (BOOL)setData:(NSData *)data forKey:(NSString *)key {

	NSString *filename = [[self cacheDictionary] objectForKey:key];
	BOOL newFile = NO;
		
	if (!filename) {
		CFUUIDRef uuidObj = CFUUIDCreate(nil);
		CFStringRef uniqueString = CFUUIDCreateString(nil, uuidObj);
		filename = [NSString stringWithFormat:@"file-%@", uniqueString];
		CFRelease(uniqueString);
		CFRelease(uuidObj);
		newFile = YES;
	}
	
	if (![data writeToFile:[self pathForFilename:filename] atomically:NO]) return NO;
	
	if (newFile) {
		NSMutableDictionary *dict = [[self cacheDictionary] mutableCopy];
		[dict setObject:filename forKey:key];
		BOOL dictSuccess = [dict writeToFile:[self cacheDictionaryPath] atomically:NO];
		[dict release];	
		
		if (!dictSuccess) {
			NSError *error = nil;
			[[NSFileManager defaultManager] removeItemAtPath:[self pathForFilename:filename] error:&error];
			return NO;
		}
	}	
	return YES;	
}

+ (BOOL)deleteDataForKey:(NSString *)key {
	NSString *filename = [[self cacheDictionary] objectForKey:key];
	
	if (!filename) return NO;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSString *path = [self pathForFilename:filename];
	
	if ([fileManager fileExistsAtPath:path]) {
		NSError *error = nil;
		if (![fileManager removeItemAtPath:path error:&error]) return NO;
	}
	
	NSMutableDictionary *dict = [[self cacheDictionary] mutableCopy];
	[dict removeObjectForKey:key];
	BOOL dictSuccess = [dict writeToFile:[self cacheDictionaryPath] atomically:NO];	
	[dict release];
	
	return dictSuccess;	
}

+ (NSData *)dataForKey:(NSString *)key {
	return [NSData dataWithContentsOfFile:[self pathForKey:key]];
}



#pragma mark -
#pragma mark Internal methods

+ (NSDictionary *)cacheDictionary {
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[self cacheDictionaryPath]];
	
	if (!dict) dict = [NSDictionary dictionary];
	
	return dict;
}


+ (NSString *)pathForKey:(NSString *)key {
	return [self pathForFilename:[[self cacheDictionary] objectForKey:key]];
}

+ (NSString *)pathForFilename:(NSString *)filename {
	return [[self baseDirectoryPath] stringByAppendingPathComponent:filename];
}

+ (NSString *)baseDirectoryPath {
	
	NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:DTFileCachePath];
		
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (![fileManager fileExistsAtPath:path])
		[fileManager createDirectoryAtPath:path attributes:nil];
	
	return path;
}

	
+ (NSString *)cacheDictionaryPath {
	return [[self baseDirectoryPath] stringByAppendingPathComponent:DTFileCacheDictionaryPath];
}







+ (void)logCache {
	
	NSError *error = nil;
	
	NSDictionary *dict = [self cacheDictionary];
	NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self baseDirectoryPath] error:&error];
	
	NSLog(@"DTImageCache: %i in dictionary, %i on disk.\n%@\n%@", [dict count], [items count], dict, items);
}

@end
