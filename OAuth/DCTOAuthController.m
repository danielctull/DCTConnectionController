//
//  DTOAuthController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 09.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "DCTOAuthController.h"
#import "NSString+DTURLEncoding.h"
#import "NSBundle+DTInfoPlist.h"

NSString *const DTOAuthCallBackNotification = @"DTOAuthCallBackNotification";

@interface DCTOAuthController ()
- (void)tryRequestTokenConnection;
- (void)tryAccessTokenConnectionWithParameters:(NSDictionary *)parameters;
- (NSString *)schemeDefinedInInfoPlist;
- (void)url:(NSNotification *)notification;
@end



@implementation DCTOAuthController

@synthesize canLogin;

@synthesize oauthToken, oauthTokenSecret, username, delegate;

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(url:) name:DTOAuthCallBackNotification object:nil];
	[self tryRequestTokenConnection];
	
	return self;	
}

- (void)dealloc {
	[requestTokenConnection release];
	[super dealloc];
}

- (void)url:(NSNotification *)notification {
	
	self.canLogin = NO;
	
	NSURL *url = [notification object];
	
	NSString *s = [url query];
	
	NSDictionary *d = [DCTOAuthConnectionController oauthDictionaryFromString:s];
	
	NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), d);
	
	[self tryAccessTokenConnectionWithParameters:d];	
	
}

- (void)connectionController:(DCTConnectionController *)connectionController didSucceedWithObject:(NSObject *)object {
	
	NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), object);
	
	if ([connectionController isEqual:requestTokenConnection]) {
		
		NSDictionary *d = (NSDictionary *)object;
		
		self.oauthTokenSecret = [d objectForKey:DCTOAuthVerifierKey];
		self.oauthToken = [d objectForKey:DCTOAuthTokenKey];
		
		self.canLogin = YES;
		
	} else if ([connectionController isEqual:accessTokenConnection]) {
		
		NSDictionary *d = (NSDictionary *)object;
		
		self.oauthTokenSecret = [d objectForKey:DCTOAuthVerifierKey];
		self.oauthToken = [d objectForKey:DCTOAuthTokenKey];
		self.username = [d objectForKey:@"screen_name"];
		
		if ([self.delegate respondsToSelector:@selector(oauthControllerDidComplete:)])
			[self.delegate oauthControllerDidComplete:self];
		
		//NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), object);
	}
	
}

- (void)tryRequestTokenConnection {
	
	if (requestTokenConnection || !self.consumerKey || !self.secretConsumerKey) return;
	
	requestTokenConnection = [[DCTOAuthRequestTokenConnectionController alloc] init];
	// TODO: requestTokenConnection.URL = [self requestTokenConnectionURL];
	requestTokenConnection.type = [self requestTokenConnectionType];
	requestTokenConnection.consumerKey = [self consumerKey];
	requestTokenConnection.secretConsumerKey = [self secretConsumerKey];
	requestTokenConnection.callback = self.callback;
	
	requestTokenConnection.delegate = self;
	[requestTokenConnection connect];
	
}

- (void)tryAccessTokenConnectionWithParameters:(NSDictionary *)parameters {
	
	accessTokenConnection = [[DCTOAuthAccessTokenConnectionController alloc] init];
	
	//for (NSString *key in parameters)
	//	[accessTokenConnection setValue:[parameters objectForKey:key] forParameter:key];	
	
	// TODO: accessTokenConnection.URL = [self accessTokenConnectionURL];
	accessTokenConnection.type = [self accessTokenConnectionType];
	accessTokenConnection.consumerKey = [self consumerKey];
	accessTokenConnection.secretConsumerKey = [self secretConsumerKey];
	accessTokenConnection.secretToken = self.oauthTokenSecret;
	
	accessTokenConnection.delegate = self;
	[accessTokenConnection connect];
	
}

- (void)login {
	
	if (!self.canLogin) return;
	
	[[UIApplication sharedApplication] openURL:[self userAuthPageURL]];	
}

- (NSString *)schemeDefinedInInfoPlist {
	
	NSObject *object = [[NSBundle mainBundle] dt_deepObjectForInfoDictionaryKey:@"CFBundleURLSchemes"];
	
	if (![object isKindOfClass:[NSArray class]]) return @"";
	
	NSArray *array = (NSArray *)object;
	
	for (NSObject *o in array)
		if ([o isKindOfClass:[NSString class]])
			return (NSString *)o;
	
	return @"";
}

+ (void)postHandledURLNotification:(NSURL *)url {
	
	if (![[url host] isEqualToString:@"oauth"]) return;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTOAuthCallBackNotification object:url];
}

- (NSURL *)accessTokenConnectionURL {
	return [NSURL URLWithString:@""];
}

- (DCTConnectionType)accessTokenConnectionType {
	return DCTConnectionControllerTypeGet;
}

- (NSURL *)requestTokenConnectionURL {
	return [NSURL URLWithString:@""];
}

- (DCTConnectionType)requestTokenConnectionType {
	return DCTConnectionControllerTypeGet;
}

- (NSString *)consumerKey {
	return @"";
}

- (NSString *)secretConsumerKey {
	return @"";
}

- (NSString *)serviceName {
	return @"";
}

- (NSURL *)userAuthPageURL {
	return [NSURL URLWithString:@""];
}

- (NSString *)callback {
	return [[NSString stringWithFormat:@"%@://oauth/%@", [self schemeDefinedInInfoPlist], self.serviceName] dt_urlEncodedString];
}




@end
