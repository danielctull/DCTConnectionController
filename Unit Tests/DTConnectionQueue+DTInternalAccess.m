//
//  DTConnectionQueue+DTInternalAccess.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnectionQueue+DTInternalAccess.h"

@implementation DTConnectionQueue (DTInternalAccess)

- (DCTConnectionController *)nextConnection {
	return [self performSelector:@selector(dt_nextConnection)];
}

- (void)runNextConnection {
	[self performSelector:@selector(dt_runNextConnection)];
}

@end
