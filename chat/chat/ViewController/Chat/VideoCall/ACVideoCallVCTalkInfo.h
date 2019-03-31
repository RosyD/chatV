//
//  ACVideoCallVC+Talk.h
//  chat
//
//  Created by Aculearn on 16/11/28.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACVideoCallVC.h"


@class SRWebSocket;
@class RTCEAGLVideoView;
@class RTCPeerConnectionFactory;
@class RTCPeerConnection;
@class RTCVideoTrack;
@class RTCAudioTrack;
@class RTCMediaStream;



@interface ACVideoCallVC_TalkInfo :NSObject{
    RTCEAGLVideoView *_remoteVideoView;
    CGSize           _remoteVideoViewSize;
    RTCEAGLVideoView *_localVideoView;
    CGSize           _localVideoViewSize;
    
    __weak UIImageView *_audio_bk_imageView;
    __weak UIImageView *_audio_user_icon;
    __weak UILabel     *_audio_user_Name;
    
    
    UIButton *_videoChangeCamera_Button;
    
    UIView   *_button_bk_view;
    UIButton *_left_Button;
    UIButton *_center_Button;
    UIButton *_right_Button;
    
    UIButton *_decline_Button;
    
    __weak UILabel *_tipLable;
    
    UIButton *_minButton;
    UIView *_minAudioView;
    UIImageView *_minAudioFlagImag;
    UILabel *_minAudioTimeLabel;
    
    //    NSTimer*        _timer;
    //    NSTimeInterval  _nTimeBegin;
    __weak ACUser*     _caller;
    
    BOOL _isSender, _isReceiverReady;
    NSString *_room;
    
    RTCPeerConnectionFactory *_factory;
    RTCPeerConnection *pc;
    
    

    RTCAudioTrack   *_localAudioTrack;
    RTCVideoTrack   *_localVideoTrack;
    
    
    RTCMediaStream *_localMediaStream, *_remoteMediaStream;
    //    RTCMediaConstraints *offerOrAConstraints;
    
    //    RTCVideoTrack * _localVideoTrack;
    BOOL            _localVideoIsFront;
    BOOL            _remoteViewFullScreen; //远程View全屏
    int             _remoteScreenOrientation;
    int             _p2pSendSataSata;   //发送Stat的状态
    int             _webSocketReconnectCount; //webSocket重试次数
    CGFloat         _fviewWidth;    //self.view.frame.size.width
    
    
    //    UIView *_tipViewBk;
    //    UILabel *_tipViewLable;
    //    UIButton *_tipViewButton;
    //
    time_t            _beingTimeSeconds; //开始时间
    NSTimer*          _timerForMin; //最小化后显示时间
    
    //    CGRect          _frame;
    
    //    SocketIOClient *socket;
    SRWebSocket                 *_webSocket;
    NSString                    *_socktID_me;
    NSMutableArray<NSString*>          *_socktID_others;
    
    __weak NSDictionary*   _webRTC_Config;
    
    //    ACAudioManager* _audioManger;
    
    __weak  ACVideoCallVC*  _videoCallVC;
    
    BOOL    _isHandFreeMode;    //是否设置了外放
    BOOL    _isHandFreeModeForAudio; //
    BOOL    _beforeMinimized_LocalVideoHidded; //最小化之前，本地视频是否关闭了
}

@property (nonatomic,readonly) BOOL isVideoCallUI;
@property (nonatomic,readonly) BOOL isMinimized; //最小化了
@property (nonatomic,weak)      UIView*     view;
@property (nonatomic,strong)    UIView*     minTipBkView;   //最小化时的提示View


-(instancetype)initWithCallVC:(ACVideoCallVC*)pVC;
-(void)showTalk;
-(void)showCameraBkView; //显示背景CameraView
//-(void)testFunc;

-(void)forceTerminate_Talk;

-(void)viewDidDisappear__Call;
-(void)viewWillLayoutSubviews_Call;
-(UIInterfaceOrientationMask)supportedInterfaceOrientations_Call;
- (BOOL)prefersStatusBarHidden_Call;


-(void)_stopWithTip:(NSString*)pTip;
-(void)_tipShow:(NSString*)pTip;
-(void)_changeUI_forFirst:(BOOL)bFirst;
-(void)_fullScreenRemoteView:(BOOL)bRemoteView;
-(void)_videoView:(RTCEAGLVideoView*)videoView showFullScreen:(BOOL)bFullScreen;
-(void)_onMinOk:(id)sender;
-(void)_hideButtons:(BOOL)bHide;
-(void)_hideButtonsSetAuto:(BOOL)bSet;
-(void)_orientationScreen; //强制竖屏

@end
