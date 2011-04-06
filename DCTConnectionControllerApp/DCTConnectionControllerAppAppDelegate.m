//
//  DCTConnectionControllerAppAppDelegate.m
//  DCTConnectionControllerApp
//
//  Created by Daniel Tull on 06/04/2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//

#import "DCTConnectionControllerAppAppDelegate.h"

#import "DCTConnectionKitExampleViewController.h"
#import "DCTConnectionQueue+Singleton.h"
#import "DCTConnectionQueue+UIKitAdditions.h"

#import "DCTURLConnectionController.h"
#import "DCTConnectionController+Equality.h"

@implementation DCTConnectionControllerAppAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	DCTConnectionQueue *queue = [DCTConnectionQueue sharedConnectionQueue];
	queue.multitaskEnabled = YES;
	queue.maxConnections = 4;
	
	DCTConnectionKitExampleViewController *viewController = [[DCTConnectionKitExampleViewController alloc] init];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
	[viewController release];
	window.rootViewController = nav;
	[nav release];
    [window makeKeyAndVisible];
	
	[self.window makeKeyAndVisible];
    return YES;
}

- (void)dealloc {
	[window release];
    [super dealloc];
}

@end
