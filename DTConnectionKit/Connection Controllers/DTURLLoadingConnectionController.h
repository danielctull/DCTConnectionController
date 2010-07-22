//
//  DTURLLoadingConnectionController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 25.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnectionController.h"

@interface DTURLLoadingConnectionController : DTConnectionController {
}

@property (nonatomic, retain, readwrite) NSURL *URL;

@end
