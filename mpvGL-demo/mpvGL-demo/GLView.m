//
//  GLView.m
//  mpvGL-demo
//
//  Created by midoks on 2020/2/28.
//  Copyright © 2020 midoks. All rights reserved.
//
#include <mpv/client.h>
#include <mpv/render_gl.h>
#include <stdio.h>
#include <stdlib.h>

#import <OpenGL/gl.h>
#import <Cocoa/Cocoa.h>

#import "GLView.h"

static void wakeup(void *);

static inline void check_error(int status)
{
    if (status < 0) {
        printf("%d:mpv API error: %s\n",status, mpv_error_string(status));
        exit(1);
    }
}

static void *get_proc_address(void *ctx, const char *name)
{
    CFStringRef symbolName = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingASCII);
    void *addr = CFBundleGetFunctionPointerForName(CFBundleGetBundleWithIdentifier(CFSTR("com.apple.opengl")), symbolName);
    CFRelease(symbolName);
    return addr;
}

static void glupdate(void *ctx);

@interface GLView(){
    mpv_handle *mpv;
    dispatch_queue_t queue;
    NSView *wrapper;
    mpv_render_context *mpvGL;
}

@end

@implementation GLView


static GLView *_instance = nil;
static dispatch_once_t _instance_once;

+ (id)Instance:(NSRect)frame {
    dispatch_once(&_instance_once, ^{
        _instance = [[GLView alloc] initWithFrame:frame];
    });
    return _instance;
}

- (id)initWithFrame:(NSRect)frame{
    self = [self initMpvGL:frame];
    if (self) {
        
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        
    }
    return self;
}

-(id) initMpvGL:(NSRect)frame{
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFADoubleBuffer,
        0
    };
    self = [super initWithFrame:frame
                    pixelFormat:[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes]];
    
    if (self) {
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        // swap on vsyncs
        GLint swapInt = 1;
        [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
        [[self openGLContext] makeCurrentContext];
        self->mpvGL = nil;
    }
    return self;
}

-(void)fillBlack
{
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
}

-(void) drawRectGL{
    if (self->mpvGL) {
        mpv_render_param params[] = {
            {MPV_RENDER_PARAM_OPENGL_FBO, &(mpv_opengl_fbo){
                .fbo = 0,
                .w = self.bounds.size.width,
                .h = self.bounds.size.height,
            }},
            {MPV_RENDER_PARAM_FLIP_Y, &(int){1}},
            {0}
        };
        
        mpv_render_context_render(self->mpvGL, params);
    } else{
        [self fillBlack];
    }
    
    [[self openGLContext] flushBuffer];
}


-(void) initVideo {
    queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);
    mpv = mpv_create();
    if (!mpv) {
        NSLog(@"%@", @"failed creating context");
        exit(-1);
    }
    check_error(mpv_initialize(mpv));
    
    mpv_render_param params[] = {
        {MPV_RENDER_PARAM_API_TYPE, MPV_RENDER_API_TYPE_OPENGL},
        {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &(mpv_opengl_init_params){
            .get_proc_address = get_proc_address,
        }},
        {0}
    };
    
    mpv_render_context *mpvGL;
    if (mpv_render_context_create(&mpvGL, mpv, params) < 0) {
        puts("failed to initialize mpv GL context");
        exit(1);
    }
    
    self->mpvGL = mpvGL;
    
    mpv_render_context_set_update_callback(mpvGL, glupdate, (__bridge void *)self);
    
    //libmpv,gpu,opengl
    mpv_set_property_string(mpv, "vo", "libmpv");
    mpv_set_property_string(mpv, "keepaspect", "no");
    mpv_set_property_string(mpv, "gpu-hwdec-interop", "auto");
    mpv_request_log_messages(mpv, "warn");
}

-(void)openVideo:(NSString *)path{
    dispatch_async(queue, ^{
        mpv_set_wakeup_callback(self->mpv, wakeup, (__bridge void *) self);
    });
    
    const char *cmd[] = {"loadfile", path.UTF8String, NULL};
    check_error(mpv_command(self->mpv, cmd));
}


static void wakeup(void *context) {
    GLView *video = (__bridge GLView *) context;
    [video readEvents];
}

-(void)readEvents {
    dispatch_async(queue, ^{
        while (self->mpv) {
            mpv_event *event = mpv_wait_event(self->mpv, 0);
            if (event->event_id == MPV_EVENT_NONE){
                break;
            }
            [self handleEvent:event];
        }
    });
}

static void glupdate(void *ctx)
{
    GLView *video = (__bridge GLView *)ctx;
    // I'm still not sure what the best way to handle this is, but this works.
    dispatch_async(dispatch_get_main_queue(), ^{
        [video drawRectGL];
    });
}

-(void)handleEvent:(mpv_event *)event
{
    switch (event->event_id) {
        case MPV_EVENT_SHUTDOWN: {
            mpv_render_context_free(mpvGL);
            mpv_detach_destroy(mpv);
            mpv = NULL;
            NSLog(@"event: shutdown");
            break;
        }
        case MPV_EVENT_FILE_LOADED:{
            double width = [self mpvGetDouble:@"width"];
            double height = [self mpvGetDouble:@"height"];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSApp mainWindow] setFrame:NSMakeRect(0, 0, width, height) display:YES];
            });
            
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
                // mpv's events view
                // NSView *eview = [self->wrapper subviews][0];
                // [self->_window makeFirstResponder:eview];
                //                }
            });
        }
        default:{
            NSLog(@"event: %s\n", mpv_event_name(event->event_id));
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [self drawRectGL];
}

#pragma mark - MPV Private Methods
-(int)mpvGetInt:(NSString *)name {
    int64_t data;
    mpv_get_property(mpv, name.UTF8String, MPV_FORMAT_INT64, &data);
    return (int)data;
}

-(double)mpvGetDouble:(NSString *)name {
    int64_t data;
    mpv_get_property(mpv, name.UTF8String, MPV_FORMAT_INT64, &data);
    return (double)data;
}

@end
