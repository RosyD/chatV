//
//  videocapture.h
//  videocapture
//
//  Created by aculearn on 13-6-21.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//


/*
 Preset                                         3G       3GS        4 back      4 front
 AVCaptureSessionPresetPhoto                This is not supported for video output.
 AVCaptureSessionPresetHigh                 300x304    640x480     1280x720    640x480
 AVCaptureSessionPresetMedium               400x304    480x360     480x360     480x360
 AVCaptureSessionPresetLow                  400x306    192x144     192x144     192x144
 AVCaptureSessionPreset352x288
 AVCaptureSessionPreset640x480
 AVCaptureSessionPreset1280x720
 AVCaptureSessionPreset1920x1080
 AVCaptureSessionPresetiFrame960x540
 AVCaptureSessionPresetiFrame1280x720
 */


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AcuVideoCaptureOutputDataSampleDelegate;

@interface AcuVideoCapture : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    
    
    
}

@property(nonatomic, assign) AVCaptureVideoOrientation  orientation;
@property(nonatomic, assign) BOOL isHighQualityVideo;
@property(nonatomic, assign) BOOL isWIFINetwork;
@property(nonatomic, weak) id<AcuVideoCaptureOutputDataSampleDelegate> videoSampleDelegate;

/*
 //1是1对1的视频会议， 0是多人视频会议
 */
@property (nonatomic, assign) int               videoCallMode;


- (bool)setupCapture;
//- (void)teardownCapture;
- (bool)startCapture:(int)fps;
- (void)stopCapture;
- (bool)switchCamera;
- (bool)setFPS:(int)fps;
- (NSUInteger)cameraCount;
//use preset low:192x144
- (void)captureWidth:(int*)nWidth Height:(int*)nHeight;
- (void)captureColorSpace:(FourCharCode*)colorSpace;
- (BOOL)gotVideoData:(char*&)pVideoData withLength:(int&)nVideoLength;

- (void)setVideoCallMode:(int)videoCallMode;

@end


@protocol AcuVideoCaptureOutputDataSampleDelegate <NSObject>

//- (void)videoCapture:(AcuVideoCapture*)videoCapture OutputSampleData:(char*)data dataLength:(int)length;
- (void)videoCapture:(AcuVideoCapture*)videoCapture OutputImageBuffer:(CVImageBufferRef)videoFrame;

@end