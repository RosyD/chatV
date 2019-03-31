//
//  AcuAudioManager.m
//
//
//  Created by Aculearn on 13-11-14.
//
//

//copy from pjsip

/**
 * As in iOS SDK 4 or later, audio route change property listener is
 * no longer necessary. Just make surethat your application can receive
 * remote control events by adding the code:
 *     [[UIApplication sharedApplication]
 *      beginReceivingRemoteControlEvents];
 * Otherwise audio route change (such as headset plug/unplug) will not be
 * processed while your application is in the background mode.
 */

/* Starting iOS SDK 7, Audio Session API is deprecated. */
//end pjsip

#define USE_AUDIO_SESSION_API 0


/*
 kAudioUnitErr_InvalidProperty			-10879
 
 kAudioUnitErr_InvalidParameter			-10878
 
 kAudioUnitErr_InvalidElement			-10877
 
 kAudioUnitErr_NoConnection				-10876
 
 kAudioUnitErr_FailedInitialization     -10875
 
 kAudioUnitErr_TooManyFramesToProcess	-10874
 
 kAudioUnitErr_IllegalInstrument        -10873
 
 kAudioUnitErr_InstrumentTypeNotFound	-10872
 
 kAudioUnitErr_InvalidFile              -10871
 
 kAudioUnitErr_UnknownFileType          -10870
 
 kAudioUnitErr_FileNotSpecified         -10869
 
 kAudioUnitErr_FormatNotSupported       -10868
 
 kAudioUnitErr_Uninitialized            -10867
 
 kAudioUnitErr_InvalidScope             -10866
 
 kAudioUnitErr_PropertyNotWritable      -10865
 
 kAudioUnitErr_CannotDoInCurrentContext	-10863
 
 kAudioUnitErr_InvalidPropertyValue     -10851
 
 kAudioUnitErr_PropertyNotInUse         -10850
 
 kAudioUnitErr_Initialized              -10849
 
 kAudioUnitErr_InvalidOfflineRender     -10848
 
 kAudioUnitErr_Unauthorized             -10847
 
 */

#import <UIKit/UIKit.h>
#import "AcuAudioManager.h"
#import "AcuDeviceHardware.h"
#include "fifo.h"

#define Acu_Audio_Manager_Preferred_Duration		200.0

@interface AcuAudioManager()
{
@public
    AudioUnit						_audioUnit;
    AudioBufferList					*_audioBufferList;
    AudioStreamBasicDescription     _streamFormat;
    AudioStreamBasicDescription     _streamFormat8K;
    CFIFO							_captureDataFIFO;
	char							_oneCaptureAudioFrameData[1280];		//20*sizeof(short)*16000/1000
	int								_oneCaptureAudioFrameDataLen;
	BOOL							_bMute;
	BOOL							_running;
    BOOL                            _bNeed8K;
    
    BOOL                            _bHandFree;
}

@end

static OSStatus input_callback(void                       *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp       *inTimeStamp,
                               UInt32                      inBusNumber,
                               UInt32                      inNumberFrames,
                               AudioBufferList            *ioData)
{
    AcuAudioManager* pAudioManager = (__bridge AcuAudioManager*)inRefCon;
    
    OSStatus ostatus = noErr;
	
	if (pAudioManager->_bMute)
	{
		pAudioManager->_captureDataFIFO.removeall();
		return ostatus;
	}
    
    AudioBufferList *buf = pAudioManager->_audioBufferList;
    
    buf->mBuffers[0].mData = NULL;
    buf->mBuffers[0].mDataByteSize = inNumberFrames * pAudioManager->_streamFormat.mChannelsPerFrame;
    /* Render the unit to get input data */
    ostatus = AudioUnitRender(pAudioManager->_audioUnit,
                              ioActionFlags,
                              inTimeStamp,
                              inBusNumber,
                              inNumberFrames,
                              buf);
    
    if (ostatus != noErr)
    {
        return -1;
    }
    
    char *audioDataBuffer = (char*)buf->mBuffers[0].mData;
    pAudioManager->_captureDataFIFO.Put(audioDataBuffer, inNumberFrames * pAudioManager->_streamFormat.mBytesPerFrame);
	
	while (pAudioManager->_captureDataFIFO.GetLength() >= pAudioManager->_oneCaptureAudioFrameDataLen)
	{
		memset(pAudioManager->_oneCaptureAudioFrameData, 0, pAudioManager->_oneCaptureAudioFrameDataLen);
		pAudioManager->_captureDataFIFO.Get(pAudioManager->_oneCaptureAudioFrameData, pAudioManager->_oneCaptureAudioFrameDataLen);
		@autoreleasepool
		{
			if (pAudioManager.audioDelegate)
			{
				[pAudioManager.audioDelegate audioManager:pAudioManager
                                            captureSample:pAudioManager->_oneCaptureAudioFrameData
                                               withLength:pAudioManager->_oneCaptureAudioFrameDataLen];
			}
		}
	}
    return noErr;
}

