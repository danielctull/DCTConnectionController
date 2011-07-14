/*
 DCTURLConnection.h
 DCTConnectionController
 
 Created by Daniel Tull on 3.3.2009.
 
 
 
 Copyright (c) 2009 Daniel Tull. All rights reserved.
 
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
@property (readonly, strong) NSURL *URL;

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
