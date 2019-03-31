//
//  AcuVideoPixelBuffer.h
//  AcuConference
//
//  Created by aculearn on 13-8-8.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@interface AcuVideoPixelBuffer : NSObject
{
@public
    CVPixelBufferRef _videoFrame;
}
- (void)setVideoData:(unsigned char*)pVideoData
          withLenght:(int)nVideoDataLen
     videoColorSpace:(FourCharCode)videoColorSpace
          videoWidth:(int)nVideoWidth
         videoHeight:(int)nVideoHeight;

@end
