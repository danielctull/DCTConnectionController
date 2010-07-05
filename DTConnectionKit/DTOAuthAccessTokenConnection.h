//
//  DTOAuthAccessTokenConnection.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthConnection.h"

@interface DTOAuthAccessTokenConnection : DTOAuthConnection {
}
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSString *verifier;
@end
