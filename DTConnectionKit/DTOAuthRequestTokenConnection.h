//
//  DTOAuthRequestTokenConnection.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTConnection.h"
/* oauth_callback
 - http://localhost:3005/the_dance/process_callback?service_provider_id=11
 oauth_consumer_key
 - GDdmIQH6jhtmLUypg82g
 oauth_nonce
 - QP70eNmVz8jvdPevU3oJD2AfF7R7odC2XJcn4XlZJqk
 oauth_signature_method
 - HMAC-SHA1
 oauth_timestamp
 - 1272323042
 oauth_version
 - 1.0*/
@interface DTOAuthRequestTokenConnection : DTConnection {
	NSArray *keys;
	NSDictionary *dictionary;
}
@property (nonatomic, copy) NSString *nonce;
@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *version;


- (NSString *)versionString;
- (NSString *)nonceString;
- (NSString *)consumerKeyString;
- (NSString *)signatureMethodStringForMethod:(NSString *)method;
- (NSString *)timestampString;

- (NSString *)stringForKey:(NSString *)key value:(NSString *)value;

@end
