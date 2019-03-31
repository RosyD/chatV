//
//  ACAudioManager.m
//
//
//  Created by Aculearn on 13-11-14.
//
//



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
#include <AVFoundation/AVAudioSession.h>
#import "ACAudioManager.h"


@implementation ACAudioManager{
    AVAudioSession                      *_audioSession;
    __weak id <ACAudioManagerDelegate>  _delegate;
}



- (void)handleInterruption:(NSNotification *)notif{
    AVAudioSessionInterruptionType interrupt = (AVAudioSessionInterruptionType)[[notif.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (interrupt == AVAudioSessionInterruptionTypeBegan){
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification
                                                            object:nil];
    }
    else if (interrupt == AVAudioSessionInterruptionTypeEnded){
        
    }
}

- (void)handleRouteChange:(NSNotification *)notification{
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
    
#if 1
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
        AVAudioSessionRouteChangeReasonOldDeviceUnavailable == reason){
        [_delegate audioManager:self headseted:[ACAudioManager isHeadsetPluggedIn]];
        [self _setIsHandFreeMode:_isHandFreeMode];
    }
    
    
    if (AVAudioSessionRouteChangeReasonCategoryChange == reason){
        if (![[_audioSession category] isEqualToString:AVAudioSessionCategoryPlayAndRecord]){
            
            //[_audioSession setActive:NO error:nil];
            [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                                 error:nil];
            //[_audioSession setActive:YES error:nil];
            [self _setIsHandFreeMode:_isHandFreeMode];
        }
    }
}

+ (BOOL)isHeadsetPluggedIn{ //戴在头上的耳机或听筒

#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs])
    {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
#endif
}

-(void)_setIsHandFreeMode:(BOOL)bHandFree{
    _isHandFreeMode =   bHandFree;
    NSError* pErr = nil;
    
#if 0
    if(bHandFree){
        [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                       withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&pErr];
        ITLogEX(@"外放 %@",pErr.localizedDescription);
    }
    else{
        [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        ITLogEX(@"耳机 %@",pErr.localizedDescription);
    }
#else
    
    if (bHandFree&&(![ACAudioManager isHeadsetPluggedIn])){
        ITLogEX(@"外放 %@",pErr.localizedDescription);
        [_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&pErr];
    }
    else{
        [_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&pErr];
        ITLogEX(@"耳机 %@",pErr.localizedDescription);
    }
#endif
//    ITLogEX(@"%@ err=%@",bHandFree?@"外放":@"耳机",pErr.localizedDescription);
}

-(void)setIsHandFreeMode:(BOOL)bHandFree{
//    if(_isHandFreeMode!=bHandFree)
    {
        [self _setIsHandFreeMode:bHandFree];
    }
}

- (void)changeMode:(BOOL)forVideoCall{
//    [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
//                                error:nil];
    
    self.isHandFreeMode =   forVideoCall;
    
    NSArray* inputArray = [_audioSession availableInputs];
    for (AVAudioSessionPortDescription* desc in inputArray) {
        if ([desc.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
            NSError* error;
            [_audioSession setPreferredInput:desc error:&error];
        }  
    }
    
    

//    [_audioSession setMode:forVideoCall?AVAudioSessionModeVideoChat:AVAudioSessionModeVoiceChat error:nil];
}

+ (instancetype)startAudioManagerWithDelegate:(id <ACAudioManagerDelegate>)dela{
    ACAudioManager* pRet = [ACAudioManager new];
    pRet->_delegate =   dela;
    [pRet _startAudioManager];
    return pRet;
}

-(void)_startAudioManager{
    
    if(_audioSession){
        return;
    }
    
    _audioSession = [AVAudioSession sharedInstance];
    
    
    BOOL  bRet = YES;
//    if ([_audioSession respondsToSelector:@selector(setCategory:withOptions:error:)]){
//        bRet = [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
//                              withOptions:AVAudioSessionCategoryOptionAllowBluetooth
//                                    error:nil];
//    }
//    else
    {
        bRet = [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                                    error:nil];
    }
    
    if (!bRet){
        ITLog(@"set AVAudioSession setCategory error");
    }
    
    /*
    bRet = YES;
    if ([_audioSession respondsToSelector:@selector(setMode:error:)]){
        bRet = [_audioSession setMode:AVAudioSessionModeVoiceChat error:nil];
        if(!bRet){
            ITLog(@"Set voice chat mode error");
        }
        //    [_audioSession setMode:AVAudioSessionModeVoiceChat error:nil]; IOS9 可能不被支持
   }*/
    
    bRet = [_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                                            error:nil];
//不知道什么作用
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
//    {
//        if ([_audioSession setPreferredOutputNumberOfChannels:1
//                                                        error:nil] != YES)
//        {
//            return NO;
//        }
//    }
    
    

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:_audioSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    
    [_audioSession setActive:YES error:nil];
}

- (void)stopAudioManager{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (!_audioSession){
        return;
    }
    
//    [_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    [_audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    _audioSession = nil;
}


@end
