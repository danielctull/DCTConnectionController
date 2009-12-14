//
//  DTConnectionKitAppDelegate.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.12.2009.
//  Copyright Daniel Tull 2009. All rights reserved.
//

#import "DTConnectionKitAppDelegate.h"
#import "DTConnectionKitExampleViewController.h"

@implementation DTConnectionKitAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	DTConnectionKitExampleViewController *viewController = [[DTConnectionKitExampleViewController alloc] init];
	nav = [[UINavigationController alloc] initWithRootViewController:viewController];
	[window addSubview:nav.view];
	[viewController release];
    [window makeKeyAndVisible];
}


- (void)dealloc {
	[nav release];
    [window release];
    [super dealloc];
}


@end