static OSStatus output_renderer(void                       *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp       *inTimeStamp,
                                UInt32                      inBusNumber,
                                UInt32                      inNumberFrames,
                                AudioBufferList            *ioData)
{
    AcuAudioManager *pAudioManager = (__bridge AcuAudioManager*)inRefCon;
    AudioBuffer *audioBuffer = &ioData->mBuffers[0];
    
    if (pAudioManager.audioDelegate == NULL)
	{
        // No frames available yet.
        audioBuffer->mDataByteSize = 0;
        return -1;
    }
    
    @autoreleasepool
	{
        if (pAudioManager->_bNeed8K)
        {
            char *pAudioData16K = new char[audioBuffer->mDataByteSize*2];
            [pAudioManager.audioDelegate audioManager:pAudioManager
                                       playbackSample:pAudioData16K
                                           withLength:audioBuffer->mDataByteSize*2];
            
            char *pAudioBufferData = (char*)audioBuffer->mData;
            short *pAudioBufferSample = (short*)pAudioBufferData;
            short *pAudioBufferSample16K = (short*)pAudioData16K;
            for (int i = 0; i < audioBuffer->mDataByteSize/2; i++)
            {
                pAudioBufferSample[i] = pAudioBufferSample16K[2*i];
            }
            
            delete []pAudioData16K;
            pAudioData16K = 0;
        }
        else
        {
            //int nAudioBufferSize = inNumberFrames * pAudioManager->_streamFormat.mBytesPerFrame;
            char *pAudioBufferData = (char*)audioBuffer->mData;
            [pAudioManager.audioDelegate audioManager:pAudioManager
                                       playbackSample:pAudioBufferData
                                           withLength:audioBuffer->mDataByteSize];
        }
	}
    
    return noErr;
    
}

@implementation AcuAudioManager
{
    AVAudioSession      *_audioSession;
    BOOL                _bEchoCancellationAvailable;
}

#if 0
+ (AcuAudioManager*)shareAudioManager
{
	static dispatch_once_t pred;
    static AcuAudioManager *audioManager = 0;
	
    dispatch_once(&pred, ^{
        audioManager = [[AcuAudioManager alloc] init];
    });
	
    return audioManager;
}
#endif

- (void)handleInterruption:(NSNotification *)notif
{
    AVAudioSessionInterruptionType interrupt = (AVAudioSessionInterruptionType)[[notif.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (interrupt == AVAudioSessionInterruptionTypeBegan)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification
                                                            object:nil];
    }
    else if (interrupt == AVAudioSessionInterruptionTypeEnded)
    {
        
    }
    
    
}

