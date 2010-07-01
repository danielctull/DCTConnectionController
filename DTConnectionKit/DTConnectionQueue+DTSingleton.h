//
//  DTConnectionQueue+DTSingleton.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnectionQueue.h"

@interface DTConnectionQueue (DTSingleton)
+ (DTConnectionQueue *)sharedConnectionQueue;
@end
