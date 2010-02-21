//
//  DTCoreDataConnection.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 24.01.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DTConnection.h"

@interface DTCoreDataConnection : DTConnection {
	NSManagedObjectContext *mainContext;
	NSManagedObjectContext *threadedContext;
	id mergePolicy;
}

@property (nonatomic, assign) id mergePolicy;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;



#pragma mark -
#pragma mark Initialising a connection

/** @name Initialising a connection
 @{
 */

/** @brief Use this method to create a Core Data-based Connection.
 
 Calling this adds the DTConnection operation to be added to the DTConnectionQueue. 
 
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 @}
 */


@end