- (void)handleRouteChange:(NSNotification *)notification
{
    NSInteger  reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    //    AVAudioSessionRouteDescription* prevRoute = [[notification userInfo] objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    //    switch (reason)
    //    {
    //        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
    //        case AVAudioSessionRouteChangeReasonWakeFromSleep:
    //        case AVAudioSessionRouteChangeReasonOverride:
    //        case AVAudioSessionRouteChangeReasonCategoryChange:
    //        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
    //        case AVAudioSessionRouteChangeReasonUnknown:
    //            return;
    //    }
    
#if 0
    if (reason == AVAudioSessionRouteChangeReasonUnknown)
    {
        NSLog(@"handleRouteChange: Unknown");
    }
    else if (reason == AVAudioSessionRouteChangeReasonNewDeviceAvailable)
    {
        NSLog(@"handleRouteChange: NewDeviceAvailable");
    }
    else if (reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable)
    {
        NSLog(@"handleRouteChange: OldDeviceUnavailable");
    }
    else if (reason == AVAudioSessionRouteChangeReasonCategoryChange)
    {
        NSLog(@"handleRouteChange: CategoryChange");
        NSLog(@"current category: %@",_audioSession.category);
    }
    else if (reason == AVAudioSessionRouteChangeReasonOverride)
    {
        NSLog(@"handleRouteChange: Override");
    }
    else if (reason == AVAudioSessionRouteChangeReasonWakeFromSleep)
    {
        NSLog(@"handleRouteChange: WakeFromSleep");
    }
    else if (reason == AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory)
    {
        NSLog(@"handleRouteChange: NoSuitableRouteForCategory");
    }
    else if (reason == AVAudioSessionRouteChangeReasonRouteConfigurationChange)
    {
        NSLog(@"handleRouteChange: RouteConfigurationChange");
    }
#endif

    if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == reason ||
        AVAudioSessionRouteChangeReasonOldDeviceUnavailable == reason)
    {
        if ([self isHeadsetPluggedIn])
        {
            [_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                                             error:nil];
        }
        else
        {
            [_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                             error:nil];
        }
    }
    
    
    if (AVAudioSessionRouteChangeReasonCategoryChange == reason)
    {
        if (![[_audioSession category] isEqualToString:AVAudioSessionCategoryPlayAndRecord])
        {
            //[_audioSession setActive:NO error:nil];
            [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                                 error:nil];
            //[_audioSession setActive:YES error:nil];
            
            if (_bHandFree)
            {
                [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            }
            else
            {
                [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            }
        }

    }
}

- (BOOL)isHeadsetPluggedIn
{
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs])
    {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

- (id)init
{
    self = [super init];
	if (self)
	{
        
#if USE_AUDIO_SESSION_API
		_bEchoCancellationAvailable = YES;
#else
        _bEchoCancellationAvailable = NO;
#endif
        _bEchoCancellationAvailable = YES;
        
		_bMute = NO;
        _captureDataFIFO.Create(512*1024);
		_oneCaptureAudioFrameDataLen = 1280;
        _videoCallAVMode = 0;
        _bHandFree = NO;
	}
	
	return self;
}

- (void)setMute:(BOOL)bMute
{
	@synchronized(self)
	{
		_bMute = bMute;
	}
}

- (void)setVideoCallAVMode:(int)videoCallAVMode
{
    _videoCallAVMode = videoCallAVMode;
}

- (void)setHandFreeMode:(BOOL)bHandFree
{
    _bHandFree = bHandFree;
    if (_running)
    {
#if 0
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        if (_bHandFree)
        {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                             withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                                   error:nil];
        }
        else
        {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                                   error:nil];
        }
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
#else
        if (_bHandFree)
        {
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        }
        else
        {
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
        }
#endif
        
    }
}

