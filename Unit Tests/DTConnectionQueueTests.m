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
	
	DCTConnectionQueue *queue = [[[DCTConnectionQueue alloc] init] autorelease];
	
	[queue stop];
	
	DTMockConnection *veryHigh = [DTMockConnection connectionController];
	veryHigh.priority = DTConnectionControllerPriorityVeryHigh;
	
	DTMockConnection *high = [DTMockConnection connectionController];
	high.priority = DTConnectionControllerPriorityHigh;
	
	DTMockConnection *medium = [DTMockConnection connectionController];
	medium.priority = DTConnectionControllerPriorityMedium;
	
	DTMockConnection *low = [DTMockConnection connectionController];
	low.priority = DTConnectionControllerPriorityLow;
	
	DTMockConnection *veryLow = [DTMockConnection connectionController];
	veryLow.priority = DTConnectionControllerPriorityVeryLow;
	
	[queue addConnectionController:veryLow];
	[queue addConnectionController:low];
	[queue addConnectionController:medium];
	[queue addConnectionController:high];
	[queue addConnectionController:veryHigh];
	
	NSArray *connections = [queue connectionControllers];
	
	STAssertTrue([[connections objectAtIndex:0] isEqual:veryHigh], @"First object should be very high priority");
	
	STAssertTrue([[connections objectAtIndex:1] isEqual:high], @"Second object should be high priority");
	
	STAssertTrue([[connections objectAtIndex:2] isEqual:medium], @"Third object should be medium priority");
	
	STAssertTrue([[connections objectAtIndex:3] isEqual:low], @"Fourth object should be low priority");
	
	STAssertTrue([[connections objectAtIndex:4] isEqual:veryLow], @"Fifth object should be very low priority");	
}

- (void)testOrderingDependencies {
	
	DCTConnectionQueue *queue = [[[DCTConnectionQueue alloc] init] autorelease];
	
	[queue stop];
	
	DTMockConnection *veryLow = [DTMockConnection connectionController];
	veryLow.priority = DTConnectionControllerPriorityVeryLow;
	
	DTMockConnection *medium = [DTMockConnection connectionController];
	medium.priority = DTConnectionControllerPriorityMedium;
	
	DTMockConnection *veryHigh = [DTMockConnection connectionController];
	veryHigh.priority = DTConnectionControllerPriorityVeryHigh;
	[veryHigh addDependency:veryLow];
	[veryHigh addDependency:medium];
	
	[queue addConnectionController:veryHigh];
	[queue addConnectionController:veryLow];
	[queue addConnectionController:medium];
	
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
	DCTConnectionQueue *queue = [[[DCTConnectionQueue alloc] init] autorelease];
	
	[queue stop];
	
	DTMockConnection *veryLow = [DTMockConnection connectionController];
	veryLow.priority = DTConnectionControllerPriorityVeryLow;
	
	DTMockConnection *low = [DTMockConnection connectionController];
	low.priority = DTConnectionControllerPriorityLow;
	[low addDependency:veryLow];
	
	DTMockConnection *medium = [DTMockConnection connectionController];
	medium.priority = DTConnectionControllerPriorityMedium;
	[medium addDependency:low];
	
	DTMockConnection *high = [DTMockConnection connectionController];
	high.priority = DTConnectionControllerPriorityHigh;
	[high addDependency:medium];
	
	DTMockConnection *veryHigh = [DTMockConnection connectionController];
	veryHigh.priority = DTConnectionControllerPriorityVeryHigh;
	[veryHigh addDependency:high];
	
	[queue addConnectionController:veryLow];
	[queue addConnectionController:low];
	[queue addConnectionController:medium];
	[queue addConnectionController:high];
	[queue addConnectionController:veryHigh];
	
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
