//
//  ACVideoCallVC.m
//  chat
//
//  Created by Aculearn on 16/11/28.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACVideoCallVCTalkInfo+webRTC.h"


#import "RTCDataChannel.h"

#import "RTCLogging.h"
#import "RTCFileLogger.h"
#import "RTCPair.h"
#import "RTCMediaSource.h"
#import "RTCEAGLVideoView.h"
#import "RTCMediaStream.h"
#import "RTCVideoTrack.h"
#import "RTCAudioTrack.h"
#import "RTCVideoSource.h"
#import "RTCVideoCapturer.h"
#import "RTCMediaConstraints.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCICEServer.h"
#import "RTCDataChannel.h"
#import "RTCPeerConnection.h"
#import "RTCSessionDescription.h"
#import "RTCICECandidate.h"
#import "RTCTypes.h"
#import "UINavigationController+Additions.h"
#import "ACMessage.h"
#import "JSONKit.h"
#import "ACNoteListVC_Cell.h"
#import "ACUser.h"
#import "ACVideoCall.h"
//#import "ACAudioManager.h"
#include <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
//#ifdef BUILD_FOR_EGA
//    #import "GovChat-swift.h"
//#else
//    #import "chat-swift.h"
//#endif


/*58103836@qq.com 000000
 通过控制 MediaStream的MediaStreamTrack对象的enabled属性
 
	MediaStream.getAudioTracks()[0].enabled = true|false; //关闭麦克
	MediaStream.getVideoTracks()[0].enabled = true|false; //关闭摄像头
 
 
 通过监听远程MediaStream的MediaStreamTrack的mute和unmute事件，来判断远程stream是否关闭或打开了音视频设备。
 (不一定所有设备都支持)
 
 pc.onaddstream = function(evt) {
 that.emit('pc_add_stream', evt.stream, socketId, pc);
 evt.stream.getTracks().forEach(function(track){
 track.onmute = function(e){
 that.emit("remote_track_mute", this, socketId);
 };
 track.onunmute = function(e){
 that.emit("remote_track_unmute", this, socketId);
 };
 });
 };
 
 音视频设备切换
 
 pc.removeStream(oldMediaStream);
 pc.addStream(newMediaStream);
 closeOldMediaStream;
 sendOffer();
 
 */


#ifdef ACUtility_Need_Log
//打开webRTC的日志输出
#define NEED_WEB_RTC_LOG
#endif

#define AUDIO_MIN_SIZE_W    45      //Audio最小化时Wnd大小
#define AUDIO_MIN_SIZE_H    53


#define _p2pSendSataSata_FirstSended    1
#define _p2pSendSataSata_CancelSended   2   //已经调用过Cancel了



@implementation NSURLRequest (NSURLRequestWithIgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}

@end

@implementation ACVideoCallVC_TalkInfo(webRTC)


//#define USE_localAudioTrack //使用 _localAudioTrack

-(void)_setAudioTrack:(BOOL)bEnable{

#ifdef USE_localAudioTrack
    [_localAudioTrack setEnabled:bEnable];
#else
    
    [_localMediaStream removeAudioTrack:_localMediaStream.audioTracks.firstObject];
    
    if(bEnable){
        [_localMediaStream addAudioTrack:_localAudioTrack];
    }
    [pc removeStream:_localMediaStream];
    [pc addStream:_localMediaStream];
  
    if(bEnable&&_isHandFreeMode){
        [self _setIsHandFreeMode:_isHandFreeMode];
    }
   
 
    
    /*
    RTCAudioTrack* audiorTrack =    _localMediaStream.audioTracks.firstObject;
    if(audiorTrack){
        [_localMediaStream removeAudioTrack:audiorTrack];
    }
    
    if(bEnable){
        [_localMediaStream addAudioTrack:[_factory audioTrackWithID:@"audio1"]];
    }*/
#endif
}


