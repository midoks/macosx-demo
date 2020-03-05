//
//  VideoLayer.h
//  mpvOGL-Demo
//
//  Created by midoks on 2020/3/1.
//  Copyright © 2020 midoks. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#include <mpv/client.h>
#include <mpv/render.h>
#include <mpv/render_gl.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoLayer : CAOpenGLLayer

@property mpv_render_context *mpvGL;
@property  dispatch_queue_t queue;


-(void)initMPV;
-(void)initVideoRender;
-(void)openVideo:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
