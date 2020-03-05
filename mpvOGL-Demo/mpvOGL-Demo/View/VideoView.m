//
//  VideoView.m
//  mpvOGL-Demo
//
//  Created by midoks on 2020/3/1.
//  Copyright © 2020 midoks. All rights reserved.
//

#import "VideoLayer.h"

#import "VideoView.h"
#import <QuartzCore/QuartzCore.h>


@interface  VideoView()

@property CGRect tmpFrame;


@property VideoLayer *vlayer;
@end

@implementation VideoView

static VideoView *_instance = nil;
static dispatch_once_t _instance_once;

+ (id)Instance:(NSRect)frame {
    dispatch_once(&_instance_once, ^{
        _instance = [[VideoView alloc] initWithFrame:frame];
    });
    return _instance;
}

-(id)initWithFrame:(NSRect)frame{
    _tmpFrame = frame;
    self = [super initWithFrame:frame];
    if (self){
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeFileURL, nil]];
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor redColor].CGColor;
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        
        _vlayer = [[VideoLayer alloc] init];
        self.layer = _vlayer;
    }
    return  self;
}


// 当文件被拖动到界面触发
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}

//当文件在界面中放手
-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *zPasteboard = [sender draggingPasteboard];
    NSArray *files = [zPasteboard propertyListForType:NSFilenamesPboardType];
    [_vlayer openVideo:[files objectAtIndex:0]];
    return YES;
}

@end
