//
//  videocapture_ios.m
//  videocapture
//
//  Created by aculearn on 13-6-21.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuVideoCapture.h"
#import <UIKit/UIKit.h>
#import <AssertMacros.h>
#import "AcuConferencePublic.h"
#import "AcuDeviceHardware.h"

#define ACU_IOS_SAVE_VIDEO_DATA 0

#pragma mark -
@interface AcuVideoCapture ()
{
    char                        *videoData;
    size_t                      videoDataLen;
    
    int                         videoFPS;
    
    AVCaptureSession           *videoCaptureSession;
    AVCaptureDevice            *videoDevice;
    AVCaptureDeviceInput       *videoCaptureDeviceInput;
    AVCaptureVideoDataOutput   *videoCaptureDataOutput;
    
    dispatch_queue_t            videoDataOutputQueue;
    
    CVImageBufferRef            _currentImageBuffer;
    NSLock                      *_videoDataMutex;
    
    BOOL                        _bUseHighQuality;
    
#if ACU_IOS_SAVE_VIDEO_DATA
    NSFileHandle                *_videoDataFileHandler;
#endif
}
- (BOOL)useHighQuality;
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice *)frontFacingCamera;
- (AVCaptureDevice *)backFacingCamera;
- (void)getVideoData:(CVImageBufferRef)videoFrame;
@end

@implementation AcuVideoCapture

@synthesize orientation;
@synthesize isHighQualityVideo;
@synthesize isWIFINetwork;
@synthesize videoSampleDelegate;

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        self.isHighQualityVideo = NO;
        self.isWIFINetwork = YES;
        _bUseHighQuality = YES;
        _videoDataMutex = [NSLock new];
        videoFPS = 15;
        _videoCallMode = 1;
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self
                               selector:@selector(deviceOrientationDidChange)
                                   name:UIDeviceOrientationDidChangeNotification
                                 object:nil];
        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
            orientation = AVCaptureVideoOrientationLandscapeRight;
        else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
            orientation = AVCaptureVideoOrientationLandscapeLeft;
        else if (deviceOrientation == UIDeviceOrientationPortrait)
            orientation = AVCaptureVideoOrientationPortrait;
        else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
        else
            orientation = AVCaptureVideoOrientationPortrait;
		
    }
    
    return self;
}

- (void)dealloc
{
    [videoCaptureSession removeInput:videoCaptureDeviceInput];
    [videoCaptureSession removeOutput:videoCaptureDataOutput];
	//dispatch_release(videoDataOutputQueue);
    
    [_videoDataMutex lock];
    if (videoData)
    {
        delete[] videoData;
        videoData = 0;
    }
    [_videoDataMutex unlock];
    
    _videoDataMutex = nil;
}


#pragma mark ----public function----
- (bool)setupCapture
{
    _bUseHighQuality = [self useHighQuality];
    
    NSError *error = nil;
    
    videoCaptureSession = [AVCaptureSession new];
    if (_bUseHighQuality)
    {
        videoCaptureSession.sessionPreset = AVCaptureSessionPreset640x480;
    }
    else
    {
        //NSLog(@"Use Low preset");
        videoCaptureSession.sessionPreset = AVCaptureSessionPresetLow;
    }
    
    
    //if have front camera, use front, else use back.
    if ([self cameraCount] > 1)
    {
        videoDevice = [self frontFacingCamera];
    }
    else
    {
        videoDevice = [self backFacingCamera];
    }
    
    
    videoCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    if (error != nil)
    {
        return false;
    }
    
    
    if ([videoCaptureSession canAddInput:videoCaptureDeviceInput])
    {
        [videoCaptureSession addInput:videoCaptureDeviceInput];
    }
    else
    {
        return false;
    }
    
    videoCaptureDataOutput = [AVCaptureVideoDataOutput new];

    /*
     Currently, the only supported key is kCVPixelBufferPixelFormatTypeKey. 
     Supported pixel formats are
     kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, 
     kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 
     and kCVPixelFormatType_32BGRA.
    */
	NSDictionary *outputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
                                                               forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    videoCaptureDataOutput.videoSettings = outputSettings;
    // discard if the data output queue is blocked (as we process the still image)
    videoCaptureDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    videoDataOutputQueue = dispatch_queue_create("videoFrameQueue", NULL);
    [videoCaptureDataOutput setSampleBufferDelegate:self
                                              queue:videoDataOutputQueue];
    
    if ( [videoCaptureSession canAddOutput:videoCaptureDataOutput] )
    {
		[videoCaptureSession addOutput:videoCaptureDataOutput];
    }
    else
    {
        return false;
    }
    
	[[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
    if ([[[UIDevice currentDevice] systemVersion] intValue] > 6)
    {
        [[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] setAutomaticallyAdjustsVideoMirroring:NO];
    }
    
    [[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] setVideoMirrored:YES];
    
   // CATransaction
    [videoCaptureSession startRunning];
    
#if ACU_IOS_SAVE_VIDEO_DATA
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"%@",documentsDirectory);
    
    //make a full file name
    NSString *fileName = [NSString stringWithFormat:@"%@/AcuVideoData.yuv", documentsDirectory];
    NSLog(@"File path and name:%@", fileName);
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath: fileName ] == YES)
    {
        NSLog (@"File exists");
        [filemgr removeItemAtPath:fileName error:&error];
        if (error != nil)
        {
            NSLog(@"Remove file error");
        }
        NSLog(@"Create file");
        [filemgr createFileAtPath:fileName contents:nil attributes:nil];
    }
    else
    {
        NSLog (@"File not found");
        [filemgr createFileAtPath:fileName contents:nil attributes:nil];
    }
    
    _videoDataFileHandler = [NSFileHandle fileHandleForWritingAtPath:fileName];
    if (_videoDataFileHandler == nil)
    {
        NSLog(@"Failed to open file");
    }
    
