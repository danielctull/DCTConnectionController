//
//  DTGenericRestCommand.h
//  Tesco
//
//  Created by Daniel Tull on 07.10.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import "DTRestCommand.h"


@interface DTGenericRestCommand : DTRestCommand {
	NSString *urlString;
}

- (id)initWithDelegate:(NSObject<DTRestCommandDelegate> *)aDelegate urlString:(NSString *)aUrlString;
+ (DTGenericRestCommand *)restCommandWithDelegate:(NSObject<DTRestCommandDelegate> *)aDelegate urlString:(NSString *)aUrlString;

@end
