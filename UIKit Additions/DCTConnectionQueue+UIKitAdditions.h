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

/** Background task identifier given when we ask for background completion.
 */
@property (nonatomic, readonly) NSArray *nonMultitaskingQueuedConnections;

/** Background task identifier given when we ask for background completion.
 */
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end
