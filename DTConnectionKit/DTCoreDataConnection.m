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

@synthesize mergePolicy;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
	if (!(self = [super init])) return nil;
		
	mainContext = [managedObjectContext retain];
		
	threadedContext = [[NSManagedObjectContext alloc] init];
	[threadedContext setPersistentStoreCoordinator:[mainContext persistentStoreCoordinator]];
	
	return self;
}

- (void)dealloc {
	mergePolicy = nil;
	[mainContext release]; mainContext = nil;
	[threadedContext release]; threadedContext = nil;
	[super dealloc];
}

- (NSManagedObjectContext *)managedObjectContext {
	return [[threadedContext retain] autorelease];
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
		[self performSelector:@selector(receivedObjectIDArray:) onThread:self.originatingThread withObject:idArray waitUntilDone:YES];
	} else if ([object isKindOfClass:[NSManagedObject class]]) {
		
		NSManagedObject *mo = (NSManagedObject *)object;
		[self performSelector:@selector(receivedObjectID:) onThread:self.originatingThread withObject:[mo objectID] waitUntilDone:YES];
		
	} else {
		[super receivedObject:object];
		
	}
}

- (void)saveThreadedContext {
	//[threadedContext lock];
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self selector:@selector(threadedContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:threadedContext];
	
	if ([threadedContext hasChanges]) {
			
		NSError *error;
		
		// Don't need to lock the thread as the merge happens on the originating thread.
		// See -threadedContextDidSave: for how this happens.
		BOOL contextDidSave = [threadedContext save:&error];
		
		if (!contextDidSave) {
			
			// If the context failed to save, log out as many details as possible.
			NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
			
			NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			
			if(detailedErrors != nil && [detailedErrors count] > 0) {
				
				for(NSError* detailedError in detailedErrors)
					NSLog(@"  DetailedError: %@", [detailedError userInfo]);
				
			} else {
				NSLog(@"  %@", [error userInfo]);
			}
			
        }
	}
	
	[defaultCenter removeObserver:self name:NSManagedObjectContextDidSaveNotification object:threadedContext];
	//[threadedContext unlock];
}

- (void)threadedContextDidSave:(NSNotification *)notification {
	id theMergePolicy = self.mergePolicy;
	if (theMergePolicy) [mainContext setMergePolicy:theMergePolicy]; // NSMergeByPropertyStoreTrumpMergePolicy
	
	[mainContext performSelector:@selector(mergeChangesFromContextDidSaveNotification:) 
						onThread:self.originatingThread 
					  withObject:notification 
				   waitUntilDone:YES];
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
