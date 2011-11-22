//
//  DCTConnectionKitExampleViewController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTLogViewController.h"
#import "DCTConnectionController.h"

#if !defined(dctlogviewcontroller) || !defined(dctlogviewcontroller_1_0) || dctlogviewcontroller < dctlogviewcontroller_1_0
#warning "DCTLogViewController 1.0 is required with the demo of DCTConnectionController. Update at https://github.com/danielctull/DCTLogViewController" or pull in the submodules with `git submodule init; git submodule update`.
#endif

@interface DCTConnectionControllerDemoViewController : DCTLogViewController {
	UIToolbar *toolbar;
	UILabel *connectionsLabel;
}
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *connectionsAmountLabel;
@property (nonatomic, retain) IBOutlet UILabel *queuedAmountLabel;
@property (nonatomic, retain) IBOutlet UILabel *activeAmountLabel;
@end
