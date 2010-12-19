//
//  DTURLConnection.h
//  DTKit
//
//  Created by Daniel Tull on 03.03.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DCTURLConnection : NSURLConnection {
	
	NSData *data;
    NSString *identifier;
	NSURL *URL;
	
}

#pragma mark -
#pragma mark Connection Information
/** @name Connection Information
 @{
 */

/** A universally unique identifier to indentify this connection.
 
 Uses NSProcessInfo's -globallyUniqueString method to gain a unique string.
 */
@property (readonly, copy) NSString *identifier;

/** The URL of the given request.
 */
@property (readonly, retain) NSURL *URL;

/**
 @}
 */

#pragma mark -
#pragma mark Creating URL Connections
/** @name Creating URL Connections
 @{
 */

/** Initialises and returns a new URL connection with the given objects.
 
 @param request The URL request for the URL connection to perform.
 @param delegate The delegate for the request.
 @param identifier The identifier to use, or nil to generate one.
 
 @return The newly initialized URL connection.
 */

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate identifier:(NSString *)identifier;

/**
 @}
 */

#pragma mark -
#pragma mark Handling the Data
/** @name Handling the Data
 @{
 */

/** The data being returned through this connection.
 
 A nice place to store this without the hassle of setting up a dictionary for the returned data.
 Use -resetDataLength and -appendData: to modify the stored data.
 */
@property (readonly, copy) NSData *data;

/** Resets the data length to 0.
 */
- (void)resetDataLength;

/** Appends the given data to the receiver's data.
 
 Typically this will be called by the delegate of the URL connection every time it receives some data to build up the full data result.
 
 @param someData The data to append to the receiver's data.
 */
- (void)appendData:(NSData *)someData;

/**
 @}
 */

@end
