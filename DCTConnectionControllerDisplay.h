//
//  DCTConnectionControllerDisplay.h
//  DCTConnectionController
//
//  Created by Daniel Tull on 11.11.2011.
//  Copyright (c) 2011 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const DCTConnectionControllerNeedsDisplayNotification;

@protocol DCTConnectionControllerDisplay <NSObject>
- (void)dismissConnectionControllerDisplay;
@end

@protocol DCTDisplayableConnectionController <NSObject>
- (BOOL)connectionControllerDisplay:(id<DCTConnectionControllerDisplay>)connectionControllerDisplay shouldLoadURLRequest:(NSURLRequest *)urlRequest;
@end
