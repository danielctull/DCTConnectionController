//
//  DCTiOSConnectionQueue.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 08/11/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTConnectionQueue.h"

@interface DCTConnectionQueue (UIKitAdditions)

@property (nonatomic, readonly) NSArray *nonMultitaskingQueuedConnections;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;


// Methods called by the queue proper to enable UIKit functionality
- (DCTConnectionController *)uikit_queuedConnectionControllerToURL:(NSURL *)URL;
- (void)uikit_dealloc;
- (void)uikit_init;

@end
