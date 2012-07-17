//
//  AppDelegate.m
//  Mac Demo
//
//  Created by Daniel Tull on 06/07/2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "AppDelegate.h"
#import <DCTConnectionController/DCTConnectionController.h>

NSString * const ViewControllerStatusString[] = {
	@"NotStarted",
	@"Queued",
	@"Started",
	@"Responded",
	@"Completed",
	@"Failed",
	@"Cancelled"
};

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	NSArray *urls = @[@"http://www.tesco.com/",
	@"http://www.nike.com/",
	@"http://www.coca-cola.com/",
	@"http://www.no.danieltull.co.uk/",
	@"http://www.oakley.com/",
	@"http://www.sky.com/",
	@"http://www.yahoo.com/",
	@"http://www.microsoft.com/",
	@"http://www.play.com/"];

	for (NSString *s in urls) {
		NSURL *URL = [NSURL URLWithString:s];
		DCTConnectionController *connectionController = [[DCTConnectionController alloc] initWithURL:URL];
		NSString *domain = [self _domainStringFromURL:connectionController.URLRequest.URL];

		[connectionController addStatusChangeHandler:^(DCTConnectionControllerStatus status) {
			NSLog(@"%@:%@ %@ %@", self, NSStringFromSelector(_cmd), domain, ViewControllerStatusString[status]);
		}];
		[connectionController enqueue];
	}
}

- (NSString *)_domainStringFromURL:(NSURL *)URL {
	NSString *urlString = [URL absoluteString];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"www." withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".com/" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".co.uk/" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".com" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".co.uk" withString:@""];
	return urlString;

}

@end
