//
//  DTRequestConnectionController.h
//  Car Maps
//
//  Created by Daniel Tull on 14.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"

/** Simplest workable subclass of DCTConnectionController possible.
 
 Adds a request property which it loads when newRequest is called. 
 */
@interface DCTRequestConnectionController : DCTConnectionController {}


/** The request to load. 
 */
@property (nonatomic, retain) NSURLRequest *request;

@end
