//
//  DCTConnectionQueue+DTInternalAccess.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueue+DTInternalAccess.h"

@implementation DCTConnectionQueue (DTInternalAccess)

- (DCTConnectionController *)nextConnection {
	return [self performSelector:@selector(dctInternal_nextConnection)];
}

- (void)runNextConnection {
	[self performSelector:@selector(dctInternal_runNextConnection)];
}

@end
