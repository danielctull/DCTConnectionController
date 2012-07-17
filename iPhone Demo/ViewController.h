//
//  DCTConnectionKitExampleViewController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UILabel *connectionsAmountLabel;
@property (nonatomic, weak) IBOutlet UILabel *queuedAmountLabel;
@property (nonatomic, weak) IBOutlet UILabel *activeAmountLabel;
@end