- (BOOL)setupDevice
{
    [self isNeed8KHz];
    
    OSStatus ostatus;
    
    int nWordsize = 2;
    
    /* Set the stream format */
    _streamFormat.mSampleRate       = 16000;
    _streamFormat.mFormatID         = kAudioFormatLinearPCM;
    _streamFormat.mFormatFlags      = kAudioFormatFlagsCanonical;
    //_streamFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    _streamFormat.mChannelsPerFrame = 1;
    _streamFormat.mBitsPerChannel   = nWordsize * 8;
    _streamFormat.mFramesPerPacket  = 1;
    _streamFormat.mBytesPerFrame    = _streamFormat.mChannelsPerFrame * nWordsize;
    _streamFormat.mBytesPerPacket   = _streamFormat.mBytesPerFrame * _streamFormat.mFramesPerPacket;
    
    AudioComponent comp;
    AudioComponentDescription desc;
    
    desc.componentType = kAudioUnitType_Output;
    if (_bEchoCancellationAvailable)
    {
        desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    }
    else
    {
        desc.componentSubType = kAudioUnitSubType_RemoteIO;
    }
    
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    comp = AudioComponentFindNext(NULL, &desc);
    if (comp == NULL)
    {
        return NO;
    }
    
    /* We want to be able to open playback and recording streams */
    _audioSession = [AVAudioSession sharedInstance];
    
#if 1
    {
        BOOL  bRet = YES;
        if ([_audioSession respondsToSelector:@selector(setCategory:withOptions:error:)])
        {
            bRet = [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                           withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                 error:nil];
        }
        else
        {
            bRet = [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                                 error:nil];
        }
        
        if (!bRet)
        {
            NSLog(@"set AVAudioSession setCategory error");
        }
        
        bRet = YES;
        if ([_audioSession respondsToSelector:@selector(setMode:error:)])
        {
            bRet = [_audioSession setMode:AVAudioSessionModeVoiceChat error:nil];
            if(!bRet)
            {
                NSLog(@"Set voice chat mode error");
            }
        }
        
        if (_videoCallAVMode == 1)
        {
            bRet = [_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                                             error:nil];
        }
        else
        {
            bRet = [_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                                    error:nil];
        }

    }
    
#else
    if ([_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:nil] != YES)
    {
        return NO;
    }
#endif
    
    //    if ([_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
    //                                              error:nil] != YES)
    //    {
    //        return NO;
    //    }
    
    //    Available values are AVAudioSessionPortOverrideNone and AVAudioSessionPortOverrideSpeaker
    //    - (BOOL) overrideOutputAudioPort:error:
    //    if ([self isHeadsetPluggedIn])
    //    {
    //
    //    }
    
    //    if([_audioSession setMode:AVAudioSessionModeVoiceChat error:nil] != YES)
    //    {
    //        return NO;
    //    }
    
    NSError *error = 0;
    if ([_audioSession setPreferredSampleRate:16000.0 error:&error] != YES)
    {
        return NO;
    };
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        if ([_audioSession setPreferredOutputNumberOfChannels:1
                                                        error:&error] != YES)
        {
            return NO;
        }
    }
    
    
    if ([_audioSession setPreferredIOBufferDuration:Acu_Audio_Manager_Preferred_Duration/1000.0
                                              error:&error] != YES)
    {
        return NO;
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:_audioSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    
    
    
    /* Create an audio unit to interface with the device */
    ostatus = AudioComponentInstanceNew(comp, &(_audioUnit));
    if (ostatus != noErr)
    {
        return NO;
    }
    
    UInt32 enable = 1;
    
    /* Enable input */
    ostatus = AudioUnitSetProperty(_audioUnit,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Input,
                                   1,
                                   &enable,
                                   sizeof(enable));
    if (ostatus != noErr)
    {
        return NO;
    }
    
    /* Enable output */
    ostatus = AudioUnitSetProperty(_audioUnit,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Output,
                                   0,
                                   &enable,
                                   sizeof(enable));
    if (ostatus != noErr)
    {
        return NO;
    }
    
    /* When setting the stream format, we have to make sure the sample
     * rate is supported. Setting an unsupported sample rate will cause
     * AudioUnitRender() to fail later.
     */
    ostatus = AudioUnitSetProperty(_audioUnit,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Output,
                                   1,
                                   &_streamFormat,
                                   sizeof(_streamFormat));
    if (ostatus != noErr)
    {
        return NO;
    }
    
    
    if(_bNeed8K)
    {
        _streamFormat8K.mSampleRate       = 8000;
        _streamFormat8K.mFormatID         = kAudioFormatLinearPCM;
        _streamFormat8K.mFormatFlags      = kAudioFormatFlagsCanonical;
        //_streamFormat8K.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        _streamFormat8K.mChannelsPerFrame = 1;
        _streamFormat8K.mBitsPerChannel   = nWordsize * 8;
        _streamFormat8K.mFramesPerPacket  = 1;
        _streamFormat8K.mBytesPerFrame    = _streamFormat8K.mChannelsPerFrame * nWordsize;
        _streamFormat8K.mBytesPerPacket   = _streamFormat8K.mBytesPerFrame * _streamFormat8K.mFramesPerPacket;
        
        ostatus = AudioUnitSetProperty(_audioUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       0,
                                       &_streamFormat8K,
                                       sizeof(_streamFormat8K));
        if (ostatus != noErr)
        {
            return NO;
        }
    }
    else
    {
        /* Set the stream format */
        ostatus = AudioUnitSetProperty(_audioUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       0,
                                       &_streamFormat,
                                       sizeof(_streamFormat));
        if (ostatus != noErr)
        {
            return NO;
        }
    }
    
    /* Set render callback */
    AURenderCallbackStruct output_cb;
    output_cb.inputProc = output_renderer;
    output_cb.inputProcRefCon = (__bridge void *)(self);
    ostatus = AudioUnitSetProperty(_audioUnit,
                                   kAudioUnitProperty_SetRenderCallback,
                                   kAudioUnitScope_Input,
                                   0,
                                   &output_cb,
                                   sizeof(output_cb));
    if (ostatus != noErr)
    {
        return NO;
    }
    
    AURenderCallbackStruct input_cb;
    /* Set input callback */
    input_cb.inputProc = input_callback;
    input_cb.inputProcRefCon = (__bridge void *)(self);
    ostatus = AudioUnitSetProperty(_audioUnit,
                                   kAudioOutputUnitProperty_SetInputCallback,
                                   kAudioUnitScope_Global,
                                   0,
                                   &input_cb,
                                   sizeof(input_cb));
    if (ostatus != noErr)
    {
        NO;
    }
    
    
    /* We will let AudioUnitRender() to allocate the buffer
     * for us later
     */
    _audioBufferList= (AudioBufferList*)malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer));
    if (!_audioBufferList)
    {
        return NO;
    }
    
    _audioBufferList->mNumberBuffers = 1;
    _audioBufferList->mBuffers[0].mNumberChannels = _streamFormat.mChannelsPerFrame;
    
    /* Initialize the audio unit */
    ostatus = AudioUnitInitialize(_audioUnit);
    if (ostatus != noErr)
    {
        return NO;
    }
    
    return YES;
}

