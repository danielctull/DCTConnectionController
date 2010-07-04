//
//  DTConnectionKitAppDelegate.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.12.2009.
//  Copyright Daniel Tull 2009. All rights reserved.
//

#import "DTConnectionKitAppDelegate.h"
#import "DTConnectionKitExampleViewController.h"
#import "DTOAuthRequestTokenConnection.h"

@implementation DTConnectionKitAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	/*DTConnectionKitExampleViewController *viewController = [[DTConnectionKitExampleViewController alloc] init];
	nav = [[UINavigationController alloc] initWithRootViewController:viewController];
	[window addSubview:nav.view];
	[viewController release];
    */[window makeKeyAndVisible];
	
	
	DTOAuthRequestTokenConnection *connection = [[DTOAuthRequestTokenConnection alloc] init];
	connection.consumerKey = @"HJzYQhwgALirjCKQaZN0Nw";
	connection.secretConsumerKey = @"MHkk7R4giiVj0qdqvZino1NfbcDjlLeUVkber4URkCA";
	[connection connect];
	[connection release];
}


- (void)dealloc {
	[nav release];
    [window release];
    [super dealloc];
}


@end
