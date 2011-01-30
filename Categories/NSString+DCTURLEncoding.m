//
//  NSString+DCTURLEncoding.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "NSString+DCTURLEncoding.h"


@implementation NSString (DCTURLEncoding)
- (NSString *)dct_urlEncodedString {
	
	CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(NULL,
																		(CFStringRef)self,
																		NULL,
																		(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																		kCFStringEncodingUTF8);
	
	NSString *string = [[(NSString *)encodedString retain] autorelease];
	CFRelease(encodedString);
	return string;
}

@end
