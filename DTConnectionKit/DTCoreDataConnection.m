//
//  DTCoreDataConnection.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 24.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTCoreDataConnection.h"

@interface DTCoreDataConnection ()
- (void)saveThreadedContext;
- (void)receivedObjectIDArray:(NSArray *)array;
- (void)receivedObjectID:(NSManagedObjectID *)objectID;
@end

@implementation DTCoreDataConnection

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
	if (!(self = [super init])) return nil;
	
	mainContext = [managedObjectContext retain];
	
	threadedContext = [[NSManagedObjectContext alloc] init];
	[threadedContext setPersistentStoreCoordinator:[mainContext persistentStoreCoordinator]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(threadedContextDidSave:) 
												 name:NSManagedObjectContextDidSaveNotification 
											   object:threadedContext];
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mainContext release];
	[threadedContext release];	
	[super dealloc];
}

- (NSManagedObjectContext *)managedObjectContext {
	
	return threadedContext;
	/*
	if ([self isExecuting] && ![self isConcurrent])
		return threadedContext;
	
	return mainContext;*/
}

- (void)receivedObject:(NSObject *)object {
	
	if ([object isKindOfClass:[NSArray class]]) {
		
		NSArray *array = (NSArray *)object;
		
		NSMutableArray *idArray = [[NSMutableArray alloc] init];
		
		for (NSObject *o in array) {
			if ([o isKindOfClass:[NSManagedObject class]]) {
				NSManagedObject *mo = (NSManagedObject *)o;
				[idArray addObject:[mo objectID]];	
			}
		}
		[self saveThreadedContext];
		[self performSelectorOnMainThread:@selector(receivedObjectIDArray:) withObject:idArray waitUntilDone:YES];
		
	} else if ([object isKindOfClass:[NSManagedObject class]]) {
		NSManagedObject *mo = (NSManagedObject *)object;
		[self saveThreadedContext];
		[self performSelectorOnMainThread:@selector(receivedObjectID:) withObject:[mo objectID] waitUntilDone:YES];
	} else {
		[super receivedObject:object];
	}
}

- (void)saveThreadedContext {
	NSError *error;
	
    if (![threadedContext save:&error]) NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
}

- (void)threadedContextDidSave:(NSNotification *)notification {
	[mainContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
	[mainContext mergeChangesFromContextDidSaveNotification:notification];
}

- (void)receivedObjectIDArray:(NSArray *)array {
	
	NSMutableArray *objects = [[NSMutableArray alloc] init];
	
	for (NSManagedObjectID *objectID in array)		
		[objects addObject:[mainContext objectWithID:objectID]];
	
	[super receivedObject:objects];
}

- (void)receivedObjectID:(NSManagedObjectID *)objectID {
	[super receivedObject:[mainContext objectWithID:objectID]];
}


@end
