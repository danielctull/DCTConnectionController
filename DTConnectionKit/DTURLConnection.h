//
//  DTURLConnection.h
//  DTKit
//
//  Created by Daniel Tull on 03.03.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DTURLConnection : NSURLConnection {
	
	NSData *data;
    NSString *identifier;
	NSURL *URL;
	
}

@property (readonly, copy) NSData *data;
@property (readonly, copy) NSString *identifier;
@property (readonly, retain) NSURL *URL;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate identifier:(NSString *)anIdentifier;

- (void)resetDataLength;
- (void)appendData:(NSData *)someData;

@end