- (void)teardownDevice
{
    AudioUnitUninitialize(_audioUnit);
    AudioComponentInstanceDispose(_audioUnit);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)startAudioManager
{
    if (_running)
    {
        return NO;
    }
    
    OSStatus ostatus;
    
    BOOL bRet = [self setupDevice];
    if (!bRet)
    {
        return NO;
    }
    
    if ([_audioSession setActive:YES error:nil] != YES)
    {
        return NO;
    }
    
    ostatus = AudioOutputUnitStart(_audioUnit);
    if (ostatus != noErr)
    {
        return NO;
    }
    
    _running = YES;
    
    return YES;
}

- (void)stopAudioManager
{
    if (!_running)
    {
        return;
    }
    
    _running = NO;
    _bMute = YES;
    
    OSStatus ostatus;
    
    ostatus = AudioOutputUnitStop(_audioUnit);
    if (ostatus != noErr)
    {
        NSLog(@"Stop audio unit error");
    }
    
    [self teardownDevice];
    
    if ([_audioSession setActive:false error:nil] != YES)
    {
        NSLog(@"deactive audio session error");
    }
    
    free(_audioBufferList);
    
    return;
}

- (void)isNeed8KHz
{
    NSString *sDeviceModel = [AcuDeviceHardware platformString];
    NSString *aux = [[sDeviceModel componentsSeparatedByString:@","] objectAtIndex:0];
    if ([aux rangeOfString:@"iPhone"].location != NSNotFound)
    {
        int version = [[aux stringByReplacingOccurrencesOfString:@"iPhone" withString:@""] intValue];
        if(version == 6)
        {
            //iPhone 5S
            _bNeed8K = true;
        }
        else if(version == 5)
        {
            int minVersion = [[sDeviceModel stringByReplacingOccurrencesOfString:@"iPhone5," withString:@""] intValue];
            if (minVersion == 3 || minVersion == 4)
            {
                //iPhone 5C
                _bNeed8K = true;
            }
        }
        
        return;
    }
    
    if ([aux rangeOfString:@"iPad"].location != NSNotFound)
    {
        int version = [[aux stringByReplacingOccurrencesOfString:@"iPad" withString:@""] intValue];
        if(version == 4)
        {
            int minVersion = [[sDeviceModel stringByReplacingOccurrencesOfString:@"iPad4," withString:@""] intValue];
            if (minVersion == 1 || minVersion == 2 || minVersion == 3)
            {
                //iPad Air
                _bNeed8K = true;
            }
        }
        
        return;
    }
}

@end
