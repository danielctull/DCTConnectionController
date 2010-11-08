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
#import "DCTConnectionMonitor.h"
#import "DCTiOSConnectionQueue.h"
#import "DCTConnectionQueue+Singleton.h"

@implementation DCTConnectionKitAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
	DCTConnectionMonitor *m = [[DCTConnectionMonitor alloc] init];
	
	DCTiOSConnectionQueue *q = [DCTiOSConnectionQueue sharedConnectionQueue];
	
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
