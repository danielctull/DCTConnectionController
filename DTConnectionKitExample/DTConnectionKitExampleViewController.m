//
//  DTConnectionKitExampleViewController.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import "DTConnectionKitExampleViewController.h"
#import "DTURLLoadingConnectionController.h"
#import "DTConnectionQueue+DTSingleton.h"

@interface DTConnectionKitExampleViewController ()
- (NSString *)stringFromURL:(NSURL *)url;
- (void)statusUpdate:(DTURLLoadingConnectionController *)connectionController;
@end


@implementation DTConnectionKitExampleViewController

@synthesize textView, toolbar, connectionsLabel;

- (id)init {
	if (!(self = [self initWithNibName:@"DTConnectionKitExampleView" bundle:nil])) return nil;
	
	self.title = @"DTConnectionKit";
	
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
	
	[[DTConnectionQueue sharedConnectionQueue] setMaxConnections:3];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(connectionCountChanged:) 
												 name:DTConnectionQueueConnectionCountChangedNotification 
											   object:nil];
	NSLog(@"%@", self);
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
		DTURLLoadingConnectionController *connection = [DTURLLoadingConnectionController connectionController];
		connection.delegate = self;
		connection.URL = [NSURL URLWithString:s];
		[connection addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
		[connection connect];
	}
	
	DTURLLoadingConnectionController *engadget = [DTURLLoadingConnectionController connectionController];
	engadget.URL = [NSURL URLWithString:@"http://www.engadget.com/"];
	engadget.priority = DTConnectionControllerPriorityHigh;
	[engadget addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[engadget connect];
	
	DTURLLoadingConnectionController *ebay = [DTURLLoadingConnectionController connectionController];
	ebay.URL = [NSURL URLWithString:@"http://www.ebay.com/"];
	ebay.priority = DTConnectionControllerPriorityLow;
	[ebay addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[ebay connect];
	
	DTURLLoadingConnectionController *google = [DTURLLoadingConnectionController connectionController];
	google.URL = [NSURL URLWithString:@"http://www.google.com/"];
	google.priority = DTConnectionControllerPriorityLow;
	[google addDependency:ebay];
	[google addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[google connect];
	
	DTURLLoadingConnectionController *apple = [DTURLLoadingConnectionController connectionController];
	apple.URL = [NSURL URLWithString:@"http://www.apple.com/"];
	apple.priority = DTConnectionControllerPriorityLow;
	[apple addDependency:google];
	[apple addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[apple connect];
	
	DTURLLoadingConnectionController *bbc = [DTURLLoadingConnectionController connectionController];
	bbc.URL = [NSURL URLWithString:@"http://www.bbc.co.uk/"];
	bbc.priority = DTConnectionControllerPriorityHigh;
	[bbc addDependency:apple];
	[bbc addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	[bbc connect];
	
	self.toolbarItems = self.toolbar.items;
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	DTURLLoadingConnectionController *connectionController = (DTURLLoadingConnectionController *)object;
	[self statusUpdate:connectionController];
}
	
- (void)statusUpdate:(DTURLLoadingConnectionController *)connectionController {
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"HH:mm:ss.SSS"];
	NSString *dateString = [df stringFromDate:[NSDate date]]; 
	[df release];
		
	NSString *newLine = @"";
	if ([self.textView.text length] > 0) {
		newLine = @"\n";
	}
	
	NSString *prefixString = [NSString stringWithFormat:@"%@%@ %@: ", newLine, dateString, [self stringFromURL:connectionController.URL]];
	switch (connectionController.status) {
		case DTConnectionControllerStatusStarted:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Started", prefixString];
			break;
		case DTConnectionControllerStatusQueued:
			return;
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Queued", prefixString];
			break;
		case DTConnectionControllerStatusFailed:
			return;
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Failed", prefixString];
			[connectionController removeObserver:self forKeyPath:@"status"];
			break;
		case DTConnectionControllerStatusNotStarted:
			return;
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Not Started", prefixString];
			break;
		case DTConnectionControllerStatusResponded:
			return;
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Responded", prefixString];
			break;
		case DTConnectionControllerStatusComplete:
			return;
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Complete", prefixString];
			[connectionController removeObserver:self forKeyPath:@"status"];
			break;
		case DTConnectionControllerStatusCancelled:
			return;
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%Cancelled", prefixString];
			[connectionController removeObserver:self forKeyPath:@"status"];
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
	self.connectionsLabel.text = [NSString stringWithFormat:@"Connections: %i", [DTConnectionQueue sharedConnectionQueue].activeConnectionsCount];
}

@end
