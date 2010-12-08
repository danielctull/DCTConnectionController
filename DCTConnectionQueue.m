//
//  DCTConnectionQueue.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.06.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DCTConnectionQueue.h"
#import "NSObject+DCTKVOExtras.h"
#import "DCTObservationInfo.h"

NSComparisonResult (^compareConnections)(id obj1, id obj2) = ^(id obj1, id obj2) {
	
	if (![obj1 isKindOfClass:[DCTConnectionController class]] || ![obj2 isKindOfClass:[DCTConnectionController class]]) return (NSComparisonResult)NSOrderedSame;
	
	DCTConnectionController *con1 = (DCTConnectionController *)obj1;
	DCTConnectionController *con2 = (DCTConnectionController *)obj2;
	
	if (con1.priority > con2.priority) return (NSComparisonResult)NSOrderedDescending;
	
	if (con1.priority < con2.priority) return (NSComparisonResult)NSOrderedAscending;
	
	return (NSComparisonResult)NSOrderedSame;
};

NSString *const DCTConnectionQueueConnectionCountChangedNotification = @"DCTConnectionQueueConnectionCountChangedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountChangedNotification = @"DCTConnectionQueueActiveConnectionCountChangedNotification";

NSString *const DCTConnectionQueueActiveConnectionCountKey = @"activeConnectionCount";
NSString *const DCTConnectionQueueConnectionCountKey = @"connectionCount";

@interface DCTConnectionQueue ()

- (void)dctInternal_runNextConnection;
- (BOOL)dctInternal_tryToRunConnection:(DCTConnectionController *)connection;
- (void)dctInternal_removeActiveConnection:(DCTConnectionController *)connection;
- (void)dctInternal_addConnectionControllerToActives:(DCTConnectionController *)connectionController;

- (DCTConnectionController *)dctInternal_nextConnection;
- (DCTConnectionController *)dctInternal_nextConnectionIterator:(DCTConnectionController *)connection;

- (void)dctInternal_addConnectionControllerToQueue:(DCTConnectionController *)connectionController;
- (void)dctInternal_removeConnectionFromQueue:(DCTConnectionController *)connectionController;

- (void)dctInternal_dequeueAndStartConnection:(DCTConnectionController *)connectionController;
@end

@implementation DCTConnectionQueue

@synthesize maxConnections, multitaskEnabled;

#pragma mark -
#pragma mark NSObject

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	SEL uikitInit = @selector(uikit_init);
	if ([self respondsToSelector:uikitInit])
		[self performSelector:uikitInit];
		
	activeConnections = [[NSMutableArray alloc] init];
	queuedConnections = [[NSMutableArray alloc] init];
	active = YES;
	self.maxConnections = 5;
	externalConnectionCountKeys = [[NSArray arrayWithObjects:DCTConnectionQueueActiveConnectionCountKey, DCTConnectionQueueConnectionCountKey, nil] retain];
	
	[self addObserver:self forKeyPath:DCTConnectionQueueConnectionCountKey options:NSKeyValueObservingOptionNew context:nil];
	[self addObserver:self forKeyPath:DCTConnectionQueueActiveConnectionCountKey options:NSKeyValueObservingOptionNew context:nil];
	
	return self;	
}

