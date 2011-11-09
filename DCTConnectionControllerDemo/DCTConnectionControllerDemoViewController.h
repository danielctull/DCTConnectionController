//
//  DCTConnectionKitExampleViewController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTConnectionController.h"

@interface DCTConnectionControllerDemoViewController : UIViewController <DCTConnectionControllerDelegate> {
	UITextView *textView;
	UIToolbar *toolbar;
	UILabel *connectionsLabel;
}
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *connectionsAmountLabel;
@property (nonatomic, retain) IBOutlet UILabel *queuedAmountLabel;
@property (nonatomic, retain) IBOutlet UILabel *activeAmountLabel;
@end