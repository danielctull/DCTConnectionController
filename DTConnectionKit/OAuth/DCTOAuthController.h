//
//  DTOAuthController.h
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//


#import "DCTConnectionController.h"
#import "DCTOAuthRequestTokenConnectionController.h"
#import "DCTOAuthAccessTokenConnectionController.h"

extern NSString *const DTOAuthCallBackNotification;

@protocol DCTOAuthControllerDelegate;

@interface DCTOAuthController : NSObject <DTConnectionControllerDelegate> {
	DCTOAuthRequestTokenConnectionController *requestTokenConnection;
	DCTOAuthAccessTokenConnectionController *accessTokenConnection;	
}





// Provide the folling in a subclass.

- (NSURL *)accessTokenConnectionURL;
- (DCTConnectionType)accessTokenConnectionType;

- (NSURL *)requestTokenConnectionURL;
- (DCTConnectionType)requestTokenConnectionType;

- (NSString *)consumerKey;
- (NSString *)secretConsumerKey;

- (NSString *)serviceName;
- (NSURL *)userAuthPageURL;








+ (void)postHandledURLNotification:(NSURL *)url;



@property (nonatomic, readonly) NSString *callback;
@property (nonatomic, assign) BOOL canLogin;
@property (nonatomic, retain) NSString *oauthToken;
@property (nonatomic, retain) NSString *oauthTokenSecret;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, assign) id<DCTOAuthControllerDelegate> delegate;
- (void)login;

@end




@protocol DCTOAuthControllerDelegate <NSObject>

- (void)oauthControllerDidComplete:(DCTOAuthController *)oauthController;

@end