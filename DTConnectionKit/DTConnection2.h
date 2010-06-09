//
//  DTConnection2.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	DTConnectionPriorityVeryHigh = 0,
	DTConnectionPriorityHigh,
	DTConnectionPriorityMedium,
	DTConnectionPriorityLow,
	DTConnectionPriorityVeryLow
} DTConnectionPriority;

@interface DTConnection2 : NSObject {
	DTConnectionPriority priority;
	NSArray *dependencies;
}

@property (nonatomic, readonly) NSArray *dependencies;
- (void)addDependency:(DTConnection2 *)connection;
- (void)removeDependency:(DTConnection2 *)connection;

- (void)connect;
- (void)addToConnectionQueue;

@end
