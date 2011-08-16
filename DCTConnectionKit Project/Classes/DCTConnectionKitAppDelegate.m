//
//  DCTConnectionKitAppDelegate.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.12.2009.
//  Copyright Daniel Tull 2009. All rights reserved.
//

#import "DCTConnectionKitAppDelegate.h"
#import "DCTConnectionKitExampleViewController.h"
#import "DCTConnectionQueue+Singleton.h"
#import "DCTConnectionQueue+UIKitAdditions.h"

#import "DCTConnectionController.h"
#import "DCTConnectionController+Equality.h"

@implementation DCTConnectionKitAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	/*
	DCTConnectionController *c = [[DCTConnectionController alloc] init];
	c.URL = [NSURL URLWithString:@"www.google.com"];
	c.delegate = self;
	DCTConnectionController *cRunning = [c connect];
	
	NSLog(@"%@", cRunning);
	
	DCTConnectionController *c2 = [[DCTConnectionController alloc] init];
	c2.URL = [NSURL URLWithString:@"www.google.com"];
	c2.delegate = self;
	DCTConnectionController *c2Running = [c2 connect];
	
	NSLog(@"%@", c2Running);
	
	NSLog(@"%@", [c delegates]);
	
	NSLog(@"[c isEqualToConnectionController:c2]: %i", [c isEqualToConnectionController:c2]);
	*/
	
	DCTConnectionQueue *queue = [DCTConnectionQueue sharedConnectionQueue];
	queue.multitaskEnabled = YES;
	queue.maxConnections = 4;
	
	DCTConnectionKitExampleViewController *viewController = [[DCTConnectionKitExampleViewController alloc] init];
	nav = [[UINavigationController alloc] initWithRootViewController:viewController];
	[window addSubview:nav.view];
    [window makeKeyAndVisible];
}




@end
