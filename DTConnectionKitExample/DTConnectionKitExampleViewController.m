//
//  DTConnectionKitExampleViewController.m
//  DTConnectionKit
//
//  Created by Daniel Tull on 14.12.2009.
//  Copyright 2009 Daniel Tull. All rights reserved.
//

#import "DTConnectionKitExampleViewController.h"
#import "DTURLLoadingConnection.h"
#import "DTConnectionQueue.h"

@interface DTConnectionKitExampleViewController ()
- (NSString *)stringFromURL:(NSURL *)url;
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
	
	NSArray *urls = [NSArray arrayWithObjects:
					 @"http://www.bbc.co.uk/", 
					 @"http://www.google.co.uk/", 
					 @"http://www.tesco.com/", 
					 @"http://www.apple.com/", 
					 @"http://www.ebay.com/", 
					 @"http://www.nike.com/", 
					 @"http://www.engadget.com/",
					 @"http://www.coca-cola.com/",
					 @"http://www.no.danieltull.co.uk/", 
					 @"http://www.oakley.com/",
					 @"http://www.sky.com/",
					 @"http://www.yahoo.com/",
					 @"http://www.microsoft.com/",
					 @"http://www.play.com/",
					 nil];
	
	for (NSString *s in urls) {		
		DTURLLoadingConnection *connection = [[DTURLLoadingConnection alloc] init];
		connection.delegate = self;
		connection.URL = [NSURL URLWithString:s];
		[connection addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
		[connection connect];
		[connection release];
	}
	
	self.toolbarItems = self.toolbar.items;
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	DTURLLoadingConnection *connectionController = (DTURLLoadingConnection *)object;
	
	[self performSelectorOnMainThread:@selector(statusUpdate:) withObject:connectionController waitUntilDone:NO];
}
	
- (void)statusUpdate:(DTURLLoadingConnection *)connectionController {
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
		case DTConnectionStatusStarted:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Started", prefixString];
			break;
		case DTConnectionStatusQueued:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Queued", prefixString];
			break;
		case DTConnectionStatusFailed:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Failed", prefixString];
			break;
		case DTConnectionStatusNotStarted:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Not Started", prefixString];
			break;
		case DTConnectionStatusResponded:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Responded", prefixString];
			break;
		case DTConnectionStatusComplete:
			self.textView.text = [self.textView.text stringByAppendingFormat:@"%@Complete", prefixString];
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
	self.connectionsLabel.text = [NSString stringWithFormat:@"Connections: %i", [DTConnectionQueue sharedConnectionQueue].connectionCount];
}

#pragma mark -
#pragma mark DTConnectionControllerDelegate methods

- (void)dtconnection:(DTConnection *)connectionController didSucceedWithObject:(id)object {
	[connectionController removeObserver:self forKeyPath:@"status"];
}

- (void)dtconnection:(DTConnection *)connectionController didFailWithError:(NSError *)error {
	[connectionController removeObserver:self forKeyPath:@"status"];
}

@end
