//
//  AppDelegate.m
//  ffmpeg-player-demo
//
//  Created by midoks on 2020/2/23.
//  Copyright © 2020 midoks. All rights reserved.
//


#import "AppDelegate.h"
#import "DemoView.h"
#import "DemoVoiceView.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, strong) DemoView *player;
@property (nonatomic, strong) DemoVoiceView *voice;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // NSLog(@"%@",NSStringFromRect(self.window.frame));
    // NSLog(@"%@",NSStringFromRect(self.window.contentView.frame));
    
    // 视频播放
//    self.player = [[DemoView alloc] initWithFrame:self.window.frame];
//    self.window.contentView = self.player;
    
    // 声音播放
    self.voice = [[DemoVoiceView alloc] initWithFrame:self.window.frame];
    self.window.contentView = self.voice;
    
    self.window.movableByWindowBackground = YES;
    [self.window makeKeyWindow];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}




@end