- (void)dealloc {
	SEL uikitDealloc = @selector(uikit_dealloc);
	if ([self respondsToSelector:uikitDealloc])
		[self performSelector:uikitDealloc];
	
	[externalConnectionCountKeys release], externalConnectionCountKeys = nil;
	[activeConnections release]; activeConnections = nil;
	[queuedConnections release]; queuedConnections = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark DCTConnection Queue

- (void)start {
	active = YES;
	[self dctInternal_runNextConnection];
}

- (void)pause {
	active = NO;
}

- (void)stop {
	active = NO;
	
	while ([activeConnections count] > 0)
		[self requeueConnectionController:[activeConnections lastObject]];
}

- (DCTConnectionController *)addConnectionController:(DCTConnectionController *)connectionController {
	
	NSUInteger i = [self.connectionControllers indexOfObject:connectionController];
	
	if (i != NSNotFound) {
		DCTConnectionController *currentCC = [self.connectionControllers objectAtIndex:i];
		
		// Add the delegates from the duplicated connection to the existing one
		[currentCC addDelegates:connectionController.delegates];
		
		// Add the observers from the duplicated connection to the existing one, and remove from the dupe
		for (DCTObservationInfo *info in [connectionController observationInformation]) {
			
			if ([[[currentCC observationInformation] dct_observationInfosWithObject:info.object	keyPath:info.keyPath] count] == 0)
				[currentCC addObserver:info.object forKeyPath:info.keyPath options:info.options context:info.context];
			
			[connectionController removeObserver:info.object forKeyPath:info.keyPath];
		}
		
		return currentCC;
	}
	
	
	
	[connectionController addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	
	[self dctInternal_addConnectionControllerToQueue:connectionController];
	return connectionController;
}

- (void)removeConnectionController:(DCTConnectionController *)connectionController {

	[connectionController removeObserver:self forKeyPath:@"status"];
	[connectionController reset];
	
	if ([activeConnections containsObject:connectionController])
		[self dctInternal_removeActiveConnection:connectionController];
		
	else if ([queuedConnections containsObject:connectionController]) 
		[self dctInternal_removeConnectionFromQueue:connectionController];
}

- (void)requeueConnectionController:(DCTConnectionController *)connectionController {
	[connectionController retain];
	[self dctInternal_removeActiveConnection:connectionController];
	[connectionController reset];
	[self dctInternal_addConnectionControllerToQueue:connectionController];
	[connectionController release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
	if (object == self) {
		
		if ([keyPath isEqualToString:DCTConnectionQueueActiveConnectionCountKey])
			[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountChangedNotification object:self];
		
		else if ([keyPath isEqualToString:DCTConnectionQueueConnectionCountKey])
			[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueConnectionCountChangedNotification object:self];
		
		return;
	}
	
	if (![object isKindOfClass:[DCTConnectionController class]]) return;
	
	if (![keyPath isEqualToString:@"status"]) return;
	
	if (!active) return;
	
	DCTConnectionController *connection = (DCTConnectionController *)object;
	
	if (connection.status >= DCTConnectionControllerStatusComplete)
		[self dctInternal_removeActiveConnection:connection];
}

- (BOOL)isConnectingToURL:(NSURL *)URL {
	for (DCTConnectionController *c in activeConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return YES;
	
	return NO;
}

- (BOOL)hasQueuedConnectionControllerToURL:(NSURL *)URL {
	if ([self queuedConnectionControllerToURL:URL])
		return YES;
	
	return NO;
}

- (DCTConnectionController *)queuedConnectionControllerToURL:(NSURL *)URL {
	for (DCTConnectionController *c in queuedConnections)
		if ([[URL absoluteString] isEqualToString:[c.URL absoluteString]])
			return c;
	
	DCTConnectionController *c = nil;
	
	if ([self respondsToSelector:@selector(uikit_queuedConnectionControllerToURL)])
		c = [self performSelector:@selector(uikit_queuedConnectionControllerToURL)];
	
	return c;
}


- (void)incrementExternalConnectionCount {
	[self dct_changeValueForKeys:externalConnectionCountKeys withChange:^{
		externalConnectionCount++;
	}];
}

- (void)decrementExternalConnectionCount {
	[self dct_changeValueForKeys:externalConnectionCountKeys withChange:^{
		externalConnectionCount--;
	}];
}

#pragma mark -
#pragma mark DCTConnectionQueue Accessors

- (NSArray *)activeConnectionControllers {
	return [NSArray arrayWithArray:activeConnections];
}
- (NSArray *)queuedConnectionControllers {
	return [NSArray arrayWithArray:queuedConnections];
}

- (NSArray *)connectionControllers {
	return [activeConnections arrayByAddingObjectsFromArray:queuedConnections];
}

- (NSInteger)activeConnectionCount {
	return [activeConnections count] + externalConnectionCount;
}

- (NSInteger)connectionCount {
	return self.activeConnectionCount + [queuedConnections count] + [nonMultitaskingConnections count];
}

#pragma mark -
#pragma mark Internals

- (void)dctInternal_runNextConnection {
	
	if ([activeConnections count] >= self.maxConnections) return;
	
	if (!active) return;
	
	if ([queuedConnections count] == 0) return;
	
	// Loop through the queue and try to run the top-most connection.
	// If it can't be run (eg waiting for dependencies), run the next one down.
		
	DCTConnectionController *connection = [self dctInternal_nextConnection];
	
	if (!connection) return;
	
	[self dctInternal_dequeueAndStartConnection:connection];
	
	// In the case that connections are added but the queue is not active, such as
	// returning from background in multitasking, we should repeatedly call this method.
	// It will return out when the max connections has been hit or when there are 
	// no more connections to run.
	[self dctInternal_runNextConnection];
}

- (DCTConnectionController *)dctInternal_nextConnection {
	
	for (DCTConnectionController *connection in queuedConnections) {
		DCTConnectionController *c = [self dctInternal_nextConnectionIterator:connection];
		if (c)
			return c;
	}
	return nil;
}

- (DCTConnectionController *)dctInternal_nextConnectionIterator:(DCTConnectionController *)connection {
	if ([connection.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];		
		
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusQueued)
				return [self dctInternal_nextConnectionIterator:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusStarted || c.status == DCTConnectionControllerStatusResponded)
				return nil;
	}	
	
	return connection;
}

- (BOOL)dctInternal_tryToRunConnection:(DCTConnectionController *)connection {
	
	if ([connection.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connection.dependencies sortedArrayUsingComparator:compareConnections];		
	
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusQueued)
				return [self dctInternal_tryToRunConnection:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusStarted || c.status == DCTConnectionControllerStatusResponded)
				return NO;
	}	
	
	// There are no dependencies left to be run on this connection, so we can safely run it.
	[self dctInternal_dequeueAndStartConnection:connection];
	
	return YES;
}

- (void)dctInternal_addConnectionControllerToQueue:(DCTConnectionController *)connectionController {
	
	[self dct_changeValueForKey:DCTConnectionQueueConnectionCountKey withChange:^{
		[queuedConnections addObject:connectionController];
	}];
	
	[connectionController setQueued];
	[queuedConnections sortUsingComparator:compareConnections];
	
	if (active) [self dctInternal_runNextConnection];
}

- (void)dctInternal_removeConnectionFromQueue:(DCTConnectionController *)connectionController {
	[self dct_changeValueForKey:DCTConnectionQueueConnectionCountKey withChange:^{
		[queuedConnections removeObject:connectionController];
	}];
}

- (void)dctInternal_removeActiveConnection:(DCTConnectionController *)connection {
	[connection removeObserver:self forKeyPath:@"status"];
	
	[self dct_changeValueForKeys:externalConnectionCountKeys withChange:^{
		[activeConnections removeObject:connection];
	}];
	
	[self dctInternal_runNextConnection];
}
		

- (void)dctInternal_addConnectionControllerToActives:(DCTConnectionController *)connectionController {
	[self dct_changeValueForKeys:externalConnectionCountKeys withChange:^{
		[activeConnections addObject:connectionController];
	}];
}

- (void)dctInternal_dequeueAndStartConnection:(DCTConnectionController *)connectionController {
	
	[self dct_changeValueForKey:DCTConnectionQueueActiveConnectionCountKey withChange:^{
		[activeConnections addObject:connectionController];
		[queuedConnections removeObject:connectionController];
	}];
	
	[connectionController start];
}

@end