- (RTCMediaConstraints *)_defaultMediaStreamConstraints {
    NSArray *mandatoryConstraints = @[
/*                                      [[RTCPair alloc] initWithKey:@"maxWidth" value:@"1920"],
                                      [[RTCPair alloc] initWithKey:@"minWidth" value:@"1280"],
                                      
                                      [[RTCPair alloc] initWithKey:@"maxHeight" value:@"1080"],
                                      [[RTCPair alloc] initWithKey:@"minHeight" value:@"720"],*/
                                      
                                      
                                      [[RTCPair alloc] initWithKey:@"maxWidth" value:@"1280"],
                                      [[RTCPair alloc] initWithKey:@"minWidth" value:@"720"],
                                      
                                      [[RTCPair alloc] initWithKey:@"maxHeight" value:@"720"],
                                      [[RTCPair alloc] initWithKey:@"minHeight" value:@"480"],
                                      
                                      [[RTCPair alloc] initWithKey:@"maxFrameRate" value:@"30"],
                                      [[RTCPair alloc] initWithKey:@"minFrameRate" value:@"20"],
                                      //                                      [[RTCPair alloc] initWithKey:@"googLeakyBucket" value:@"true"]
                                      ];
    
    RTCMediaConstraints *constrains = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
    return constrains;
}


//-(void)_locaVideoRemove{
//    RTCVideoTrack* localVideoTrack = _localMediaStream.videoTracks.firstObject;
//    if(localVideoTrack){
//        [localVideoTrack removeRenderer:_localVideoView];
//        [_localMediaStream removeVideoTrack:localVideoTrack];
//    }
//}

-(RTCVideoTrack*)_locaVideoGetForFront:(BOOL)bFront{
    
    _localVideoIsFront  =   bFront;
    
    
    /*
     @[
     [[RTCPair alloc] initWithKey:@"maxWidth" value:[NSString stringWithFormat:@"%f", self.view.frame.size.width]],
     [[RTCPair alloc] initWithKey:@"maxHeight" value:[NSString stringWithFormat:@"%f", self.view.frame.size.height]],
     [[RTCPair alloc] initWithKey:@"maxFrameRate" value:@"15"]] optionalConstraints:nil];
     */
    
    
    //    RTCMediaConstraints *mediaConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
    
    RTCMediaConstraints *mediaConstraints = [self _defaultMediaStreamConstraints];
    
    NSString *cameraID = nil;
    AVCaptureDevicePosition nType=  bFront?AVCaptureDevicePositionFront:AVCaptureDevicePositionBack;
    for (AVCaptureDevice *captureDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == nType) {
            cameraID = captureDevice.localizedName;
            break;
        }
    }
    
    //            AVCaptureDevicePositionBack                = 1,
    //            AVCaptureDevicePositionFront               = 2
    
    RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    
    RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer constraints:mediaConstraints];
    
    _localVideoTrack = [_factory videoTrackWithID:@"video1" source:videoSource];
    [_localVideoTrack addRenderer:_localVideoView];
    
    if(_localVideoIsFront){
        _localVideoView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    }
    else{
        _localVideoView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }
    return _localVideoTrack;
}

-(void) _locaVideoEnable:(BOOL)bEnable{
    [_localVideoTrack setEnabled:bEnable];
}
-(void)_locaVideoSetDevice:(BOOL)bFront{
    
    if(_localVideoTrack){
        if(_localVideoIsFront==bFront){
            [_localVideoTrack setEnabled:YES];
            return;
        }
        [_localVideoTrack removeRenderer:_localVideoView];
        [_localMediaStream removeVideoTrack:_localVideoTrack];
        
        _localVideoTrack = nil;
    }
    
    [_localMediaStream addVideoTrack:[self _locaVideoGetForFront:bFront]];
}

-(void)_getLocalMediaWithAudio:(BOOL)bNeedAudio{
    if(nil==_factory){
        _factory = [RTCPeerConnectionFactory new];
    }
    
    if(nil==_localMediaStream){
        _localMediaStream = [_factory mediaStreamWithLabel:@"stream"];
        [self _locaVideoSetDevice:YES];
    }
    
    if(bNeedAudio&&nil==_localAudioTrack){
        _localAudioTrack    =   [_factory audioTrackWithID:@"audio1"];
        [_localMediaStream addAudioTrack:_localAudioTrack];
    }
}

- (void)_getMedia {
    
    [self _getLocalMediaWithAudio:YES];
    
    //发送Offer
    if(_isSender){
        [self _start];
    }
    else{
        _isReceiverReady = YES;
        [self _sendEvent:@"__ready" withData:@{@"socketId":_socktID_others[0]}];
    }
}


