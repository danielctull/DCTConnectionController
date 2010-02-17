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
	
	return self;
}

- (void)dealloc {
	[mainContext release];
	[threadedContext release];	
	[super dealloc];
}

- (NSManagedObjectContext *)managedObjectContext {
	return threadedContext;
}

- (void)receivedObject:(NSObject *)object {
	
	[self saveThreadedContext];
	
	if ([object isKindOfClass:[NSArray class]]) {
		
		NSArray *array = (NSArray *)object;
		
		NSMutableArray *idArray = [[NSMutableArray alloc] init];
		
		for (NSObject *o in array) {
			if ([o isKindOfClass:[NSManagedObject class]]) {
				
				NSManagedObject *mo = (NSManagedObject *)o;
				[idArray addObject:[mo objectID]];	
			}
		}
		[self performSelectorOnMainThread:@selector(receivedObjectIDArray:) withObject:idArray waitUntilDone:YES];
		
	} else if ([object isKindOfClass:[NSManagedObject class]]) {
		
		NSManagedObject *mo = (NSManagedObject *)object;
		[self performSelectorOnMainThread:@selector(receivedObjectID:) withObject:[mo objectID] waitUntilDone:YES];
		
	} else {
		[super receivedObject:object];
		
	}
}

- (void)saveThreadedContext {
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self selector:@selector(threadedContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:threadedContext];
	
	[threadedContext lock];
	
	if ([threadedContext hasChanges]) {
		
		
		NSError* error;
        if(![threadedContext save:&error]) {
			NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
			NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			if(detailedErrors != nil && [detailedErrors count] > 0) {
				for(NSError* detailedError in detailedErrors) {
					NSLog(@"  DetailedError: %@", [detailedError userInfo]);
				}
			}
			else {
				NSLog(@"  %@", [error userInfo]);
			}
        }/*
		
		
		
		NSError *error;
		if (![threadedContext save:&error]) NSLog(@"Unresolved error %@, %@", error, [error userInfo]);*/
	}
	
	[threadedContext unlock];
	
	[defaultCenter removeObserver:self name:NSManagedObjectContextDidSaveNotification object:threadedContext];	
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
	[objects release];
}

- (void)receivedObjectID:(NSManagedObjectID *)objectID {
	[super receivedObject:[mainContext objectWithID:objectID]];
}


@end