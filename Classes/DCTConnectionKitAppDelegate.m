//
//  DCTConnectionKitAppDelegate.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.12.2009.
//  Copyright Daniel Tull 2009. All rights reserved.
//

#import "DCTConnectionKitAppDelegate.h"
#import "DCTConnectionKitExampleViewController.h"
#import "DCTOAuthRequestTokenConnectionController.h"
#import "DCTOAuthAccessTokenConnectionController.h"
#import "DCTOAuthController.h"
#import "DCTiOSConnectionQueue.h"
#import "DCTConnectionQueue+Singleton.h"

#import "DCTURLLoadingConnectionController.h"
#import "DCTConnectionController+DCTEquality.h"

@implementation DCTConnectionKitAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	/*
	DCTURLLoadingConnectionController *c = [[DCTURLLoadingConnectionController alloc] init];
	c.URL = [NSURL URLWithString:@"www.google.com"];
	c.delegate = self;
	DCTConnectionController *cRunning = [c connect];
	
	DCTURLLoadingConnectionController *c2 = [[DCTURLLoadingConnectionController alloc] init];
	c2.URL = [NSURL URLWithString:@"www.google.com"];
	c2.delegate = self;
	DCTConnectionController *c2Running = [c2 connect];
	*/
	DCTiOSConnectionQueue *queue = (DCTiOSConnectionQueue *)[DCTiOSConnectionQueue sharedConnectionQueue];
	queue.multitaskEnabled = YES;
	queue.maxConnections = 4;
	
	DCTConnectionKitExampleViewController *viewController = [[DCTConnectionKitExampleViewController alloc] init];
	nav = [[UINavigationController alloc] initWithRootViewController:viewController];
	[window addSubview:nav.view];
	[viewController release];
    [window makeKeyAndVisible];
	/*
	
	DTOAuthRequestTokenConnection *connection = [DTOAuthRequestTokenConnection connectionController];
	connection.URL = [NSURL URLWithString:@"http://term.ie/oauth/example/request_token.php"];
	connection.type = DCTConnectionControllerTypeGet;
	connection.consumerKey = @"key";
	connection.secretConsumerKey = @"secret";
	[connection connect];
	
	DTOAuthAccessTokenConnection *accessTokenConnection = [DTOAuthAccessTokenConnection connectionController];
	accessTokenConnection.URL = [NSURL URLWithString:@"http://term.ie/oauth/example/access_token.php"];
	accessTokenConnection.type = DCTConnectionControllerTypeGet;
	accessTokenConnection.consumerKey = @"key";
	accessTokenConnection.secretConsumerKey = @"secret";
	accessTokenConnection.token = @"requestkey";
	accessTokenConnection.secretToken = @"requestsecret";
	[accessTokenConnection connect];
*/		
}


- (void)dealloc {
	[nav release];
    [window release];
    [super dealloc];
}


@end
