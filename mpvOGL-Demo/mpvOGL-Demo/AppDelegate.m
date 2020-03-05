//
//  AppDelegate.m
//  mpvOGL-Demo
//
//  Created by midoks on 2020/3/1.
//  Copyright © 2020 midoks. All rights reserved.
//

#import "AppDelegate.h"
#import "VideoView.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    int mask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|
    NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable;
    [self.window setStyleMask:mask];
    
    
    NSView *video = [[VideoView alloc] initWithFrame:self.window.contentView.frame];
    [self.window.contentView addSubview:video];


    [self.window makeKeyWindow];
    [self.window center];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
