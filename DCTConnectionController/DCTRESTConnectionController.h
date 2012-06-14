/*
 DCTRESTController.h
 DCTConnectionController
 
 Created by Daniel Tull on 8.8.2010.
 
 
 
 Copyright (c) 2010 Daniel Tull. All rights reserved.
 
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

#import "DCTConnectionController.h"

/** The DCTRESTController subclass of DCTConnectionController allows easier building of URL requests in general.
 
 The loadURLRequest method in this subclass asks for queryProperties , bodyProperties and headerProperties to build up 
 a complete URL request to the location given by baseURLString . When subclassing , you should 
 implement these methods to allow DCTRESTController to build the request, rather than implementing loadURLRequest as you
 would with other connection controllers.
 */
@interface DCTRESTConnectionController : DCTConnectionController

/// @name Methods to subclass

/** Returns the query properties implemented in each subclass.
 
 This should be overridden by subclasses to give properties to be automatically used in the query string.
*/
+ (NSArray *)queryProperties;

/** Returns the body properties implemented in each subclass.
 
 This should be overridden by subclasses to give properties to be automatically used in a body form.
 */
+ (NSArray *)bodyProperties;

/** Returns the header properties implemented in each subclass.
 
 This should be overridden by subclasses to give properties to be automatically used in the header.
 */
+ (NSArray *)headerProperties;

/** Returns the base URL as a string.
 
 This should be overridden by subclasses to give the base URL to the core 
 */
- (NSString *)baseURLString;

/** Allows the receiver to return a different value for the given connection key.
 
 There are two scenarios where you might want to use this method:
 
 The first is if you want to define a connection (query, body or header) property, that
 is the same as an existing property on DCTConnectionController. For example, if the web service
 requires a "type" query parameter, then you can use this method to override the value used. 
 Return @"type" as one of the keys in queryProperties, and check for the @"type" as the key.
 
 The second is if you want to use a different value type than that used for the type of the 
 object to be used as in the connection property object. For example you may have an enum to 
 define the proprety, but the web service requires a string.
 
 In general, this should return a string.
 
 By default this method returns the result of valueForKey:, thus by not implementing this method,
 this class acts the same as pre version 2.0.2.
 
 @param key The connection property key.
 @return The value for the given key.
 
 @see queryProperties
 @see bodyProperties
 @see headerProperties
 */
- (id)valueForConnectionKey:(id)key;

@end
