//
//  DTConnectionQueueTests.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnectionQueueTests.h"
#import "DTConnection.h"
#import "DTConnectionQueue.h"

@implementation DTConnectionQueueTests

- (void)testPriority {
	
	[[DTConnectionQueue sharedConnectionQueue] stop];
	
	DTConnection *veryHigh = [DTConnection connection];
	veryHigh.priority = DTConnectionPriorityVeryHigh;
	
	DTConnection *high = [DTConnection connection];
	high.priority = DTConnectionPriorityHigh;
	
	DTConnection *medium = [DTConnection connection];
	medium.priority = DTConnectionPriorityMedium;
	
	DTConnection *low = [DTConnection connection];
	low.priority = DTConnectionPriorityLow;
	
	DTConnection *veryLow = [DTConnection connection];
	veryLow.priority = DTConnectionPriorityVeryLow;
	
	[veryLow connect];
	[low connect];
	[medium connect];
	[high connect];
	[veryHigh connect];
	
	NSArray *connections = [[DTConnectionQueue sharedConnectionQueue] connections];
	
	STAssertTrue([[connections objectAtIndex:0] isEqual:veryHigh], @"First object should be very high priority");
	
	STAssertTrue([[connections objectAtIndex:1] isEqual:high], @"Second object should be high priority");
	
	STAssertTrue([[connections objectAtIndex:2] isEqual:medium], @"Third object should be medium priority");
	
	STAssertTrue([[connections objectAtIndex:3] isEqual:low], @"Fourth object should be low priority");
	
	STAssertTrue([[connections objectAtIndex:4] isEqual:veryLow], @"Fifth object should be very low priority");	
}

@end
