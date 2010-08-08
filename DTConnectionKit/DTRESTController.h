//
//  DTRESTController.h
//  DTConnectionKit
//
//  Created by Daniel Tull on 08/08/2010.
//  Copyright (c) 2010 Daniel Tull. All rights reserved.
//

#import "DTConnectionController.h"


@interface DTRESTController : DTConnectionController {
    NSMutableDictionary *queryParameters, *bodyParameters;
}


- (void)setQueryParameter:(NSString *)parameter forKey:(NSString *)key;
- (void)removeQueryParameterForKey:(NSString *)key;
- (NSString *)queryParameterForKey:(NSString *)key;

- (void)setBodyParameter:(NSString *)parameter forKey:(NSString *)key;
- (void)removeBodyParameterForKey:(NSString *)key;
- (NSString *)bodyParameterForKey:(NSString *)key;
@end
