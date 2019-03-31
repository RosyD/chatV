//
//  AcuLocalVideoPreviewView.h
//  AcuTester4iOS
//
//  Created by aculearn on 13-7-4.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AcuVideoView : UIView

//@property GLfloat preferredRotation;
@property CGSize presentationRect;
//@property GLfloat chromaThreshold;
//@property GLfloat lumaThreshold;

- (void)setupGL:(EAGLContext*)glContext;
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (CGRect)getVideoRealRect;

@end
