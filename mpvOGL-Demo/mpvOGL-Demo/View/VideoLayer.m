//
//  VideoLayer.m
//  mpvOGL-Demo
//
//  Created by midoks on 2020/3/1.
//  Copyright © 2020 midoks. All rights reserved.
//

#include <mpv/client.h>
#include <mpv/render.h>
#include <mpv/render_gl.h>

@import OpenGL.GL;
@import OpenGL.GL3;

#import "VideoLayer.h"

static void wakeup(void *);
static void *get_proc_address(void *ctx, const char *name);

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
    return addr;
}


@interface VideoLayer()
{
    mpv_render_context *_mpv_render_context;
    CGLContextObj _cglContext;
    CGLPixelFormatObj _cglPixelFormat;
    mpv_handle *mpv;
    
}
@end

@implementation VideoLayer

-(id)init{
    self = [super init];
    if (self) {
        NSLog(@"VideoLayer init");
        //        self.isOpaque = YES;
        [self setAsynchronous:NO];
        
        
        _cglPixelFormat = [self copyCGLPixelFormatForDisplayMask:0];
        if (!_cglPixelFormat) {
            NSLog(@"Failed to create CGLPixelFormatObj");
            return nil;
        }
        CGLError err = CGLCreateContext(_cglPixelFormat, nil, &_cglContext);
        if (!_cglContext) {
            NSLog(@"Failed to create CGLContextObj %d", err);
            return nil;
        }
        GLint i = 1;
        CGLSetParameter(_cglContext, kCGLCPSwapInterval, &i);
        
        CGLSetCurrentContext(_cglContext);
        [self initMPV];
        [self initVideoRender];
    }
    return self;
}

- (CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask {
    CGLPixelFormatAttribute att1[] = {
        kCGLPFADoubleBuffer,
        kCGLPFAOpenGLProfile,  (CGLPixelFormatAttribute)kCGLOGLPVersion_3_2_Core,
        kCGLPFAAccelerated,
        kCGLPFAAllowOfflineRenderers,
        0
    };
    
    
    CGLPixelFormatAttribute att2[] = {
        kCGLPFADoubleBuffer,
        kCGLPFAOpenGLProfile,  (CGLPixelFormatAttribute)kCGLOGLPVersion_3_2_Core,
        kCGLPFAAllowOfflineRenderers,
        0
    };
    
    
    CGLPixelFormatAttribute att3[] = {
        kCGLPFADoubleBuffer,
        kCGLPFAOpenGLProfile,  (CGLPixelFormatAttribute)kCGLOGLPVersion_3_2_Core,
        kCGLPFAAllowOfflineRenderers,
        0
    };
    
    
    CGLPixelFormatObj pix = NULL;
    GLint npix = 0;
    
    if (pix==NULL){
        CGLError error = CGLChoosePixelFormat(att1, &pix, &npix);
        if (error != kCGLNoError) {
            NSLog(@"ddd:%d", error);
        }
    }
    
    if (pix==NULL){
        CGLError error = CGLChoosePixelFormat(att2, &pix, &npix);
        if (error != kCGLNoError) {
            NSLog(@"ddd:%d", error);
        }
    }
    
    if (pix==NULL){
        CGLError error = CGLChoosePixelFormat(att3, &pix, &npix);
        if (error != kCGLNoError) {
            NSLog(@"ddd:%d", error);
        }
    }
    
    return pix;
}


- (BOOL)canDrawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts {
    return (_mpv_render_context != nil);
}

- (void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts {
    NSLog(@"drawInCGLContext");
    _draw_frame(self);
}

- (CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf {
    return _cglContext;
}


static inline void _draw_frame(VideoLayer *obj) {
    
    static GLint dims[] = { 0, 0, 0, 0 };
    glGetIntegerv(GL_VIEWPORT, dims);

 
    GLint i = 0;
    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &i);
    
    if (i) {
        NSLog(@"print:%d",i);
    }
    
    mpv_render_param params[] = {
        {MPV_RENDER_PARAM_OPENGL_FBO, &(mpv_opengl_fbo){
            .fbo = i,
            .w = obj.frame.size.width,
            .h = obj.frame.size.height,
        }},
        {MPV_RENDER_PARAM_FLIP_Y, &(int){1}},
        {0}
    };
    
    mpv_render_context_render(obj->_mpv_render_context, params);
    CGLFlushDrawable(obj->_cglContext);
}

-(void) display {
    [super display];
    [CATransaction flush];
}

-(void)initMPV{
    _queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);
    mpv = mpv_create();
    if (!mpv) {
        NSLog(@"%@", @"failed creating context");
        exit(-1);
    }
    
    //libmpv,gpu,opengl
    mpv_set_property_string(mpv, "vo", "libmpv");
    mpv_request_log_messages(mpv, "warn");
    check_error(mpv_initialize(mpv));
}

-(void)initVideoRender{
    mpv_render_param params[] = {
        {MPV_RENDER_PARAM_API_TYPE, MPV_RENDER_API_TYPE_OPENGL},
        {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &(mpv_opengl_init_params){
            .get_proc_address = get_proc_address,
            .get_proc_address_ctx = NULL,
            .extra_exts = NULL,
        }},
        {0}
    };
    
    if (mpv_render_context_create(&_mpv_render_context, mpv, params) < 0) {
        puts("failed to initialize mpv GL context");
        exit(1);
    }

    mpv_render_context_set_update_callback(_mpv_render_context, render_context_callback, (__bridge void *)self);
    
}

-(void)openVideo:(NSString *)path{
    mpv_set_wakeup_callback(self->mpv, wakeup, (__bridge void *) self);
    const char *cmd[] = {"loadfile", path.UTF8String, NULL};
    check_error(mpv_command(self->mpv, cmd));
}


static void wakeup(void *context) {
    VideoLayer *video = (__bridge VideoLayer *) context;
    [video readEvents];
}

-(void)readEvents {
    dispatch_async(_queue, ^{
        while (self->mpv) {
            mpv_event *event = mpv_wait_event(self->mpv, 0);
            if (event->event_id == MPV_EVENT_NONE){
                break;
            }
            [self handleEvent:event];
        }
    });
}


static void render_context_callback(void *ctx) {
    VideoLayer *obj = (__bridge id)ctx;
    dispatch_async(dispatch_get_main_queue(), ^{
        [obj display];
//        [CATransaction flush];
    });
}


-(void)handleEvent:(mpv_event *)event
{
    switch (event->event_id) {
        case MPV_EVENT_SHUTDOWN: {
            mpv_detach_destroy(mpv);
            mpv = NULL;
            NSLog(@"event-MPV_EVENT_SHUTDOWN: shutdown");
            break;
        }
        case MPV_EVENT_FILE_LOADED:{
            break;
        }
        case MPV_EVENT_PROPERTY_CHANGE:{
            NSLog(@"MPV_EVENT_PROPERTY_CHANGE");
            break;
        }
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            printf("[%s] %s: %s", msg->prefix, msg->level, msg->text);
            break;
        }
        case MPV_EVENT_VIDEO_RECONFIG: {
            dispatch_async(dispatch_get_main_queue(), ^{
                //
            });
            break;
        }
        default:{
            NSLog(@"event-default: %s\n", mpv_event_name(event->event_id));
            break;
        }
    }
}
@end
