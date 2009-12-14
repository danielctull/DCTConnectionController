//
//  DTURLConnectionController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnectionController.h"

@interface DTURLConnectionController : DTConnectionController {
	NSURL *URL;
}

@property (nonatomic, retain) NSURL *URL;

@end
