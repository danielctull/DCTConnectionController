/*
 DCTConnectionQueue.m
 DCTConnectionController
 
 Created by Daniel Tull on 9.6.2010.
 
 
 
 Copyright (c) 2010 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DCTConnectionQueue.h"
#import "DCTConnectionController+UsefulChecks.h"
#import "DCTConnectionGroup.h"
#import "DCTConnectionQueue+Singleton.h"

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
NSString *const DCTConnectionQueueActiveConnectionCountIncreasedNotification = @"DCTConnectionQueueActiveConnectionCountIncreasedNotification";
NSString *const DCTConnectionQueueActiveConnectionCountDecreasedNotification = @"DCTConnectionQueueActiveConnectionCountDecreasedNotification";

@interface DCTConnectionQueue ()

- (void)dctInternal_runNextConnection;
- (BOOL)dctInternal_tryToRunConnection:(DCTConnectionController *)connection;

- (DCTConnectionController *)dctInternal_nextConnection;
- (DCTConnectionController *)dctInternal_nextConnectionIterator:(DCTConnectionController *)connection;

- (void)dctInternal_dequeueAndStartConnection:(DCTConnectionController *)connectionController;

#ifdef TARGET_OS_IPHONE
- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification;
- (void)dctInternal_applicationWillTerminateNotification:(NSNotification *)notification;
- (void)dctInternal_archiveConnectionController:(DCTConnectionController *)cc;
#endif

@property (nonatomic, strong) NSMutableArray *dctInternal_activeConnectionControllers;
@property (nonatomic, strong) NSMutableArray *dctInternal_queuedConnectionControllers;

@end

@implementation DCTConnectionQueue {
	BOOL active;
	dispatch_queue_t queue;
}

@synthesize maxConnections;
@synthesize archivePriorityThreshold = _archivePriorityThreshold;
@synthesize backgroundPriorityThreshold = _backgroundPriorityThreshold;
@synthesize dctInternal_activeConnectionControllers;
@synthesize dctInternal_queuedConnectionControllers;

#pragma mark - NSObject

#ifdef TARGET_OS_IPHONE

+ (void)load {
	// Load the archives and add connections to shared queue:
	[[DCTConnectionQueue sharedConnectionQueue] dctInternal_applicationWillEnterForegroundNotification:nil];
}

- (void)dealloc {
	UIApplication *app = [UIApplication sharedApplication];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:UIApplicationDidEnterBackgroundNotification
												  object:app];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:UIApplicationWillTerminateNotification
												  object:app];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:UIApplicationWillEnterForegroundNotification
												  object:app];
}
#endif

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	_backgroundPriorityThreshold = DCTConnectionControllerPriorityHigh;
	_archivePriorityThreshold = DCTConnectionControllerPriorityVeryHigh;
	self.dctInternal_activeConnectionControllers = [[NSMutableArray alloc] init];
	self.dctInternal_queuedConnectionControllers = [[NSMutableArray alloc] init];
	active = YES;
	self.maxConnections = 5;
	
	queue = dispatch_get_current_queue();
	
#ifdef TARGET_OS_IPHONE
	
	UIApplication *app = [UIApplication sharedApplication];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dctInternal_applicationDidEnterBackgroundNotification:) 
												 name:UIApplicationDidEnterBackgroundNotification 
											   object:app];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dctInternal_applicationWillTerminateNotification:) 
												 name:UIApplicationWillTerminateNotification
											   object:app];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dctInternal_applicationWillEnterForegroundNotification:) 
												 name:UIApplicationWillEnterForegroundNotification
											   object:app];
#endif
	
	return self;	
}

#pragma mark - DCTConnectionQueue

- (void)start {
	active = YES;
	[self dctInternal_runNextConnection];
}

- (void)stop {
	active = NO;
	
	[self.activeConnectionControllers makeObjectsPerformSelector:@selector(requeue)];
}

- (NSArray *)activeConnectionControllers {
	return [self.dctInternal_activeConnectionControllers copy];
}


- (NSArray *)queuedConnectionControllers {
	return [self.dctInternal_queuedConnectionControllers copy];
}

- (NSArray *)connectionControllers {
	return [self.dctInternal_activeConnectionControllers arrayByAddingObjectsFromArray:self.dctInternal_queuedConnectionControllers];
}

- (void)addConnectionController:(DCTConnectionController *)connectionController {
	
	/*NSString *previousSymbol = [[NSThread callStackSymbols] objectAtIndex:1];
	SEL connectOnQueue = @selector(connectOnQueue:);
	if ([previousSymbol rangeOfString:NSStringFromSelector(connectOnQueue)].location == NSNotFound) {
		[connectionController connectOnQueue:self];
		return;
	}*/
		
	__dct_weak DCTConnectionController *weakConnectionController = connectionController;
	__dct_weak DCTConnectionQueue *weakSelf = self;
	
	[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
		if (weakConnectionController.ended) {
			[weakSelf removeConnectionController:weakConnectionController];
			if (active) [weakSelf dctInternal_runNextConnection];
		}
	}];
	
	[self.dctInternal_queuedConnectionControllers addObject:connectionController];
	[self.dctInternal_queuedConnectionControllers sortUsingComparator:compareConnections];
	
	if (active) [self dctInternal_runNextConnection];
}

