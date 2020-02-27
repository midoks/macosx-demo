//
//  GLView.h
//  mpvGL-demo
//
//  Created by midoks on 2020/2/28.
//  Copyright © 2020 midoks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLView : NSOpenGLView

+ (id)Instance:(NSRect)frame;
-(void) initVideo;
-(void)openVideo:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
