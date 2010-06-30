//
//  DTConnection2.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTConnection.h"

typedef enum {
	DTConnectionPriorityVeryHigh = 0,
	DTConnectionPriorityHigh,
	DTConnectionPriorityMedium,
	DTConnectionPriorityLow,
	DTConnectionPriorityVeryLow
} DTConnectionPriority;

@interface DTConnection2 : NSObject {
	DTConnectionPriority priority;
	NSMutableArray *dependencies;
	DTConnectionType type;
	DTConnectionStatus status;
	DTURLConnection *urlConnection;
}

@property (nonatomic, readonly) DTConnectionStatus status;
@property (nonatomic, assign) DTConnectionType type;
@property (nonatomic, assign) DTConnectionPriority priority;

@property (nonatomic, readonly) NSArray *dependencies;

+ (DTConnection2 *)connection;

- (void)addDependency:(DTConnection2 *)connection;
- (void)removeDependency:(DTConnection2 *)connection;

- (void)connect;

- (void)start;
- (NSMutableURLRequest *)newRequest;

@end
