//
//  DTConnectionKitExampleViewController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTConnection.h"

@interface DTConnectionKitExampleViewController : UIViewController <DTConnectionDelegate> {
	UITextView *textView;
	UIToolbar *toolbar;
	UILabel *connectionsLabel;
}
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *connectionsLabel;
- (IBAction)addConnection:(id)sender;
- (IBAction)removeConnection:(id)sender;
@end
