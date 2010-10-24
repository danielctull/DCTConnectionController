//
//  DCTConnectionQueue+DTInternalAccess.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueue+DCTInternalAccess.h"

@implementation DCTConnectionQueue (DCTInternalAccess)

- (DCTConnectionController *)dct_nextConnection {
	return [self performSelector:@selector(dctInternal_nextConnection)];
}

- (void)dct_runNextConnection {
	[self performSelector:@selector(dctInternal_runNextConnection)];
}

@end