- (RTCMediaConstraints *)_offerOranswerConstraint
{
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@[[[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                                                                                   [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]]
                                                                             optionalConstraints:nil];
    return constraints;
}

#ifdef NEED_WEB_RTC_LOG
RTCFileLogger*  g____loggerFile = nil;
#endif

- (void)_start {
    if (pc == nil && _localMediaStream != nil && _isReceiverReady) {
        ITLogEX(@"%@",_isSender?@"  IsSender  ":@"");
        
#ifdef NEED_WEB_RTC_LOG
        g____loggerFile =   [RTCFileLogger new];
        [g____loggerFile start];
#endif
        
        NSMutableArray* serverConfig = [[NSMutableArray alloc] initWithCapacity:10];
        NSArray<NSDictionary*> *pIces =  _webRTC_Config[@"ice"];
        for(NSDictionary* pItem in  pIces){
            NSString*   pUserName   = pItem[@"username"];
            NSString*   pPwd    =   pItem[@"credential"];
            [serverConfig addObject:[[RTCICEServer alloc] initWithURI:[NSURL URLWithString:pItem[@"url"]] username:pUserName?pUserName:@"" password:pPwd?pPwd:@""]];
        }
        
        //        NSArray *serverConfig1 = [NSArray arrayWithObjects:
        //                                 [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:_webRTC_Config[webRCT_Cfg_Field_stun]] username:@"" password:@""],
        //                                 [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:_webRTC_Config[webRCT_Cfg_Field_turn]] username:_webRTC_Config[webRCT_Cfg_Field_turnUser] password:_webRTC_Config[webRCT_Cfg_Field_turnPwd]],
        //                                 nil];
        
        
        
        
        RTCMediaConstraints* peerConnectionConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@[[[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                                                                                                     [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]]
                                                                                               optionalConstraints:@[[[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]]];
        
        pc = [_factory peerConnectionWithICEServers:serverConfig constraints:peerConnectionConstraints delegate:self];
        [pc addStream:_localMediaStream];
        if (_isSender) {
            [pc createOfferWithDelegate:self constraints:[self _offerOranswerConstraint]]; //RTCSessionDescriptionDelegate
        }
        else {
            
        }
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRouteChange:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:nil];
    }
}

-(void)_sendCancelStat{
    if(_webRTC_Config){
        NSDictionary* pCfg =    _webRTC_Config;
        _webRTC_Config  =   nil;
        if(_p2pSendSataSata_CancelSended!=_p2pSendSataSata){
            
            [ACVideoCall webRTC_SendStat:_p2pSendSataSata_FirstSended==_p2pSendSataSata?webRTC_SendStat_Cancel_Success:webRTC_SendStat_Cancel_Failed
                                 withCfg:pCfg];
            _p2pSendSataSata    =   _p2pSendSataSata_CancelSended;
        }
    }
}

- (void)_stop{
    //    [_timer invalidate];_timer = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    
    [self _sendCancelStat];
    
    [_localVideoTrack removeRenderer:_localVideoView];
    
    if (pc != nil) {
        pc.delegate = nil;
        ITLog(@"webRTC stop release");
//        [pc removeStream:_localMediaStream];
//        [pc removeStream:_remoteMediaStream];
        [pc close];
        pc = nil;
        _remoteVideoView.hidden  = YES;
    }
    [_webSocket close];
    _webSocket = nil;
    _localVideoView.hidden = YES;
    
#ifdef NEED_WEB_RTC_LOG
    if(g____loggerFile){
        [g____loggerFile stop];
        NSString* pLog = [[NSString alloc] initWithData:[g____loggerFile logData]  encoding:NSUTF8StringEncoding];
        if(pLog.length){
            ITLogEX(@"\n\n----------webRTC logs--------\n\n%@\n\n",pLog );
        }
        g____loggerFile = nil;
    }
#endif
    
}

#pragma mark SRWebSocketDelegate

-(void)_sendEvent:(NSString*)pEvent withData:(NSDictionary*)pData{
    NSString* pSendString = [@{@"eventName":pEvent,@"data":pData} JSONString];
    [_webSocket send:pSendString];
    
#ifdef ACUtility_Need_Log
    if(![pEvent isEqualToString:@"__ice_candidate"]){
        ITLogEX(@"%@",pEvent);
    }
#endif
}

-(void)_webSocketTimeOutFuncForFirstJoin{
    ITLogEX(@"%d",_p2pSendSataSata);
    if(0==_p2pSendSataSata){
        [self _stopWithTip:nil];
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    _webSocketReconnectCount =   INT_MAX;
    if(0==_p2pSendSataSata){
        //
        int nTimeOUt = [_webRTC_Config[@"timeout"] intValue]/1000;
        [self performSelector:@selector(_webSocketTimeOutFuncForFirstJoin)
                   withObject:self
                   afterDelay:nTimeOUt];
        [self _sendEvent:@"__join" withData:@{@"room": _room}];
    }
    else{
        [self _sendEvent:@"__join" withData:@{@"room": _room,@"socketId":_socktID_me}];
    }
}


-(void)_webSocketTimeOutFuncForRetryConnect{
    ITLog(@"");
    [_webSocket open];
}

-(void)_webSocketRetryConnectWithDelay{
    int signalMaxRetry = [_webRTC_Config[@"signalMaxRetry"] intValue]+1;
    
    if(_webSocketReconnectCount<signalMaxRetry){
        //webSocketDidOpen(){_webSocketReconnectCount =   INT_MAX;}
        _webSocketReconnectCount ++;
        if(_webSocketReconnectCount>=signalMaxRetry){
            [self _stopWithTip:nil];
            return;
        }
    }
    
    [self performSelector:@selector(_webSocketTimeOutFuncForRetryConnect)
               withObject:self
               afterDelay:[_webRTC_Config[@"retryWait"] intValue]/1000];
}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    ITLogEX(@"%@,stat=%d",error.localizedDescription,(int)webSocket.readyState);
    if(SR_CONNECTING==webSocket.readyState){
        //再试试
        [self _webSocketRetryConnectWithDelay];
    }
}



- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    ITLogEX(@"[%d]%@",(int)code,reason);
    if(SRStatusCodeNormal==code){
        return;
    }
    [self _webSocketRetryConnectWithDelay];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    NSDictionary* pDict = [(NSString*)message objectFromJSONString];
    NSString* eventName = pDict[@"eventName"];
    NSDictionary* pData = pDict[@"data"];
    
    if([@"_peers" isEqualToString:eventName]||
       [@"_new_peer" isEqualToString:eventName]){
        
        ITLogEX(@"%@",(NSString*)message);
        
        if([@"_peers" isEqualToString:eventName]){
            _socktID_others =   [NSMutableArray arrayWithArray:pData[@"connections"]];
            _socktID_me     =   pData[@"you"];
            _isSender       =   0!= _socktID_others.count;
        }
        else{
            [_socktID_others addObject:pData[@"socketId"]];
        }
        
        if(_socktID_others.count){
            [self _getMedia];
        }
        return;
    }
    
    if([@"_ice_candidate" isEqualToString:eventName]){
        //        ITLogEX(@"ice_candidate=%@",pData);
        RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:pData[@"id"] index:[pData[@"label"] intValue] sdp:pData[@"candidate"]];
        [pc addICECandidate:candidate];
        return;
    }
    
    if([@"_ready" isEqualToString:eventName]){
        _isReceiverReady = YES;
        [self _start];
        return;
    }
    
    
    ITLogEX(@"%@",eventName);
    
    if([@"_remove_peer" isEqualToString:eventName]){
        //"data" : { "socketId" : "85edb19e-b140-44dd-8e8d-3ce315ac8dad"}}
        //        NSString* pOtherSocketID = pData[@"socketId"];
        //        [self _stopWithTip:NSLocalizedString(@"Call stopped", nil)];
        return;
    }
    
    if([@"_notice" isEqualToString:eventName]){
        /*
         视频通话时候，默认使用扬声器和前置摄像头；语音通话时候，默认使用听筒，关闭摄像头
         语音和视频通话可以互转，用摄像头的开关按钮来切换，每次切换，都走一次默认设置
         
         XXX打开了麦克风
         XXX enabled microphone
         XXX关闭了麦克风
         XXX disabled microphone
         XXX打开了摄像头
         XXX enabled camera
         XXX关闭了摄像头
         XXX disabled camera
         */
        
        NSString* pDeviceStat = pData[@"device"];
        //        "device": "audioOn|audioOff|videoOn|videoOff"
        NSString* pTip = nil;
        if([pDeviceStat isEqualToString:@"audioOn"]){
            pTip    =   NSLocalizedString(@"%@ enabled microphone",nil);
        }
        else if([pDeviceStat isEqualToString:@"audioOff"]){
            pTip    =   NSLocalizedString(@"%@ disabled microphone",nil);
        }
        else if([pDeviceStat isEqualToString:@"videoOn"]){
            pTip    =   NSLocalizedString(@"%@ enabled camera",nil);
            //对方打开视频
            if(self.isMinimized){
                //已经最小化了
                _remoteVideoView.hidden = NO;
                [self _onMinOk:nil];
            }
            else{
                [UIView animateWithDuration:0.5 animations:^{
                    _remoteVideoView.hidden = NO;
                    [self _changeUI_forFirst:NO];
                }];
            }
        }
        else if([pDeviceStat isEqualToString:@"videoOff"]){
            
            pTip    =   NSLocalizedString(@"%@ disabled camera",nil);
            
            
            if(self.isMinimized){
                //已经最小化了
                _remoteVideoView.hidden = YES;
                [self _onMinOk:nil];
            }
            else{
                [UIView animateWithDuration:0.5 animations:^{
                    _remoteVideoView.hidden = YES;
                    [self _changeUI_forFirst:NO];
                }];
            }
        }
        
        if(pTip){
            pTip    =   [NSString stringWithFormat:pTip,_caller.name];
            if(self.isMinimized){
                [ACUtility showTip:pTip];
            }
            else{
                [self _tipShow:pTip];
            }
        }
        
        return;
    }
    
    NSDictionary* pSdpInfo = pData[@"sdp"];
    if(pSdpInfo){
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:pSdpInfo[@"type"] sdp:pSdpInfo[@"sdp"]];
        
        NSAssert(sdp,@"nil==sdp");
        
        if([@"_offer" isEqualToString:eventName]){
            [self _start];
            [pc setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
            return;
        }
        
        if([@"_answer" isEqualToString:eventName]){
            [pc setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
            return;
        }
    }
}




#pragma mark RTCEAGLVideoViewDelegate


- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
    ITLogEX(@"%@ %@",videoView.tag==1?@"Local":@"Remote",NSStringFromCGSize(size));
    if (videoView.tag == 1) {
        _localVideoViewSize =   size;
        if(self.isVideoCallUI&&0==_remoteVideoViewSize.width){
            [self _videoView:videoView showFullScreen:YES];
        }
        else{
            [self _videoView:videoView showFullScreen:!_remoteViewFullScreen];
        }
    }
    else {
        BOOL bIsInit =  0==_remoteVideoViewSize.width;
        _remoteVideoViewSize    =   size;
        if(self.isMinimized){
            [self _onMinOk:nil];
        }
        else if(bIsInit){
//            [UIView animateWithDuration:5 animations:^{
//                //动画居然没有效果,两个View，其中一个VIew有效果 ???
//                [self _fullScreenRemoteView:YES];
//            }];
            [self _fullScreenRemoteView:YES];
        }
        else{
            [self _videoView:videoView showFullScreen:_remoteViewFullScreen];
        }
    }
}

