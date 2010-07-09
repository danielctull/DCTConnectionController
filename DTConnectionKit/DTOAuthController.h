//
//  DTOAuthController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//


#import "DTConnection.h"
#import "DTOAuthRequestTokenConnection.h"
#import "DTOAuthAccessTokenConnection.h"

extern NSString *const DTOAuthCallBackNotification;

@interface DTOAuthController : NSObject <DTConnectionDelegate> {
	DTOAuthRequestTokenConnection *requestTokenConnection;
	DTOAuthAccessTokenConnection *accessTokenConnection;
	
	NSString *oauthTokenSecret;
	
}





// Provie the folling in a subclass.

@property (nonatomic, readonly) NSString *consumerKey;
@property (nonatomic, readonly) NSString *secretConsumerKey;
@property (nonatomic, readonly) NSString *serviceName;

@property (nonatomic, readonly) DTConnectionType requestTokenConnectionType;
@property (nonatomic, readonly) NSURL *requestTokenConnectionURL;

@property (nonatomic, readonly) DTConnectionType accessTokenConnectionType;
@property (nonatomic, readonly) NSURL *accessTokenConnectionURL;



@property (nonatomic, assign) BOOL canLogin;

- (void)login;

@end
