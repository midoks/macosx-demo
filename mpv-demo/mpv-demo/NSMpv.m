//
//  NSMpv.m
//  mpv-demo
//
//  Created by midoks on 2020/3/1.
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

#import "NSMpv.h"

static void wakeup(void *);

static inline void check_error(int status)
{
    if (status < 0) {
        printf("%d:mpv API error: %s\n",status, mpv_error_string(status));
        exit(1);
    }
}

@interface NSMpv()
{
    mpv_handle *mpv;
    dispatch_queue_t queue;
    NSView *wrapper;
}
@property CGRect tmpFrame;
@end


@implementation NSMpv

- (id)initWithFrame:(NSRect)frame{
    self.tmpFrame = frame;
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor redColor].CGColor;
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeFileURL, nil]];
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

-(void) initVideo:(NSString *)path{
    NSLog(@"initVideo:%@", NSStringFromRect(self.tmpFrame));
    wrapper = [[NSView alloc] initWithFrame:self.tmpFrame];
    [wrapper setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [self addSubview:wrapper];
    
    // Deal with MPV in the background.
    queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);
    
    self->mpv = mpv_create();
    if (!self->mpv) {
        NSLog(@"%@", @"failed creating context");
        exit(-1);
    }
    
    int64_t wid = (intptr_t) self->wrapper;
    check_error(mpv_set_option(self->mpv, "wid", MPV_FORMAT_INT64, &wid));
    
    // Maybe set some options here, like default key bindings.
    // NOTE: Interaction with the window seems to be broken for now.
    //        check_error(mpv_set_option_string(self->mpv, "input-default-bindings", "yes"));
    
    //        // for testing!
    //        check_error(mpv_set_option_string(self->mpv, "input-media-keys", "yes"));
    //        check_error(mpv_set_option_string(self->mpv, "input-cursor", "no"));
    //        check_error(mpv_set_option_string(self->mpv, "input-vo-keyboard", "yes"));
    
    // request important errors
    //        check_error(mpv_request_log_messages(self->mpv, "warn"));
    
    check_error(mpv_initialize(self->mpv));
    dispatch_async(queue, ^{
        // Register to be woken up whenever mpv generates new events.
        mpv_set_wakeup_callback(self->mpv, wakeup, (__bridge void *) self);
    });
    
    // Load the indicated file
    const char *cmd[] = {"loadfile", path.UTF8String, NULL};
    check_error(mpv_command(self->mpv, cmd));
}

- (void) handleEvent:(mpv_event *)event
{
    switch (event->event_id) {
        case MPV_EVENT_SHUTDOWN: {
            mpv_detach_destroy(mpv);
            mpv = NULL;
            printf("event: shutdown\n");
            break;
        }
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            printf("[%s] %s: %s", msg->prefix, msg->level, msg->text);
            break;
        }
        case MPV_EVENT_VIDEO_RECONFIG: {
            dispatch_async(dispatch_get_main_queue(), ^{
//                NSArray *subviews = [self->wrapper subviews];
//                if ([subviews count] > 0) {
//                }
            });
            break;
        }
        default:{
            printf("event: %s\n", mpv_event_name(event->event_id));
            break;
        }
    }
}

- (void) readEvents
{
    dispatch_async(queue, ^{
        while (self->mpv) {
            mpv_event *event = mpv_wait_event(self->mpv, 0);
            if (event->event_id == MPV_EVENT_NONE)
                break;
            [self handleEvent:event];
        }
    });
}

static void wakeup(void *context) {
    NSMpv *a = (__bridge NSMpv *) context;
    [a readEvents];
}

- (void) mpv_stop
{
    if (mpv) {
        const char *args[] = {"stop", NULL};
        mpv_command(mpv, args);
    }
}

- (void) mpv_quit
{
    if (mpv) {
        const char *args[] = {"quit", NULL};
        mpv_command(mpv, args);
    }
}

#pragma mark - 外部文件拖拽功能
// 当文件被拖动到界面触发
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}

//当文件在界面中放手
-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *zPasteboard = [sender draggingPasteboard];
    NSArray *files = [zPasteboard propertyListForType:NSFilenamesPboardType];
    [self initVideo:[files objectAtIndex:0]];
    return YES;
}

@end
