//
//  DCTConnectionQueue+DTInternalAccess.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueue.h"

@interface DCTConnectionQueue (DCTInternalAccess)
- (DCTConnectionController *)dct_nextConnection;
- (void)dct_runNextConnection;
@end
