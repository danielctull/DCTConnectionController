//
//  DTConnectionKitExampleViewController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTConnectionController.h"

@interface DTConnectionKitExampleViewController : UIViewController <DTConnectionControllerDelegate> {
	UITextView *textView;
}
@property (nonatomic, retain) IBOutlet UITextView *textView;
@end
