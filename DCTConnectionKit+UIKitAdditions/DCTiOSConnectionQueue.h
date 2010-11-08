//
//  DCTiOSConnectionQueue.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 08/11/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTConnectionQueue.h"

@interface DCTiOSConnectionQueue : DCTConnectionQueue {
	NSMutableArray *nonMultitaskingConnections;
	UIBackgroundTaskIdentifier backgroundTaskIdentifier;
	BOOL inBackground;
}

@property (nonatomic, assign) BOOL multitaskEnabled;
@property (nonatomic, readonly) NSArray *nonMultitaskingQueuedConnections;
@end
