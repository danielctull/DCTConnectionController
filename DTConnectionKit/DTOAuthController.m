//
//  DTOAuthController.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 09.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthController.h"
#import "NSString+DTURLEncoding.h"

NSString *const DTOAuthCallBackNotification = @"DTOAuthCallBackNotification";

@interface DTOAuthController ()
- (void)tryRequestTokenConnection;
@end



@implementation DTOAuthController

@synthesize canLogin;
@synthesize consumerKey, secretConsumerKey;

@synthesize requestTokenConnectionType, requestTokenConnectionURL, accessTokenConnectionType, accessTokenConnectionURL;


- (id)init {
	
	if (!(self = [super init])) return nil;
	
	requestTokenConnection = [[DTOAuthRequestTokenConnection alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(url:) name:DTOAuthCallBackNotification object:nil];	
	
	return self;	
}

- (void)dealloc {
	[requestTokenConnection release];
	[super dealloc];
}

- (void)dtconnection:(DTConnection *)connection didSucceedWithObject:(NSObject *)object {
	
	if ([connection isEqual:requestTokenConnection]) {
		
		
		
		
		
		
		
		
		
		
	}
	
	NSDictionary *d = (NSDictionary *)object;
	
	NSLog(@"%@", d);
	/*
	oAuthToken = [[d objectForKey:DTOAuthTokenKey] retain];
	
	[UIView animateWithDuration:0.35 animations:^{
		self.loginButton.alpha = 1.0;
	}];
	*/
}

- (void)setConsumerKey:(NSString *)s {
	
	if ([s isEqualToString:consumerKey]) return;
	
	[consumerKey release];
	consumerKey = [s retain];
	
	[self tryRequestTokenConnection];
}

- (void)tryRequestTokenConnection {
	
	if (requestTokenConnection || !self.consumerKey || !self.secretConsumerKey) return;
	
	requestTokenConnection = [DTOAuthRequestTokenConnection connection];
	requestTokenConnection.URL = self.requestTokenConnectionURL;
	requestTokenConnection.type = self.requestTokenConnectionType;
	requestTokenConnection.consumerKey = self.consumerKey;
	requestTokenConnection.secretConsumerKey = self.secretConsumerKey;
	
	[requestTokenConnection setValue:[[NSString stringWithFormat:@"%@://oauth/%@", [self schemeDefinedInInfoPlist], self.serviceName] dt_urlEncodedString] forParameter:DTOAuthCallBackKey];
	
	
	
	requestTokenConnection.delegate = self;
	[requestTokenConnection connect];
	
}

- (void)login {
	
	
	
	
}

- (NSString *)schemeDefinedInInfoPlist {
	
	
	NSObject *o = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLSchemes"];
	
	NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), o);
	

	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	
	NSObject *typesObject = [info objectForKey:@"CFBundleURLTypes"];
	
	if ([typesObject isKindOfClass:[NSArray class]]) {
	
		NSArray *types = (NSArray *)typesObject;
	
		for (NSObject *typeObject in types) {
		
			if ([typeObject isKindOfClass:[NSDictionary class]]) {
		
				NSObject *schemesObject = [(NSDictionary *)typeObject objectForKey:@"CFBundleURLSchemes"];
			
				if ([schemesObject isKindOfClass:[NSArray class]]) {
				
					NSArray *schemes = (NSArray *)schemesObject;
			
					for (NSObject *schemeObject in schemes) {
						
						if ([schemeObject isKindOfClass:[NSString class]]) return (NSString *)schemeObject;
					
					}
				}
			}
		}
	}
	return @"";	
}

+ (void)postHandledURLNotification:(NSURL *)url {
	
	if (![[url host] isEqualToString:@"oauth"]) return;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTOAuthCallBackNotification object:url];
}

@end