- (void)removeConnectionController:(DCTConnectionController *)connectionController {
	
	if ([self.dctInternal_queuedConnectionControllers containsObject:connectionController])
		[self.dctInternal_queuedConnectionControllers removeObject:connectionController];
	
	if ([self.dctInternal_activeConnectionControllers containsObject:connectionController]) {
		[self.dctInternal_activeConnectionControllers removeObject:connectionController];
		[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountDecreasedNotification object:self];
		[self dctInternal_runNextConnection];
	}
}

#pragma mark - Internals

- (void)dctInternal_runNextConnection {
	
	if ([self.dctInternal_activeConnectionControllers count] >= self.maxConnections) return;
	
	if (!active) return;
	
	if ([self.dctInternal_queuedConnectionControllers count] == 0) return;
	
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
	
	for (DCTConnectionController *connection in self.dctInternal_queuedConnectionControllers) {
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

- (BOOL)dctInternal_tryToRunConnection:(DCTConnectionController *)connectionController {
	
	if ([connectionController.dependencies count] > 0) {
		
		// Sort so the dependencies are in order from high to low.
		NSArray *sortedDependencies = [connectionController.dependencies sortedArrayUsingComparator:compareConnections];		
	
		// Look for connections that are queued at present, if there is one, we can process that one.
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusQueued)
				return [self dctInternal_tryToRunConnection:c];
		
		// Look for connections that are "active" at present, if there is one, we can't proceed.		
		for (DCTConnectionController *c in sortedDependencies)
			if (c.status == DCTConnectionControllerStatusStarted || c.status == DCTConnectionControllerStatusResponded)
				return NO;
	}	
	
	// There are no dependencies left to be run on this connection controller, so we can safely run it.
	[self dctInternal_dequeueAndStartConnection:connectionController];
	
	return YES;
}

- (void)dctInternal_dequeueAndStartConnection:(DCTConnectionController *)connectionController {
	
	[self removeConnectionController:connectionController];
	[self.dctInternal_activeConnectionControllers addObject:connectionController];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DCTConnectionQueueActiveConnectionCountIncreasedNotification object:self];
	
	[connectionController start];
}

#ifdef TARGET_OS_IPHONE

- (void)dctInternal_archiveConnectionController:(DCTConnectionController *)cc {
	NSURL *archiveURL = [[[self class] dctInternal_archiveDirectory] URLByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	[NSKeyedArchiver archiveRootObject:cc toFile:[archiveURL path]];
	
	NSLog(@"%@ ARCHIVING to: %@\n\n%@", self, archiveURL, [cc fullDescription]);
}

- (void)dctInternal_handleTerminationWithConnectionController:(DCTConnectionController *)cc {
	
	[cc cancel];
	
	if (cc.priority <= self.archivePriorityThreshold)
		[self dctInternal_archiveConnectionController:cc];
}

- (void)dctInternal_handleBackgroundingWithConnectionController:(DCTConnectionController *)cc {
	
	NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), cc);
	
	if (cc.priority > self.backgroundPriorityThreshold) { // Bigger value is lower priority for some bloody reason.
		
		[self dctInternal_handleTerminationWithConnectionController:cc];
		
	} else {
		
		UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			[self stop];
			[self dctInternal_handleTerminationWithConnectionController:cc];
		}];
		
		[cc addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
			if (status > DCTConnectionControllerStatusResponded)
				[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
		}];
	}
}

- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification {
	
	[self.activeConnectionControllers enumerateObjectsUsingBlock:^(DCTConnectionController *cc, NSUInteger idx, BOOL *stop) {
		[self dctInternal_handleBackgroundingWithConnectionController:cc];		
	}];
	
	[self.queuedConnectionControllers enumerateObjectsUsingBlock:^(DCTConnectionController *cc, NSUInteger idx, BOOL *stop) {
		[self dctInternal_handleBackgroundingWithConnectionController:cc];		
	}];
}

- (void)dctInternal_applicationWillTerminateNotification:(NSNotification *)notification {
	
	[self stop];
	
	[self.activeConnectionControllers enumerateObjectsUsingBlock:^(DCTConnectionController *cc, NSUInteger idx, BOOL *stop) {
		[self dctInternal_handleTerminationWithConnectionController:cc];		
	}];
	
	[self.queuedConnectionControllers enumerateObjectsUsingBlock:^(DCTConnectionController *cc, NSUInteger idx, BOOL *stop) {
		[self dctInternal_handleTerminationWithConnectionController:cc];		
	}];
}

- (void)dctInternal_applicationWillEnterForegroundNotification:(NSNotification *)notification {
	
	[self start];
	
	NSURL *archiveDirectoryURL = [[self class] dctInternal_archiveDirectory];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSArray *archiveURLs = [fileManager contentsOfDirectoryAtURL:archiveDirectoryURL 
									  includingPropertiesForKeys:nil
														 options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants) 
														   error:nil];
	
	[archiveURLs enumerateObjectsUsingBlock:^(NSURL *archiveURL, NSUInteger idx, BOOL *stop) {
		DCTConnectionController *cc = [NSKeyedUnarchiver unarchiveObjectWithFile:[archiveURL path]];
		[fileManager removeItemAtURL:archiveURL error:nil];
		[cc connectOnQueue:self];
		NSLog(@"%@ UNARCHIVING from: %@\n\n%@", self, archiveURL, [cc fullDescription]);
	}];
}

+ (NSURL *)dctInternal_archiveDirectory {
	NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	NSURL *archive = [docs URLByAppendingPathComponent:@".DCTConnectionControllerArchive"];
	[[NSFileManager defaultManager] createDirectoryAtURL:archive withIntermediateDirectories:YES attributes:nil error:nil];
	return archive;
}

#endif

@end
