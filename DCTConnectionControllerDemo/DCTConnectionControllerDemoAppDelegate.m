//
//  DCTConnectionControllerDemoAppDelegate.m
//  DCTConnectionController
//
//  Created by Daniel Tull on 07.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionControllerDemoAppDelegate.h"

#import "DCTConnectionControllerDemoViewController.h"

@implementation DCTConnectionControllerDemoAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	DCTConnectionControllerDemoViewController *vc = [[DCTConnectionControllerDemoViewController alloc] initWithNibName:@"DCTConnectionControllerDemoViewController" bundle:nil];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
	self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
