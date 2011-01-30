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
 
 The newRequest method in this subclass asks for queryProperties , bodyProperties and headerProperties to build up 
 a complete URL request to the location given by baseURLString . When subclassing , you should 
 implement these methods to allow DCTRESTController to build the request, rather than implementing newRequest as you
 would with other connection controllers.
 */
@interface DCTRESTController : DCTConnectionController {
}

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

@end