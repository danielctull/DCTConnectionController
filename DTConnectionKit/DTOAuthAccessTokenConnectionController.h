//
//  DTOAuthAccessTokenConnection.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 05.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "DTOAuthConnectionController.h"

@interface DTOAuthAccessTokenConnection : DTOAuthConnectionController {
}
@property (nonatomic, retain) NSString *token;
@end
