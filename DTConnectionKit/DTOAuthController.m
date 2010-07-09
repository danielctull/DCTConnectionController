//
//  DTOAuthController.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthController.h"
#import "NSString+DTURLEncoding.h"
#import "NSBundle+DTInfoPlist.h"

NSString *const DTOAuthCallBackNotification = @"DTOAuthCallBackNotification";

@interface DTOAuthController ()
- (void)tryRequestTokenConnection;
- (void)tryAccessTokenConnectionWithParameters:(NSDictionary *)parameters;
- (NSString *)schemeDefinedInInfoPlist;
- (void)url:(NSNotification *)notification;
@end



@implementation DTOAuthController

@synthesize canLogin;

// Things to provide in a subclass.
@synthesize consumerKey, secretConsumerKey, requestTokenConnectionType, requestTokenConnectionURL, accessTokenConnectionType, accessTokenConnectionURL, serviceName;

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(url:) name:DTOAuthCallBackNotification object:nil];	
	
	return self;	
}

- (void)dealloc {
	[requestTokenConnection release];
	[super dealloc];
}

- (void)url:(NSNotification *)notification {
	
	NSURL *url = [notification object];
	
	NSString *s = [url query];
	
	NSDictionary *d = [DTOAuthConnection oauthDictionaryFromString:s];
	
	[self tryAccessTokenConnectionWithParameters:d];	
	
}

- (void)dtconnection:(DTConnection *)connection didSucceedWithObject:(NSObject *)object {
	
	if ([connection isEqual:requestTokenConnection]) {
		
		NSDictionary *d = (NSDictionary *)object;
		
		oauthTokenSecret = [[d objectForKey:DTOAuthTokenSecretKey] retain];
		
		self.canLogin = YES;
		
	}
	
	
	if ([connection isEqual:accessTokenConnection]) {
	
		NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), object);
	}
	
}

- (void)setConsumerKey:(NSString *)s {
	
	if ([s isEqualToString:consumerKey]) return;
	
	[consumerKey release];
	consumerKey = [s retain];
	
	[self tryRequestTokenConnection];
}

- (void)tryRequestTokenConnection {
	
	if (requestTokenConnection || !self.consumerKey || !self.secretConsumerKey) return;
	
	requestTokenConnection = [[DTOAuthRequestTokenConnection alloc] init];
	requestTokenConnection.URL = self.requestTokenConnectionURL;
	requestTokenConnection.type = self.requestTokenConnectionType;
	requestTokenConnection.consumerKey = self.consumerKey;
	requestTokenConnection.secretConsumerKey = self.secretConsumerKey;
	
	[requestTokenConnection setValue:[[NSString stringWithFormat:@"%@://oauth/%@", [self schemeDefinedInInfoPlist], self.serviceName] dt_urlEncodedString] forParameter:DTOAuthCallBackKey];
	
	requestTokenConnection.delegate = self;
	[requestTokenConnection connect];
	
}

- (void)tryAccessTokenConnectionWithParameters:(NSDictionary *)parameters {
	
	accessTokenConnection = [[DTOAuthAccessTokenConnection alloc] init];
	
	for (NSString *key in parameters)
		[accessTokenConnection setValue:[parameters objectForKey:key] forParameter:key];	
	
	accessTokenConnection.URL = self.accessTokenConnectionURL;
	accessTokenConnection.type = self.accessTokenConnectionType;
	accessTokenConnection.consumerKey = self.consumerKey;
	accessTokenConnection.secretConsumerKey = self.secretConsumerKey;
	accessTokenConnection.secretToken = oauthTokenSecret;
	
	[accessTokenConnection connect];
	
}

- (void)login {
	
	
	
	
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











@end
