/*
 DCTConnectionController+DownloadPath.m
 DCTConnectionController
 
 Created by Daniel Tull on 26.11.2011.
 
 
 
 Copyright (c) 2011 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DCTConnectionController+DownloadPath.h"
#import <objc/runtime.h>

@interface DCTConnectionController ()
- (void)dctDownloadPathInternal_setupBlockCallback;
@property (nonatomic, readonly) NSString *dctInternal_downloadPath;
@end

@implementation DCTConnectionController (DownloadPath)

- (void)setDownloadPath:(NSString *)downloadPath {
	[self dctDownloadPathInternal_setupBlockCallback];
	objc_setAssociatedObject(self, @selector(downloadPath), downloadPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)downloadPath {
	return objc_getAssociatedObject(self, _cmd);
}

- (void)dctDownloadPathInternal_setupBlockCallback {
	
	if (objc_getAssociatedObject(self, _cmd))
		return;
		
	objc_setAssociatedObject(self, _cmd, NSStringFromSelector(_cmd), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
	__dct_weak DCTConnectionController *weakself = self;
		
	[self addFinishHandler:^{
		
		if ([weakself.downloadPath length] == 0) return;
		
		if ([weakself.downloadPath isEqualToString:weakself.dctInternal_downloadPath]) return;

		
		NSString *downloadPath = weakself.downloadPath;
		NSFileManager *fileManager = [NSFileManager defaultManager];
			
		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:[downloadPath stringByDeletingLastPathComponent]
									   withIntermediateDirectories:YES
														attributes:nil 
															 error:&error])
				NSLog(@"Failed to created directory for destinationPath %@ (%@)", downloadPath, error);
			
		[fileManager copyItemAtPath:weakself.dctInternal_downloadPath toPath:downloadPath error:nil];
	}];
}

@end
