//
//  ACVideoCallVC+Talk.h
//  chat
//
//  Created by Aculearn on 16/11/28.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACVideoCallVCTalkInfo.h"


#import "SocketRocket.h"
#import "RTCEAGLVideoView.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCPeerConnectionDelegate.h"

@interface ACVideoCallVC_TalkInfo(webRTC) <SRWebSocketDelegate,RTCEAGLVideoViewDelegate, RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>


-(void)_setAudioTrack:(BOOL)bEnable;
//-(RTCVideoTrack*)_locaVideoGetForFront:(BOOL)bFront;
-(void) _locaVideoSetDevice:(BOOL)bFront;
-(void) _locaVideoEnable:(BOOL)bEnable;
-(void) _stop;
-(void) _getLocalMediaWithAudio:(BOOL)bNeedAudio;
-(void)_sendEvent:(NSString*)pEvent withData:(NSDictionary*)pData;
-(void)_HeadsetChanged; //耳机发生改变
-(void)_sendCancelStat;
-(void)_setIsHandFreeMode:(BOOL)bHandFree;

@end
