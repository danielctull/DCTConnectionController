//
//  NSString+DTURLEncoding.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "NSString+DTURLEncoding.h"


@implementation NSString (DTURLEncoding)
- (NSString *)dt_urlEncodedString {
	
	CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(NULL,
																		(CFStringRef)self,
																		NULL,
																		(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																		kCFStringEncodingUTF8);
	
	NSString *string = [[(NSString *)encodedString retain] autorelease];
	CFRelease(encodedString);
	return string;
}

- (NSString *)dt_urlEncodedStringNoSlash {
	
	CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(NULL,
																		(CFStringRef)self,
																		NULL,
																		(CFStringRef)@"!*'();:@&=+$,?%#[]",
																		kCFStringEncodingUTF8);
	
	NSString *string = [[(NSString *)encodedString retain] autorelease];
	CFRelease(encodedString);
	return string;
}

@end
