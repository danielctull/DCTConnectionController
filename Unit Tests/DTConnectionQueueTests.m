//
//  DTConnectionQueueTests.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnectionQueueTests.h"
#import "DTMockConnection.h"
#import "DTConnectionQueue+DTInternalAccess.h"

@implementation DTConnectionQueueTests

- (void)testPriority {
	
	DTConnectionQueue *queue = [[[DTConnectionQueue alloc] init] autorelease];
	
	[queue stop];
	
	DTMockConnection *veryHigh = [DTMockConnection connection];
	veryHigh.priority = DTConnectionPriorityVeryHigh;
	
	DTMockConnection *high = [DTMockConnection connection];
	high.priority = DTConnectionPriorityHigh;
	
	DTMockConnection *medium = [DTMockConnection connection];
	medium.priority = DTConnectionPriorityMedium;
	
	DTMockConnection *low = [DTMockConnection connection];
	low.priority = DTConnectionPriorityLow;
	
	DTMockConnection *veryLow = [DTMockConnection connection];
	veryLow.priority = DTConnectionPriorityVeryLow;
	
	[queue addConnection:veryLow];
	[queue addConnection:low];
	[queue addConnection:medium];
	[queue addConnection:high];
	[queue addConnection:veryHigh];
	
	NSArray *connections = [queue connections];
	
	STAssertTrue([[connections objectAtIndex:0] isEqual:veryHigh], @"First object should be very high priority");
	
	STAssertTrue([[connections objectAtIndex:1] isEqual:high], @"Second object should be high priority");
	
	STAssertTrue([[connections objectAtIndex:2] isEqual:medium], @"Third object should be medium priority");
	
	STAssertTrue([[connections objectAtIndex:3] isEqual:low], @"Fourth object should be low priority");
	
	STAssertTrue([[connections objectAtIndex:4] isEqual:veryLow], @"Fifth object should be very low priority");	
}

- (void)testOrderingDependencies {
	
	DTConnectionQueue *queue = [[[DTConnectionQueue alloc] init] autorelease];
	
	[queue stop];
	
	DTMockConnection *veryLow = [DTMockConnection connection];
	veryLow.priority = DTConnectionPriorityVeryLow;
	
	DTMockConnection *medium = [DTMockConnection connection];
	medium.priority = DTConnectionPriorityMedium;
	
	DTMockConnection *veryHigh = [DTMockConnection connection];
	veryHigh.priority = DTConnectionPriorityVeryHigh;
	[veryHigh addDependency:veryLow];
	[veryHigh addDependency:medium];
	
	[queue addConnection:veryHigh];
	[queue addConnection:veryLow];
	[queue addConnection:medium];
	
	STAssertTrue([[queue nextConnection] isEqual:medium], @"Object should be the medium connection.");
	
	[queue runNextConnection];
	
	STAssertTrue([[queue nextConnection] isEqual:veryLow], @"First object should be the dependant very low connection.");
	
	
	[queue runNextConnection];
	
	STAssertNil([queue nextConnection], @"There should be no connections in the queue that are runable, as the dependant connection is not finished.");
	
	[veryLow complete];
	
	STAssertNil([queue nextConnection], @"There should be no connections in the queue that are runable, as the dependant connection is not finished.");
	
	[medium complete];
	
	STAssertTrue([[queue nextConnection] isEqual:veryHigh], @"Object should be the very high connection, now its dependencies are complete.");
}

- (void)testDeepDependency {
	DTConnectionQueue *queue = [[[DTConnectionQueue alloc] init] autorelease];
	
	[queue stop];
	
	DTMockConnection *veryLow = [DTMockConnection connection];
	veryLow.priority = DTConnectionPriorityVeryLow;
	
	DTMockConnection *low = [DTMockConnection connection];
	low.priority = DTConnectionPriorityLow;
	[low addDependency:veryLow];
	
	DTMockConnection *medium = [DTMockConnection connection];
	medium.priority = DTConnectionPriorityMedium;
	[medium addDependency:low];
	
	DTMockConnection *high = [DTMockConnection connection];
	high.priority = DTConnectionPriorityHigh;
	[high addDependency:medium];
	
	DTMockConnection *veryHigh = [DTMockConnection connection];
	veryHigh.priority = DTConnectionPriorityVeryHigh;
	[veryHigh addDependency:high];
	
	[queue addConnection:veryLow];
	[queue addConnection:low];
	[queue addConnection:medium];
	[queue addConnection:high];
	[queue addConnection:veryHigh];
	
	STAssertTrue([[queue nextConnection] isEqual:veryLow], @"Object should be the veryLow connection.");
	[queue runNextConnection];
	[veryLow complete];
	
	STAssertTrue([[queue nextConnection] isEqual:low], @"Object should be the low connection.");
	[queue runNextConnection];
	[low complete];
	
	STAssertTrue([[queue nextConnection] isEqual:medium], @"Object should be the medium connection.");
	[queue runNextConnection];
	[medium complete];
	
	STAssertTrue([[queue nextConnection] isEqual:high], @"Object should be the high connection.");
	[queue runNextConnection];
	[high complete];
	
	STAssertTrue([[queue nextConnection] isEqual:veryHigh], @"Object should be the veryHigh connection.");
}

@end
