//
//  DCTConnectionQueueTests.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 01.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueueTests.h"
#import "DCTMockConnection.h"
#import "DCTConnectionQueue+DCTInternalAccess.h"

@implementation DCTConnectionQueueTests

- (void)testPriority {
	
	DCTConnectionQueue *queue = [[[DCTConnectionQueue alloc] init] autorelease];
	
	[queue stop];
	
	DCTMockConnection *veryHigh = [DCTMockConnection connectionController];
	veryHigh.priority = DCTConnectionControllerPriorityVeryHigh;
	
	DCTMockConnection *high = [DCTMockConnection connectionController];
	high.priority = DCTConnectionControllerPriorityHigh;
	
	DCTMockConnection *medium = [DCTMockConnection connectionController];
	medium.priority = DCTConnectionControllerPriorityMedium;
	
	DCTMockConnection *low = [DCTMockConnection connectionController];
	low.priority = DCTConnectionControllerPriorityLow;
	
	DCTMockConnection *veryLow = [DCTMockConnection connectionController];
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
	
	DCTMockConnection *veryLow = [DCTMockConnection connectionController];
	veryLow.priority = DCTConnectionControllerPriorityVeryLow;
	
	DCTMockConnection *medium = [DCTMockConnection connectionController];
	medium.priority = DCTConnectionControllerPriorityMedium;
	
	DCTMockConnection *veryHigh = [DCTMockConnection connectionController];
	veryHigh.priority = DCTConnectionControllerPriorityVeryHigh;
	[veryHigh addDependency:veryLow];
	[veryHigh addDependency:medium];
	
	[queue addConnectionController:veryHigh];
	[queue addConnectionController:veryLow];
	[queue addConnectionController:medium];
	
	STAssertTrue([[queue dct_nextConnection] isEqual:medium], @"Object should be the medium connection.");
	
	[queue dct_runNextConnection];
	
	STAssertTrue([[queue dct_nextConnection] isEqual:veryLow], @"First object should be the dependant very low connection.");
	
	[queue dct_runNextConnection];
	
	STAssertNil([queue dct_nextConnection], @"There should be no connections in the queue that are runable, as the dependant connection is not finished.");
	
	[veryLow complete];
	
	STAssertNil([queue dct_nextConnection], @"There should be no connections in the queue that are runable, as the dependant connection is not finished.");
	
	[medium complete];
	
	STAssertTrue([[queue dct_nextConnection] isEqual:veryHigh], @"Object should be the very high connection, now its dependencies are complete.");
}

- (void)testDeepDependency {
	DCTConnectionQueue *queue = [[[DCTConnectionQueue alloc] init] autorelease];
	
	[queue stop];
	
	DCTMockConnection *veryLow = [DCTMockConnection connectionController];
	veryLow.priority = DCTConnectionControllerPriorityVeryLow;
	
	DCTMockConnection *low = [DCTMockConnection connectionController];
	low.priority = DCTConnectionControllerPriorityLow;
	[low addDependency:veryLow];
	
	DCTMockConnection *medium = [DCTMockConnection connectionController];
	medium.priority = DCTConnectionControllerPriorityMedium;
	[medium addDependency:low];
	
	DCTMockConnection *high = [DCTMockConnection connectionController];
	high.priority = DCTConnectionControllerPriorityHigh;
	[high addDependency:medium];
	
	DCTMockConnection *veryHigh = [DCTMockConnection connectionController];
	veryHigh.priority = DCTConnectionControllerPriorityVeryHigh;
	[veryHigh addDependency:high];
	
	[queue addConnectionController:veryLow];
	[queue addConnectionController:low];
	[queue addConnectionController:medium];
	[queue addConnectionController:high];
	[queue addConnectionController:veryHigh];
	
	STAssertTrue([[queue dct_nextConnection] isEqual:veryLow], @"Object should be the veryLow connection.");
	[queue dct_runNextConnection];
	[veryLow complete];
	
	STAssertTrue([[queue dct_nextConnection] isEqual:low], @"Object should be the low connection.");
	[queue dct_runNextConnection];
	[low complete];
	
	STAssertTrue([[queue dct_nextConnection] isEqual:medium], @"Object should be the medium connection.");
	[queue dct_runNextConnection];
	[medium complete];
	
	STAssertTrue([[queue dct_nextConnection] isEqual:high], @"Object should be the high connection.");
	[queue dct_runNextConnection];
	[high complete];
	
	STAssertTrue([[queue dct_nextConnection] isEqual:veryHigh], @"Object should be the veryHigh connection.");
}

@end
