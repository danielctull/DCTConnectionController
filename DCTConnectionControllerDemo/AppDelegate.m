//
//  AppDelegate.m
//  DCTConnectionControllerDemo
//
//  Created by Daniel Tull on 25.06.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
	
	ViewController *vc = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.window makeKeyAndVisible];
		
    return YES;
}

@end
