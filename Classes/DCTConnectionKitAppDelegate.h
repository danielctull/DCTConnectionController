//
//  DCTConnectionKitAppDelegate.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.12.2009.
//  Copyright Daniel Tull 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCTConnectionKitAppDelegate : NSObject <UIApplicationDelegate> {
	UINavigationController *nav;
    UIWindow *window;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

