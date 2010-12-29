//
//  DCTRESTController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 08/08/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

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
