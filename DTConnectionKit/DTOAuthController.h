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
}





// Provide the folling in a subclass.

- (NSURL *)accessTokenConnectionURL;
- (DTConnectionType)accessTokenConnectionType;

- (NSURL *)requestTokenConnectionURL;
- (DTConnectionType)requestTokenConnectionType;

- (NSString *)consumerKey;
- (NSString *)secretConsumerKey;

- (NSString *)serviceName;
- (NSURL *)userAuthPageURL;








+ (void)postHandledURLNotification:(NSURL *)url;



@property (nonatomic, readonly) NSString *callback;
@property (nonatomic, assign) BOOL canLogin;
@property (nonatomic, readonly) NSString *oauthToken;
@property (nonatomic, readonly) NSString *oauthTokenSecret;

- (void)login;

@end
