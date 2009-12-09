//
//  DTRestCommand.m
//  DTKit
//
//  Created by Daniel Tull on 05.10.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import "DTRestCommand.h"

NSString * const RestTypeStrings[] = {
	@"GET",
	@"POST",
	@"PUT",
	@"DELETE"
};

NSString *const DTRestCommandCompletedSuccessfullyNotification = @"DTRestCommandCompletedSuccessfullyNotification";
NSString *const DTRestCommandFailedWithErrorNotification = @"DTRestCommandFailedWithErrorNotification";

@implementation DTRestCommand
@synthesize delegate, type, returnedData, error;

- (id)init {
	
	if (!(self = [super init])) return nil;
	
	type = DTRestCommandTypeGet;
	delegate = nil;
	
	return self;
	
}

- (id)initWithType:(DTRestCommandType)aType {
	
	if (!(self = [self init])) return nil;
	
	type = aType;
	
	returnedData = nil;
	error = nil;	
	
	return self;
}

- (id)initWithDelegate:(NSObject<DTRestCommandDelegate> *)aDelegate type:(DTRestCommandType)aType {
	
	if (!(self = [self initWithType:aType])) return nil;
	
	delegate = [aDelegate retain];	
		
	return self;
}

- (void)dealloc {
	[delegate release];
	delegate = nil;
	[super dealloc];
}

- (void)start {
	NSURLRequest *request = [self newRequest];
	[DTConnectionManager makeRequest:request delegate:self];
	[request release];
}

- (void)startRequest {
	[self start];
}

- (NSMutableURLRequest *)newRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setHTTPMethod:RestTypeStrings[type]];
	return request;
}

- (BOOL)delegateRespondsToFailureSelector {
	return [self.delegate respondsToSelector:@selector(restCommand:didFailWithError:)];
}

- (BOOL)delegateRespondsToReturnedObjectsSelector {
	return [self.delegate respondsToSelector:@selector(restCommand:didSucceedWithObjects:)];
}

- (BOOL)delegateRespondsToReturnedObjectSelector {
	return [self.delegate respondsToSelector:@selector(restCommand:didSucceedWithObject:)];
}


- (BOOL)sendObjectToDelegate:(id)object {
	returnedData = [object retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:DTRestCommandCompletedSuccessfullyNotification object:self];
	
	if (![self delegateRespondsToReturnedObjectSelector])
		return NO;
	
	[self.delegate restCommand:self didSucceedWithObject:object];
	return YES;
}

- (BOOL)sendObjectsToDelegate:(NSArray *)array {
	
	returnedData = [array retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:DTRestCommandCompletedSuccessfullyNotification object:self];
	
	if (![self delegateRespondsToReturnedObjectsSelector])
		return NO;
		
	[self.delegate restCommand:self didSucceedWithObjects:array];
	return YES;
}


- (BOOL)sendErrorToDelegate:(NSError *)anError {
	
	error = [anError retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:DTRestCommandFailedWithErrorNotification object:self];
	
	if (![self delegateRespondsToFailureSelector])
		return NO;
	
	[self.delegate restCommand:self didFailWithError:error];
	return YES;
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connection:(DTURLConnection *)connection didFailWithError:(NSError *)anError {
	//NSLog(@"%@:%s:%@.", self, _cmd, anError);
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connection:(DTURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	//NSLog(@"%@:%s Not handling this event.", self, _cmd);
}

- (void)connectionManager:(DTConnectionManager *)connectionManager connectionDidFinishLoading:(DTURLConnection *)connection {
	//NSLog(@"%@:%s Not handling this event.", self, _cmd);
}

@end
