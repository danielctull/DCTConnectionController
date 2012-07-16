//
//  DCTConnectionKitExampleViewController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DCTConnectionController/DCTConnectionController.h>
#import "ViewController.h"

NSString * const ViewControllerStatusString[] = {
	@"NotStarted",
	@"Queued",
	@"Started",
	@"Responded",
	@"Finished",
	@"Failed",
	@"Cancelled"
};

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) return nil;
	self.title = @"DCTConnectionController";
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
		
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
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				
				NSArray *connectionControllers = [[DCTConnectionQueue defaultConnectionQueue] connectionControllers];
				
				NSArray *active = [connectionControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DCTConnectionController *cc, NSDictionary *bindings) {
					return (cc.status > DCTConnectionControllerStatusQueued);
				}]];
				
				NSArray *queued = [connectionControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DCTConnectionController *cc, NSDictionary *bindings) {
					return (cc.status == DCTConnectionControllerStatusQueued);
				}]];
				
				self.activeAmountLabel.text = [NSString stringWithFormat:@"%i", [active count]];
				self.connectionsAmountLabel.text = [NSString stringWithFormat:@"%i", [connectionControllers count]];
				self.queuedAmountLabel.text = [NSString stringWithFormat:@"%i", [queued count]];

				[self log:@"%@ %@", domain, ViewControllerStatusString[status]];
			}];
		}];
		[connectionController enqueue];
	}
	
	/*
	DCTConnectionController *engadget = [[DCTConnectionController alloc] init];
	engadget.URL = [NSURL URLWithString:@"http://www.engadget.com/"];
	[engadget connect];
	
	// Make a duplicate, won't get queued.
	DCTConnectionController *engadget2 = [[DCTConnectionController alloc] init];
	engadget2.URL = [NSURL URLWithString:@"http://www.engadget.com/"];
	engadget.priority = DCTConnectionControllerPriorityHigh;
	[engadget2 connect];
		
	DCTConnectionController *ebay = [[DCTConnectionController alloc] init];
	ebay.URL = [NSURL URLWithString:@"http://www.ebay.com/"];
	ebay.priority = DCTConnectionControllerPriorityLow;
	[ebay connect];
	
	DCTConnectionController *google = [[DCTConnectionController alloc] init];
	google.URL = [NSURL URLWithString:@"http://www.google.com/"];
	google.priority = DCTConnectionControllerPriorityLow;
	[google addDependency:ebay];
	[google connect];
	
	DCTConnectionController *apple = [[DCTConnectionController alloc] init];
	apple.URL = [NSURL URLWithString:@"http://www.apple.com/"];
	apple.priority = DCTConnectionControllerPriorityLow;
	[apple addDependency:google];
	[apple connect];
	
	DCTConnectionController *bbc = [[DCTConnectionController alloc] init];
	bbc.URL = [NSURL URLWithString:@"http://www.bbc.co.uk/"];
	bbc.priority = DCTConnectionControllerPriorityHigh;
	[bbc addDependency:apple];
	[bbc connect];	*/
}

- (void)log:(NSString *)formatString, ... {
	
	BOOL shouldScroll = (self.textView.contentOffset.y + self.textView.bounds.size.height >= self.textView.contentSize.height);
	
	va_list args;
    va_start(args, formatString);
    NSString *string = [[NSString alloc] initWithFormat:formatString arguments:args];
    va_end(args);
	
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"HH:mm:ss.SSS"];
	NSString *dateString = [df stringFromDate:[NSDate date]]; 
	
	NSString *newLine = @"";
	if ([self.textView.text length] > 0) {
		newLine = @"\n";
	}
	
	self.textView.text = [self.textView.text stringByAppendingFormat:@"%@%@ %@", newLine, dateString, string];
	
	if (shouldScroll)
		[self.textView scrollRectToVisible:CGRectMake(0.0, self.textView.contentSize.height - self.textView.bounds.size.height, self.textView.bounds.size.width, self.textView.bounds.size.height) animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
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
