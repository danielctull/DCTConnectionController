//
//  DCTConnectionKitExampleViewController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTConnectionControllerDemoViewController.h"
#import "DCTConnectionController.h"
#import "DCTConnectionQueue+Singleton.h"
#import "DCTNetworkActivityIndicatorController.h"

@interface DCTConnectionControllerDemoViewController ()
- (NSString *)stringFromURL:(NSURL *)url;
- (void)statusUpdatedNotification:(NSNotification *)notification;
@end


@implementation DCTConnectionControllerDemoViewController

@synthesize textView, toolbar;
@synthesize activeAmountLabel, connectionsAmountLabel, queuedAmountLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) return nil;
	
	self.title = @"DCTConnectionController";
	
	//DCTNetworkActivityIndicatorController *indicatorController = [DCTNetworkActivityIndicatorController sharedNetworkActivityIndicatorController];
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self
						   selector:@selector(connectionCountChanged:) 
							   name:DCTNetworkActivityIndicatorControllerNetworkActivityChangedNotification
							 object:nil];
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:DCTConnectionQueueConnectionCountChangedNotification
												  object:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
		
	self.navigationController.toolbarHidden = NO;
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(connectionCountChanged:) 
												 name:DCTConnectionQueueConnectionCountChangedNotification 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(statusUpdatedNotification:)
												 name:DCTConnectionControllerStatusChangedNotification
											   object:nil];
	
	NSArray *urls = [NSArray arrayWithObjects:
					 @"http://www.tesco.com/",
					 @"http://www.nike.com/",
					 @"http://www.coca-cola.com/",
					 @"http://www.no.danieltull.co.uk/", 
					 @"http://www.oakley.com/",
					 @"http://www.sky.com/",
					 @"http://www.yahoo.com/",
					 @"http://www.microsoft.com/",
					 @"http://www.play.com/",
					 nil];
	
	for (NSString *s in urls) {
		DCTConnectionController *connection = [[DCTConnectionController alloc] init];
		connection.multitaskEnabled = YES;
		connection.delegate = self;
		connection.URL = [NSURL URLWithString:s];
		[connection connect];
	}
	
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
	[bbc connect];
	
	self.toolbarItems = self.toolbar.items;
	
}
	
- (void)statusUpdatedNotification:(NSNotification *)notification {
	
	DCTConnectionController *connectionController = [notification object];
	
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"HH:mm:ss.SSS"];
	NSString *dateString = [df stringFromDate:[NSDate date]]; 
		
	NSString *newLine = @"";
	if ([self.textView.text length] > 0) {
		newLine = @"\n";
	}
	
	NSString *prefixString = [NSString stringWithFormat:@"%@%@ %@: ", newLine, dateString, [self stringFromURL:connectionController.URL]];
	
	switch (connectionController.status) {
		case DCTConnectionControllerStatusStarted:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Started", prefixString];
			break;
		case DCTConnectionControllerStatusQueued:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Queued", prefixString];
			break;
		case DCTConnectionControllerStatusFailed:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Failed", prefixString];
			break;
		case DCTConnectionControllerStatusNotStarted:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Not Started", prefixString];
			break;
		case DCTConnectionControllerStatusResponded:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Responded", prefixString];
			break;
		case DCTConnectionControllerStatusFinished:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Finished", prefixString];
			break;
		case DCTConnectionControllerStatusCancelled:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%Cancelled", prefixString];
			break;
		default:
			break;
	}
	
	[self.textView scrollRectToVisible:CGRectMake(0.0, self.textView.contentSize.height - self.textView.bounds.size.height, self.textView.bounds.size.width, self.textView.bounds.size.height) animated:NO];
}

- (NSString *)stringFromURL:(NSURL *)url {
	NSString *urlString = [url absoluteString];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@"www." withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".com/" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".co.uk/" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".com" withString:@""];
	urlString = [urlString stringByReplacingOccurrencesOfString:@".co.uk" withString:@""];
	return urlString;
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}

- (void)connectionCountChanged:(NSNotification *)notification {
	DCTConnectionQueue *queue = [DCTConnectionQueue sharedConnectionQueue];
	
	self.connectionsAmountLabel.text = [NSString stringWithFormat:@"%i", queue.connectionCount];
	self.queuedAmountLabel.text = [NSString stringWithFormat:@"%i", [queue.queuedConnectionControllers count]];
	self.activeAmountLabel.text = [NSString stringWithFormat:@"%i", [[DCTNetworkActivityIndicatorController sharedNetworkActivityIndicatorController] networkActivity]];
}

@end