#pragma mark RTCPeerConnectionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged {
    //RTCSignalingClosed
#ifdef ACUtility_Need_Log
    static const char* _RTCSignalingState[]=
    {
        "RTCSignalingStable",
        "RTCSignalingHaveLocalOffer",
        "RTCSignalingHaveLocalPrAnswer",
        "RTCSignalingHaveRemoteOffer",
        "RTCSignalingHaveRemotePrAnswer",
        "RTCSignalingClosed"
    };
    ITLogEX(@"%s",_RTCSignalingState[stateChanged]);
#endif
}


-(void)_addedStreamFunc:(RTCMediaStream *)stream{
    ITLogEX(@"Audio=%d,Video=%d",(int)stream.audioTracks.count,(int)stream.videoTracks.count);
    
    
    RTCMediaStream* pOldStream =    _remoteMediaStream;
    _remoteMediaStream = stream;
    
    
    if(pOldStream&&pOldStream.videoTracks.count){
        [pOldStream.videoTracks.firstObject  removeRenderer:_remoteVideoView];
    }
    
    if(_localVideoView.hidden){
        //关闭视频
        [_localVideoTrack setEnabled:NO];
    }
    
    if(_remoteMediaStream.videoTracks.count){
        [_remoteMediaStream.videoTracks[0]  addRenderer:_remoteVideoView];
    }
    else{
        _remoteVideoView.hidden = YES;
    }
    
    if(pOldStream){
        pOldStream = nil;
        [self _changeUI_forFirst:NO];
    }
    else{
        [self.view hideProgressHUDWithAnimated:NO];
        
        //        _timer  =   [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_timeStickFunc) userInfo:nil repeats:YES];
        //        _nTimeBegin =   [NSDate timeIntervalSinceReferenceDate];
        [self _changeUI_forFirst:NO];
        [self _hideButtons:self.isVideoCallUI];
        _beingTimeSeconds   =   time(NULL);
        [self _setIsHandFreeMode:self.isVideoCallUI];
        [self.view setNeedsLayout];
    }
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream {
    wself_define();
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself _addedStreamFunc:stream];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream {
    ITLog(@"");
}

- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection {
    ITLog(@"");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState {
#ifdef ACUtility_Need_Log
    static const char* _RTCICEConnectionState_name[]={
        "RTCICEConnectionNew",
        "RTCICEConnectionChecking",
        "RTCICEConnectionConnected",
        "RTCICEConnectionCompleted",
        "RTCICEConnectionFailed",
        "RTCICEConnectionDisconnected",
        "RTCICEConnectionClosed",
        "RTCICEConnectionMax"
    };
    ITLogEX(@"%s",_RTCICEConnectionState_name[newState]);
#endif
    
    if(RTCICEConnectionConnected==newState){
        if(0==_p2pSendSataSata){
            _p2pSendSataSata = _p2pSendSataSata_FirstSended;
            [ACVideoCall webRTC_SendStat:webRTC_SendStat_FirstSuccess withCfg:_webRTC_Config];
        }
    }
    else if(RTCICEConnectionFailed==newState){
        [self _stopWithTip:nil];
    }
    else if(RTCICEConnectionDisconnected==newState&&
            UIApplicationStateBackground==[[UIApplication sharedApplication] applicationState]){
        [self _stopWithTip:NSLocalizedString(@"VideoCall_End",nil)];
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceGatheringChanged:(RTCICEGatheringState)newState {
#ifdef ACUtility_Need_Log
    static const char* _RTCICEGatheringState[]= {
        "RTCICEGatheringNew",
        "RTCICEGatheringGathering",
        "RTCICEGatheringComplete"
    } ;
    ITLogEX(@"%s",_RTCICEGatheringState[newState]);
#endif
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection gotICECandidate:(RTCICECandidate *)candidate {
    //    NSDictionary *json = @{
    //        @"type": @"candidate",
    //        @"label": [NSString stringWithFormat:@"%d", (int)candidate.sdpMLineIndex],
    //        @"id": candidate.sdpMid,
    //        @"candidate": candidate.sdp
    //    };
    //    [self signal:json];
    //    ITLog(@"");
    [self _sendEvent:@"__ice_candidate" withData:@{@"label": @(candidate.sdpMLineIndex),
                                                   @"candidate": candidate.sdp,
                                                   @"id":candidate.sdpMid,
                                                   @"socketId": _socktID_others[0]}];
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection didOpenDataChannel:(RTCDataChannel*)dataChannel {
    ITLog(@"");
}

#pragma mark RTCSessionDescriptionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error {
    if (error) {
        ITLogEX(@"create sdp error : %@ ", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
#if DEBUG
            [self _stopWithTip:[NSString stringWithFormat:@"create sdp error : %@ ", error.localizedDescription]];
#else
            [self _stopWithTip:nil];
#endif
        });
    }
    else {
        //        ITLogEX(@"%@",sdp.description);
        ITLog(@"");
        //        NSDictionary *json = @{
        //            @"type": sdp.type,
        //            @"sdp": sdp.description
        //        };
        [pc setLocalDescriptionWithDelegate:self sessionDescription:sdp];
        //        [self signal:json];
        
        //        if([sdp.type isEqualToString:@"offer"]){
        //            [self _sendEvent:@"__offer"
        //                    withData:@{@"socketId": _socktID_others[0],@"sdp":@{@"type":sdp.type,@"sdp":sdp.description}}];
        //        }
        //
        
        [self _sendEvent:[sdp.type isEqualToString:@"offer"]?@"__offer":@"__answer"
                withData:@{@"socketId": _socktID_others[0],@"sdp":@{@"type":sdp.type,@"sdp":sdp.description}}];
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error {
    if (error) {
        ITLogEX(@"set sdp error : %@", error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
#if DEBUG
            [self _stopWithTip:[NSString stringWithFormat:@"set sdp error : %@", error.localizedDescription]];
#else
            [self _stopWithTip:nil];
#endif
        });
    }
    else {
        ITLog(@"");
        if (pc.signalingState == RTCSignalingHaveRemoteOffer) {
            [pc createAnswerWithDelegate:self constraints:[self _offerOranswerConstraint]];
            //RTCSessionDescriptionDelegate
        }
    }
}

#pragma mark HeadSet 耳机 话筒 外放

-(void)_setIsHandFreeMode:(BOOL)bHandFree{
    if(nil==_localMediaStream){
        return;
    }
    
    _isHandFreeMode =   bHandFree;
    NSError* pErr = nil;
    
    AVAudioSession* pSession =  [AVAudioSession sharedInstance];
    BOOL isIOS9 = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_x_Max&&
                   NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_9_x_Max)?(YES):(NO);
    
    //IOS9 下，在AVAudioSessionModeVoiceChat模式下，外放时，话筒会失效
    
#if 0
    if(bHandFree&&(![ACUtility isHeadsetPluggedIn])){
        [pSession setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&pErr];
        ITLogEX(@"外放(%@) mode=%@",pErr.localizedDescription,[AVAudioSession sharedInstance].mode);
    }
    else{
        [pSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        ITLogEX(@"听筒(%@) mode=%@",pErr.localizedDescription,[AVAudioSession sharedInstance].mode);
    }
#else
    
    if (bHandFree&&(![ACUtility isHeadsetPluggedIn])){
        if(isIOS9){
            [pSession setMode:AVAudioSessionModeDefault error:&pErr];
        }
        [pSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&pErr];
        ITLogEX(@"外放(%@) mode=%@",pErr.localizedDescription,[AVAudioSession sharedInstance].mode);
    }
    else{
        if(isIOS9){
            [pSession setMode:AVAudioSessionModeVoiceChat error:&pErr];
        }
        [pSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&pErr];
        ITLogEX(@"听筒(%@) mode=%@",pErr.localizedDescription,[AVAudioSession sharedInstance].mode);
    }
#endif
    
    
    //    ITLogEX(@"%@ err=%@",bHandFree?@"外放":@"耳机",pErr.localizedDescription);
    
}


-(void)_HeadsetChanged{
    //耳机发生改变
    if(!self.isVideoCallUI){
        _right_Button.enabled   =   ![ACUtility isHeadsetPluggedIn];
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
    
#if 0 //def ACUtility_Need_Log
    if (reason == AVAudioSessionRouteChangeReasonUnknown){
        ITLog(@"handleRouteChange: Unknown");
    }
    else if (reason == AVAudioSessionRouteChangeReasonNewDeviceAvailable){
        ITLog(@"handleRouteChange: NewDeviceAvailable");
    }
    else if (reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable){
        ITLog(@"handleRouteChange: OldDeviceUnavailable");
    }
    else if (reason == AVAudioSessionRouteChangeReasonCategoryChange){
        ITLog(@"handleRouteChange: CategoryChange");
        ITLogEX(@"current category: %@",[AVAudioSession sharedInstance].category);
    }
    else if (reason == AVAudioSessionRouteChangeReasonOverride){
        ITLog(@"handleRouteChange: Override");
    }
    else if (reason == AVAudioSessionRouteChangeReasonWakeFromSleep){
        ITLog(@"handleRouteChange: WakeFromSleep");
    }
    else if (reason == AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory){
        ITLog(@"handleRouteChange: NoSuitableRouteForCategory");
    }
    else if (reason == AVAudioSessionRouteChangeReasonRouteConfigurationChange){
        ITLog(@"handleRouteChange: RouteConfigurationChange");
    }
#endif
    
    
    ITLogEX(@"current category: %@ %@",[AVAudioSession sharedInstance].category,[AVAudioSession sharedInstance].mode);
    
    if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == reason ||
        AVAudioSessionRouteChangeReasonOldDeviceUnavailable == reason){
        ITLogEX(@"%@",[ACUtility isHeadsetPluggedIn]?@"插入耳机":@"拔出耳机");
        [self _HeadsetChanged];
        [self _setIsHandFreeMode:_isHandFreeMode];
    }
    
    
    if (AVAudioSessionRouteChangeReasonCategoryChange == reason){
        if (![[[AVAudioSession sharedInstance] category] isEqualToString:AVAudioSessionCategoryPlayAndRecord]){
            
            //[_audioSession setActive:NO error:nil];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                                   error:nil];
            //[_audioSession setActive:YES error:nil];
            [self _setIsHandFreeMode:_isHandFreeMode];
        }
    }
}


@end


