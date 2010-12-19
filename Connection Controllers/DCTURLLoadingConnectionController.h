//
//  DTURLLoadingConnectionController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 25.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTConnectionController.h"

/** Another simple connection controller subclass.*/
@interface DCTURLLoadingConnectionController : DCTConnectionController {
}

/** The URL to load. */
@property (nonatomic, retain, readwrite) NSURL *URL;

@end
