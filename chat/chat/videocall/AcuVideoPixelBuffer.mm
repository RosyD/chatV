//
//  AcuVideoPixelBuffer.m
//  AcuConference
//
//  Created by aculearn on 13-8-8.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuVideoPixelBuffer.h"

void AcuVideoPixelBufferReleaseCallback(void *releaseRefCon,
                                        const void *baseAddress);

@implementation AcuVideoPixelBuffer
{
    int                 _videoWidth;
    int                 _videoHeight;
    FourCharCode        _videoColorSpace;
    
    char                *_videoData;
    int                 _videoDataLen;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _videoWidth = -1;
        _videoHeight = -1;
        _videoColorSpace = 0;
        
        _videoData = nil;
        _videoDataLen = 0;
        
        _videoFrame = nil;
    }
    
    return self;
}

-(void)dealloc
{
    if (_videoFrame)
    {
        CVPixelBufferRelease(_videoFrame);
        _videoFrame = nil;
    }
}

- (void)setVideoData:(unsigned char*)pVideoData
          withLenght:(int)nVideoDataLen
     videoColorSpace:(FourCharCode)videoColorSpace
          videoWidth:(int)nVideoWidth
         videoHeight:(int)nVideoHeight
{
    if (pVideoData == 0)
    {
        return;
    }
    
    if (nVideoWidth != _videoWidth ||
        nVideoHeight != _videoHeight ||
        videoColorSpace != _videoColorSpace)
    {
        //NSLog(@"Receive video w = %d, h = %d", nVideoWidth, nVideoHeight);
        if (_videoFrame)
        {
            CVPixelBufferRelease(_videoFrame);
            _videoFrame = nil;
        }
        
        _videoColorSpace = videoColorSpace;
        _videoWidth = nVideoWidth;
        _videoHeight = nVideoHeight;
        
        _videoDataLen = _videoWidth * _videoHeight * 1.5;
        _videoDataLen = nVideoDataLen;
        
        NSMutableDictionary*     attributes;
        attributes = [NSMutableDictionary dictionary];
        [attributes setObject:[NSNumber numberWithInt:_videoColorSpace]
                       forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        [attributes setObject:[NSNumber numberWithInt:_videoWidth]
                       forKey:(NSString*)kCVPixelBufferWidthKey];
        [attributes setObject:[NSNumber numberWithInt:_videoHeight]
                       forKey:(NSString*)kCVPixelBufferHeightKey];
        NSDictionary *IOSurfaceProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithBool:YES], @"IOSurfaceOpenGLESFBOCompatibility",
                                             [NSNumber numberWithBool:YES], @"IOSurfaceOpenGLESTextureCompatibility",
                                             nil];
        
        [attributes setObject:IOSurfaceProperties forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                            _videoWidth,
                            _videoHeight,
                            _videoColorSpace,
                            (__bridge CFDictionaryRef)attributes,
                            &_videoFrame);
        
        // lock pixel buffer
        CVPixelBufferLockBaseAddress(_videoFrame, 0);
        
        size_t bytesPerRowOfYPlanar = CVPixelBufferGetBytesPerRowOfPlane(_videoFrame, 0);
        size_t heightOfYPlanar = CVPixelBufferGetHeightOfPlane(_videoFrame, 0);
        size_t bytesOfYPlanar = bytesPerRowOfYPlanar * heightOfYPlanar;
        
        size_t bytesPerRowOfCbCrPlanar = CVPixelBufferGetBytesPerRowOfPlane(_videoFrame, 1);
        size_t heightOfCbCrPlanar = CVPixelBufferGetHeightOfPlane(_videoFrame, 1);
        size_t bytesOfCbCrPlanar = bytesPerRowOfCbCrPlanar * heightOfCbCrPlanar;
        
        // get plane addresses
        char *baseAddressY  = (char*)CVPixelBufferGetBaseAddressOfPlane(_videoFrame, 0);
        char *baseAddressCbCr = (char*)CVPixelBufferGetBaseAddressOfPlane(_videoFrame, 1);
        
        //TODO: copy your data buffers to the newly allocated memory locations
        memcpy(baseAddressY, pVideoData, bytesOfYPlanar);
        memcpy(baseAddressCbCr, pVideoData + bytesOfYPlanar, bytesOfCbCrPlanar);
        
        
        // unlock pixel buffer address
        CVPixelBufferUnlockBaseAddress(_videoFrame, 0);
        
        
#if 0
        CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (CFDictionaryRef) attributes, &bufferPool);
        
        CVPixelBufferPoolCreatePixelBuffer (NULL,bufferPool,&pixelBuffer);
        
        CVPixelBufferLockBaseAddress(pixelBuffer,0);
        
        UInt8 * baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
        
        memcpy(baseAddress, bgraData, bytesByRow * videoHeight);
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
#endif  
    }
    else
    {
        // lock pixel buffer
        CVPixelBufferLockBaseAddress(_videoFrame, 0);
        
        size_t bytesPerRowOfYPlanar = CVPixelBufferGetBytesPerRowOfPlane(_videoFrame, 0);
        size_t heightOfYPlanar = CVPixelBufferGetHeightOfPlane(_videoFrame, 0);
        size_t bytesOfYPlanar = bytesPerRowOfYPlanar * heightOfYPlanar;
        
        size_t bytesPerRowOfCbCrPlanar = CVPixelBufferGetBytesPerRowOfPlane(_videoFrame, 1);
        size_t heightOfCbCrPlanar = CVPixelBufferGetHeightOfPlane(_videoFrame, 1);
        size_t bytesOfCbCrPlanar = bytesPerRowOfCbCrPlanar * heightOfCbCrPlanar;
        
        // get plane addresses
        char *baseAddressY  = (char*)CVPixelBufferGetBaseAddressOfPlane(_videoFrame, 0);
        char *baseAddressCbCr = (char*)CVPixelBufferGetBaseAddressOfPlane(_videoFrame, 1);
        
        //TODO: copy your data buffers to the newly allocated memory locations
        memcpy(baseAddressY, pVideoData, bytesOfYPlanar);
        memcpy(baseAddressCbCr, pVideoData + bytesOfYPlanar, bytesOfCbCrPlanar);
        
        
        // unlock pixel buffer address
        CVPixelBufferUnlockBaseAddress(_videoFrame, 0);
    }
    
    
}

@end


void AcuVideoPixelBufferReleaseCallback(void *releaseRefCon,
                                        const void *baseAddress)
{
	free((void *)baseAddress);
}