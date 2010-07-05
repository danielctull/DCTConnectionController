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
#import "DTOAuthAccessTokenConnection.h"

@implementation DTConnectionKitAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	/*DTConnectionKitExampleViewController *viewController = [[DTConnectionKitExampleViewController alloc] init];
	nav = [[UINavigationController alloc] initWithRootViewController:viewController];
	[window addSubview:nav.view];
	[viewController release];
    */[window makeKeyAndVisible];
	
	
	DTOAuthRequestTokenConnection *connection = [DTOAuthRequestTokenConnection connection];
	connection.URL = [NSURL URLWithString:@"http://term.ie/oauth/example/request_token.php"];
	connection.type = DTConnectionTypeGet;
	connection.consumerKey = @"key";
	connection.secretConsumerKey = @"secret";
	[connection connect];
	
	DTOAuthAccessTokenConnection *accessTokenConnection = [DTOAuthAccessTokenConnection connection];
	accessTokenConnection.URL = [NSURL URLWithString:@"http://term.ie/oauth/example/access_token.php"];
	accessTokenConnection.type = DTConnectionTypeGet;
	accessTokenConnection.consumerKey = @"key";
	accessTokenConnection.secretConsumerKey = @"secret";
	accessTokenConnection.token = @"requestkey";
	accessTokenConnection.secretToken = @"requestsecret";
	[accessTokenConnection connect];
	
	
}


- (void)dealloc {
	[nav release];
    [window release];
    [super dealloc];
}


@end
