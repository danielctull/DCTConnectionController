//
//  DTCoreDataConnection.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 24.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTCoreDataConnection.h"

@implementation DTCoreDataConnection

@synthesize managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc {
	
	if (!(self = [super init])) return nil;
		
	managedObjectContext = [moc retain];
	
	return self;
}

- (void)dealloc {
	[managedObjectContext release]; managedObjectContext = nil;
	[super dealloc];
}

@end
