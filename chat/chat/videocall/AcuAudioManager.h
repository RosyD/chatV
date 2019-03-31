//
//  AcuAudioManager.h
//  
//
//  Created by Aculearn on 13-11-14.
//
//

#import <Foundation/Foundation.h>
#include <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioConverter.h>

#include <AVFoundation/AVAudioSession.h>

#define AudioDeviceID unsigned

/**
 * As in iOS SDK 4 or later, audio route change property listener is
 * no longer necessary. Just make surethat your application can receive
 * remote control events by adding the code:
 *     [[UIApplication sharedApplication]
 *      beginReceivingRemoteControlEvents];
 * Otherwise audio route change (such as headset plug/unplug) will not be
 * processed while your application is in the background mode.
 */
#define USE_AUDIO_ROUTE_CHANGE_PROP_LISTENER 0

/* Starting iOS SDK 7, Audio Session API is deprecated. */
#define USE_AUDIO_SESSION_API 0

@class AcuAudioManager;

@protocol AcuAudioManagerSampleDataDelegate <NSObject>

- (void)audioManager:(AcuAudioManager*)audioManager playbackSample:(char*)sampleData withLength:(int)audioLength;
- (void)audioManager:(AcuAudioManager*)audioManager captureSample:(char*)sampleData withLength:(int)audioLength;

@end

@interface AcuAudioManager : NSObject
{
    
}

@property (nonatomic, weak) id<AcuAudioManagerSampleDataDelegate> audioDelegate;
/*
 //1是语音呼叫， 0是视频呼叫
 */
@property (nonatomic, assign) int               videoCallAVMode;

- (BOOL)startAudioManager;
- (void)stopAudioManager;
- (void)setMute:(BOOL)bMute;
- (void)setVideoCallAVMode:(int)videoCallAVMode;
- (void)setHandFreeMode:(BOOL)bHandFree;

@end
