//
//  DTRESTController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 08/08/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DTConnectionController.h"


@interface DTRESTController : DTConnectionController {
}

+ (NSArray *)queryProperties;
+ (NSArray *)bodyProperties;

@end
