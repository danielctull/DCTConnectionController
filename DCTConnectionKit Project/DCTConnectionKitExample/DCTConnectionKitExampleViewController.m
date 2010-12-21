//
//  DCTConnectionKitExampleViewController.m
//  DCTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTConnectionKitExampleViewController.h"
#import "DCTURLLoadingConnectionController.h"
#import "DCTConnectionQueue+Singleton.h"

@interface DCTConnectionKitExampleViewController ()
- (NSString *)stringFromURL:(NSURL *)url;
- (void)statusUpdate:(DCTURLLoadingConnectionController *)connectionController;
@end


@implementation DCTConnectionKitExampleViewController

@synthesize textView, toolbar, connectionsLabel;

- (id)init {
	if (!(self = [self initWithNibName:@"DCTConnectionKitExampleView" bundle:nil])) return nil;
	
	self.title = @"DCTConnectionKit";
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[textView release];
    [super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.navigationController.toolbarHidden = NO;
	
	[[DCTConnectionQueue sharedConnectionQueue] setMaxConnections:3];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(connectionCountChanged:) 
												 name:DCTConnectionQueueConnectionCountChangedNotification 
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
		DCTURLLoadingConnectionController *connection = [DCTURLLoadingConnectionController connectionController];
		connection.multitaskEnabled = YES;
		connection.delegate = self;
		connection.URL = [NSURL URLWithString:s];
		[connection addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
		[connection connect];
	}
	
	DCTURLLoadingConnectionController *engadget = [DCTURLLoadingConnectionController connectionController];
	engadget.URL = [NSURL URLWithString:@"http://www.engadget.com/"];
	[engadget addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[engadget connect];
	
	// Make a duplicate, won't get queued.
	DCTURLLoadingConnectionController *engadget2 = [DCTURLLoadingConnectionController connectionController];
	engadget2.URL = [NSURL URLWithString:@"http://www.engadget.com/"];
	[engadget2 addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	engadget.priority = DCTConnectionControllerPriorityHigh;
	[engadget2 connect];
		
	DCTURLLoadingConnectionController *ebay = [DCTURLLoadingConnectionController connectionController];
	ebay.URL = [NSURL URLWithString:@"http://www.ebay.com/"];
	ebay.priority = DCTConnectionControllerPriorityLow;
	[ebay addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[ebay addObserver:self forKeyPath:@"percentDownloaded" options:NSKeyValueObservingOptionNew context:nil];	
	[ebay connect];
	
	DCTURLLoadingConnectionController *google = [DCTURLLoadingConnectionController connectionController];
	google.URL = [NSURL URLWithString:@"http://www.google.com/"];
	google.priority = DCTConnectionControllerPriorityLow;
	[google addDependency:ebay];
	[google addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[google connect];
	
	DCTURLLoadingConnectionController *apple = [DCTURLLoadingConnectionController connectionController];
	apple.URL = [NSURL URLWithString:@"http://www.apple.com/"];
	apple.priority = DCTConnectionControllerPriorityLow;
	[apple addDependency:google];
	[apple addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[apple connect];
	
	DCTURLLoadingConnectionController *bbc = [DCTURLLoadingConnectionController connectionController];
	bbc.URL = [NSURL URLWithString:@"http://www.bbc.co.uk/"];
	bbc.priority = DCTConnectionControllerPriorityHigh;
	[bbc addDependency:apple];
	[bbc addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[bbc connect];
	
	self.toolbarItems = self.toolbar.items;
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	DCTURLLoadingConnectionController *connectionController = (DCTURLLoadingConnectionController *)object;
	
	if ([keyPath isEqualToString:@"percentDownloaded"]) {
		NSLog(@"%@", connectionController.percentDownloaded);
		return;
	}
	
	[self statusUpdate:connectionController];
}
	
- (void)statusUpdate:(DCTURLLoadingConnectionController *)connectionController {
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"HH:mm:ss.SSS"];
	NSString *dateString = [df stringFromDate:[NSDate date]]; 
	[df release];
		
	NSString *newLine = @"";
	if ([self.textView.text length] > 0) {
		newLine = @"\n";
	}
	 
	NSString *logPrefixString = [NSString stringWithFormat:@"%@ %@: ", dateString, [self stringFromURL:connectionController.URL]];
	NSString *prefixString = [NSString stringWithFormat:@"%@%@ %@: ", newLine, dateString, [self stringFromURL:connectionController.URL]];
	
	switch (connectionController.status) {
		case DCTConnectionControllerStatusStarted:
			NSLog(@"%@Started", logPrefixString);
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Started", prefixString];
			break;
		case DCTConnectionControllerStatusQueued:
			NSLog(@"%@Queued", logPrefixString);
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Queued", prefixString];
			break;
		case DCTConnectionControllerStatusFailed:
			NSLog(@"%@Failed", logPrefixString);
			[connectionController removeObserver:self forKeyPath:@"status"];
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Failed", prefixString];
			break;
		case DCTConnectionControllerStatusNotStarted:
			NSLog(@"%@Not Started", logPrefixString);
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Not Started", prefixString];
			break;
		case DCTConnectionControllerStatusResponded:
			NSLog(@"%@Responded", logPrefixString);
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Responded", prefixString];
			break;
		case DCTConnectionControllerStatusComplete:
			NSLog(@"%@Complete", logPrefixString);
			[connectionController removeObserver:self forKeyPath:@"status"];
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Complete", prefixString];
			break;
		case DCTConnectionControllerStatusCancelled:
			NSLog(@"%@Cancelled", logPrefixString);
			[connectionController removeObserver:self forKeyPath:@"status"];
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
	self.connectionsLabel.text = [NSString stringWithFormat:@"Connections: %i", [DCTConnectionQueue sharedConnectionQueue].activeConnectionCount];
}

@end
