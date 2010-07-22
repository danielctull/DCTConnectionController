//
//  DTOAuthSignature.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	DTOAuthSignatureTypeHMAC_SHA1 = 0,
	DTOAuthSignatureTypePlaintext
} DTOAuthSignatureType;

@interface DTOAuthSignature : NSObject {
}

@property (nonatomic, assign) DTOAuthSignatureType type;
@property (nonatomic, copy) NSString *secret;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, readonly) NSString *signature;
- (NSString *)typeString;
@end
