//
//  NSString+DTURLEncoding.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (DTURLEncoding)


/** Get a URL encoded string.
 */
- (NSString *)dt_urlEncodedString;

/** Get a URL encoded string, disregarding the slash.
 */
- (NSString *)dt_urlEncodedStringNoSlash;

@end
