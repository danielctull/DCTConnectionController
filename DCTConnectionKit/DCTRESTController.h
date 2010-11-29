//
//  DCTRESTController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 08/08/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionController.h"


@interface DCTRESTController : DCTConnectionController {
}

+ (NSArray *)queryProperties;
+ (NSArray *)bodyProperties;
+ (NSArray *)headerProperties;
- (NSString *)baseURLString;

@end
