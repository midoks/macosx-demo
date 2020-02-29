//
//  AppDelegate.m
//  mpv-demo
//
//  Created by midoks on 2020/2/23.
//  Copyright © 2020 midoks. All rights reserved.
//
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavfilter/avfilter.h>
#include <libavfilter/buffersrc.h>
#include <libavfilter/buffersink.h>
#include <libavutil/opt.h>
#include <mpv/client.h>
#include <stdio.h>
#include <stdlib.h>



#import "AppDelegate.h"
#import "NSMpv.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    int mask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|
    NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable;
    [self.window setStyleMask:mask];
    
    //    NSString *filename = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp4"];
    //    [self initVideo:filename];
    
    NSMpv *mpv = [[NSMpv alloc] initWithFrame:self.window.contentView.frame];
    self.window.contentView = mpv;
//    NSString *filename = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp4"];
//    [mpv initVideo:filename];
    [self.window makeKeyWindow];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}





@end
