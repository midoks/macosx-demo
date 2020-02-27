//
//  AppDelegate.m
//  mpvGL-demo
//
//  Created by midoks on 2020/2/28.
//  Copyright © 2020 midoks. All rights reserved.
//

#import "AppDelegate.h"
#import "GLView.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    NSString *filename = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp4"];
    GLView *gl = [GLView Instance:self.window.frame];
    [gl initVideo];
    [gl openVideo:filename];
    self.window.contentView = gl;
    
    [self.window makeKeyWindow];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
