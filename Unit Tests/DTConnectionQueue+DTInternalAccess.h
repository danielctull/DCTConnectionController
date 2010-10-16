//
//  DCTConnectionQueue+DTInternalAccess.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueue.h"

@interface DCTConnectionQueue (DTInternalAccess)
- (DCTConnectionController *)nextConnection;
- (void)runNextConnection;
@end