#endif

    return true;
}

- (void)teardownCapture
{
    
}

- (bool)startCapture:(int)fps
{
    bool bRet = [self setFPS:fps];
    
    if (!bRet)
    {
        return false;
    }
    
    if ([[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] isVideoOrientationSupported])
    {
        [[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:orientation];
    }
    
    if ([[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] isVideoMirroringSupported])
    {
        [[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] setVideoMirrored:NO];
    }
    [[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    
    return true;
}

- (void)stopCapture
{
    while ([[UIDevice currentDevice] isGeneratingDeviceOrientationNotifications])
    {
        //NSLog(@"generate orientation notification");
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    }
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
    
    [[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
    if([videoCaptureSession isRunning])
    {
        [videoCaptureSession stopRunning];
    }
#if ACU_IOS_SAVE_VIDEO_DATA
    [_videoDataFileHandler closeFile];
#endif
}

- (bool)setFPS:(int)fps
{
    if (fps <= 0)
    {
        return false;
    }
    
    videoFPS = fps;
    
    [videoCaptureSession beginConfiguration];
    if ([videoDevice respondsToSelector:@selector(setActiveVideoMinFrameDuration:)] &&
        [videoDevice respondsToSelector:@selector(setActiveVideoMaxFrameDuration:)])
    {
        NSError *error;
        [videoDevice lockForConfiguration:&error];
        if (error == nil)
        {
            [videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, fps)];
            [videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, fps)];
        }
        [videoDevice unlockForConfiguration];
    }
    else
    {
        NSArray *connections = videoCaptureDataOutput.connections;
        if ([connections count] > 0)
        {
            [[connections objectAtIndex:0] setVideoMinFrameDuration:CMTimeMake(1, fps)];
            [[connections objectAtIndex:0] setVideoMaxFrameDuration:CMTimeMake(1, fps)];
        }
    }
    
    [videoCaptureSession commitConfiguration];
    
    return true;
}

- (bool)switchCamera
{
    BOOL success = NO;
    
    if ([self cameraCount] > 1)
    {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = [[videoCaptureDeviceInput device] position];
        
        if (position == AVCaptureDevicePositionBack)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontFacingCamera] error:&error];
        else if (position == AVCaptureDevicePositionFront)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:&error];
        else
            return false;
        
        if (newVideoInput != nil)
        {
            [videoCaptureSession beginConfiguration];
            [videoCaptureSession removeInput:videoCaptureDeviceInput];
            if ([videoCaptureSession canAddInput:newVideoInput])
            {
                [videoCaptureSession addInput:newVideoInput];
                videoCaptureDeviceInput = newVideoInput;
            }
            else
            {
                [videoCaptureSession addInput:videoCaptureDeviceInput];
            }
            [videoCaptureSession commitConfiguration];
            success = YES;
        }
    }
    

    if (success)
    {
        if ([[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] isVideoOrientationSupported])
        {
            [[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:orientation];
        }
        
        if ([[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] isVideoMirroringSupported])
        {
            [[videoCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo] setVideoMirrored:NO];
        }
        
        [self setFPS:videoFPS];
    }
    
    return success;
}

- (NSUInteger)cameraCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (void)captureWidth:(int*)nWidth Height:(int*)nHeight
{
    if (_bUseHighQuality)
    {
        if (orientation == AVCaptureVideoOrientationLandscapeRight ||
            orientation == AVCaptureVideoOrientationLandscapeLeft)
        {
            *nWidth = 640;
            *nHeight = 480;
        }
        else
        {
            *nWidth = 480;
            *nHeight = 640;
        }
        
    }
    else
    {
        //NSLog(@"return low preset width and height");
        if (orientation == AVCaptureVideoOrientationLandscapeRight ||
            orientation == AVCaptureVideoOrientationLandscapeLeft)
        {
            *nWidth = 192;
            *nHeight = 144;
        }
        else
        {
            *nWidth = 144;
            *nHeight = 192;
        }
    }
	
}

- (void)captureColorSpace:(FourCharCode*)colorSpace
{
    *colorSpace = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
}

- (BOOL)gotVideoData:(char*&)pVideoData withLength:(int&)nVideoLength
{
    CVImageBufferRef imageBuffer;
    @synchronized(self)
    {
        imageBuffer = CVBufferRetain(_currentImageBuffer);
    }
    
    if (imageBuffer)
    {
        [self getVideoData:imageBuffer];
        pVideoData = videoData;
        nVideoLength = (int)videoDataLen;
    }
    CVBufferRelease(imageBuffer);
    
    return YES;
}


#pragma mark ----internal function----
// Keep track of current device orientation so it can be applied to movie recordings and still image captures
- (void)deviceOrientationDidChange
{
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
    if (_videoCallMode == 0)
    {
        if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
            orientation = AVCaptureVideoOrientationLandscapeRight;
        else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
            orientation = AVCaptureVideoOrientationLandscapeLeft;
        else
            return;
    }
    else
    {
        if (deviceOrientation == UIDeviceOrientationFaceUp ||
            deviceOrientation == UIDeviceOrientationFaceDown ||
            deviceOrientation == UIDeviceOrientationUnknown)
        {
            return;
        }
        
        if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
            orientation = AVCaptureVideoOrientationLandscapeRight;
        else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
            orientation = AVCaptureVideoOrientationLandscapeLeft;
        else if (deviceOrientation == UIDeviceOrientationPortrait)
            orientation = AVCaptureVideoOrientationPortrait;
        else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
        else
            orientation = AVCaptureVideoOrientationPortrait;
    }
	
    NSArray *connections = videoCaptureDataOutput.connections;
    if ([connections count] > 0)
    {
        if ([[connections objectAtIndex:0] isVideoOrientationSupported])
        {
            [[connections objectAtIndex:0] setVideoOrientation:orientation];
        }
        
        if ([[connections objectAtIndex:0] isVideoMirroringSupported])
        {
            [[connections objectAtIndex:0] setVideoMirrored:NO];
        }
    }
    
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)backFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (void)getVideoData:(CVImageBufferRef)videoFrame
{
    [_videoDataMutex lock];
	
	if (self.videoSampleDelegate)
	{
		[videoSampleDelegate videoCapture:self
						OutputImageBuffer:_currentImageBuffer];
	}
	
    size_t bytesPerRowOfYPlanar = CVPixelBufferGetBytesPerRowOfPlane(videoFrame, 0);
    size_t heightOfYPlanar = CVPixelBufferGetHeightOfPlane(videoFrame, 0);
    size_t bytesOfYPlanar = bytesPerRowOfYPlanar * heightOfYPlanar;
    
    size_t bytesPerRowOfCbCrPlanar = CVPixelBufferGetBytesPerRowOfPlane(videoFrame, 1);
    size_t heightOfCbCrPlanar = CVPixelBufferGetHeightOfPlane(videoFrame, 1);
    size_t bytesOfCbCrPlanar = bytesPerRowOfCbCrPlanar * heightOfCbCrPlanar;
    
    if (!videoData)
    {
        videoDataLen = bytesOfYPlanar + bytesOfCbCrPlanar;
        videoData = new char[videoDataLen];
    }
    
    CVPixelBufferLockBaseAddress(videoFrame, 0);
    void *pTempData = CVPixelBufferGetBaseAddressOfPlane(videoFrame, 0);
    if (pTempData)
    {
        memcpy(videoData, pTempData, bytesOfYPlanar);
    }
    else
    {
        memset(videoData, 0, bytesOfYPlanar);
    }
    
    pTempData = CVPixelBufferGetBaseAddressOfPlane(videoFrame, 1);
    if (pTempData)
    {
        memcpy(videoData + bytesOfYPlanar, pTempData, bytesOfCbCrPlanar);
    }
    else
    {
        memset(videoData + bytesOfYPlanar, 0, bytesOfCbCrPlanar);
    }
    
    CVPixelBufferUnlockBaseAddress(videoFrame, 0);
    [_videoDataMutex unlock];
}

- (BOOL)useHighQuality
{
    NSString *sDeviceModel = [AcuDeviceHardware platformString];
    NSString *aux = [[sDeviceModel componentsSeparatedByString:@","] objectAtIndex:0];
    
    if (self.isHighQualityVideo)
    {
        return YES;
    }
    
    //is low preset iPod touch device
    if ([aux rangeOfString:@"iPod"].location != NSNotFound)
    {
        return NO;
    }
    
    //is low preset iPhone device
    if ([aux rangeOfString:@"iPhone"].location != NSNotFound)
    {
        //check iPhone version
        int version = [[aux stringByReplacingOccurrencesOfString:@"iPhone" withString:@""] intValue];
        //iPhone4 version : 3
        //iPhone4S version : 4
        if (version <= 4)
        {
            //NSLog(@"iPhone4 or iPhone4S");
            return NO;
        }
    }
    
    //is low preset iPad device
    if ([aux rangeOfString:@"iPad"].location != NSNotFound)
    {
        //check iPad version
        int version = [[aux stringByReplacingOccurrencesOfString:@"iPad" withString:@""] intValue];
        if (version < 3)
        {
            //iPad2 and iPad mini
            return NO;
        }
        else if (version == 3)
        {
            //new iPad and iPad4
            int minVersion = [[sDeviceModel stringByReplacingOccurrencesOfString:@"iPad3," withString:@""] intValue];
            if (minVersion < 4)
            {
                //new iPad
                return NO;
            }
            
            //minVersion >= 4 iPad4
        }
        else
        {
            //version > 3 iPad air or iPad mini2
        }
    }
    
    if (self.isWIFINetwork)
    {
        return YES;
    }
    
    return NO;
}

#pragma mark ----video data callback----

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    if (!videoSampleDelegate)
//    {
//        return;
//    }
    
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        return;
    }
    
    CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!videoFrame)
    {
        return;
    }
    
    //sanity check
    /*
    size_t nVideoDataLen = CVPixelBufferGetDataSize(videoFrame);
    size_t nImageW = CVPixelBufferGetWidth(videoFrame);
    size_t nImageH = CVPixelBufferGetHeight(videoFrame);
    OSType cs = CVPixelBufferGetPixelFormatType(videoFrame);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(videoFrame);
    if (CVPixelBufferIsPlanar(videoFrame))
    {
        
        NSLog(@"isPlanar!");
    }
    
    size_t planarCount = CVPixelBufferGetPlaneCount(videoFrame);
    
    size_t plane_width = CVPixelBufferGetWidthOfPlane(videoFrame, 0);
    size_t plane_height = CVPixelBufferGetHeightOfPlane(videoFrame, 0);
    
    size_t y_bytePer_row = CVPixelBufferGetBytesPerRowOfPlane(videoFrame, 0);
    size_t cbcr_plane_height = CVPixelBufferGetHeightOfPlane(videoFrame, 1);
    size_t cbcr_plane_width = CVPixelBufferGetWidthOfPlane(videoFrame, 1);
    size_t cbcr_bytePer_row = CVPixelBufferGetBytesPerRowOfPlane(videoFrame, 1);
    */
    
    CVImageBufferRef imageBufferToRelease;
    @synchronized (self)
    {
        imageBufferToRelease = _currentImageBuffer;
        _currentImageBuffer = CVBufferRetain(videoFrame);
    }
    CVBufferRelease(imageBufferToRelease);
    
}


- (void)setVideoCallMode:(int)videoCallMode
{
    BOOL bChangeToConf = NO;
    if (_videoCallMode == 1 && videoCallMode == 0)
    {
        bChangeToConf = YES;
    }
    
    _videoCallMode = videoCallMode;
    if (bChangeToConf)
    {
        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        
        if (deviceOrientation != UIDeviceOrientationLandscapeLeft &&
            deviceOrientation != UIDeviceOrientationLandscapeRight)
        {
            orientation = AVCaptureVideoOrientationLandscapeRight;
        }
        
        
        NSArray *connections = videoCaptureDataOutput.connections;
        if ([connections count] > 0)
        {
            if ([[connections objectAtIndex:0] isVideoOrientationSupported])
            {
                [[connections objectAtIndex:0] setVideoOrientation:orientation];
            }
            
            if ([[connections objectAtIndex:0] isVideoMirroringSupported])
            {
                [[connections objectAtIndex:0] setVideoMirrored:NO];
            }
        }
    }
    else
    {
        [self deviceOrientationDidChange];
    }
}

@end
