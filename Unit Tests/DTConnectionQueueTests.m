//
//  DCTConnectionQueueTests.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueueTests.h"
#import "DTMockConnection.h"
#import "DCTConnectionQueue+DTInternalAccess.h"

@implementation DCTConnectionQueueTests

- (void)testPriority {
	
	DCTConnectionQueue *queue = [[[DCTConnectionQueue alloc] init] autorelease];
	
	[queue stop];
	
	DTMockConnection *veryHigh = [DTMockConnection connectionController];
	veryHigh.priority = DCTConnectionControllerPriorityVeryHigh;
	
	DTMockConnection *high = [DTMockConnection connectionController];
	high.priority = DCTConnectionControllerPriorityHigh;
	
	DTMockConnection *medium = [DTMockConnection connectionController];
	medium.priority = DCTConnectionControllerPriorityMedium;
	
	DTMockConnection *low = [DTMockConnection connectionController];
	low.priority = DCTConnectionControllerPriorityLow;
	
	DTMockConnection *veryLow = [DTMockConnection connectionController];
	veryLow.priority = DCTConnectionControllerPriorityVeryLow;
	
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
	veryLow.priority = DCTConnectionControllerPriorityVeryLow;
	
	DTMockConnection *medium = [DTMockConnection connectionController];
	medium.priority = DCTConnectionControllerPriorityMedium;
	
	DTMockConnection *veryHigh = [DTMockConnection connectionController];
	veryHigh.priority = DCTConnectionControllerPriorityVeryHigh;
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
	veryLow.priority = DCTConnectionControllerPriorityVeryLow;
	
	DTMockConnection *low = [DTMockConnection connectionController];
	low.priority = DCTConnectionControllerPriorityLow;
	[low addDependency:veryLow];
	
	DTMockConnection *medium = [DTMockConnection connectionController];
	medium.priority = DCTConnectionControllerPriorityMedium;
	[medium addDependency:low];
	
	DTMockConnection *high = [DTMockConnection connectionController];
	high.priority = DCTConnectionControllerPriorityHigh;
	[high addDependency:medium];
	
	DTMockConnection *veryHigh = [DTMockConnection connectionController];
	veryHigh.priority = DCTConnectionControllerPriorityVeryHigh;
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
