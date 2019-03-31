//
//  ACVideoCallVC.m
//  chat
//
//  Created by Aculearn on 16/11/28.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACVideoCallVCTalkInfo.h"
#import "ACVideoCallVCTalkInfo+webRTC.h"

#import "UINavigationController+Additions.h"
#import "ACMessage.h"
#import "JSONKit.h"
#import "ACNoteListVC_Cell.h"
#import "ACUser.h"
#import "ACVideoCall.h"


#define AUDIO_MIN_SIZE_W    45      //Audio最小化时Wnd大小
#define AUDIO_MIN_SIZE_H    53

#define Local_View_Min_Size_W   10  //最小化后本地视频的大小

@implementation NSURLRequest (NSURLRequestWithIgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}

@end

@implementation ACVideoCallVC_TalkInfo


AC_MEM_Dealloc_implementation



-(instancetype)initWithCallVC:(ACVideoCallVC*)pVC{
    self = [super init];
    if(self){
        _videoCallVC        =   pVC;
//        _webRTC_Config      =   pVC.webRTC_Config; //不在这里赋值，可能还没有取到
//        _room               =   _webRTC_Config[@"SessionID"];
        _audio_bk_imageView =   pVC.bkView;
        _audio_user_icon    =   pVC.userIconImageView;
        _audio_user_Name    =   pVC.userNameLable;
        _tipLable           =   pVC.answerCallerTipLable;
        _view               =   pVC.view;
        _caller             =   pVC.caller;
    }
    return self;
}

-(BOOL)isVideoCallUI{
    return !(_localVideoView.hidden&&_remoteVideoView.hidden);
}

-(void)showCameraBkView{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _initLocalVideoView];
        [self _getLocalMediaWithAudio:NO];
        [self.view sendSubviewToBack:_localVideoView];
    });
    
//    _factory = [RTCPeerConnectionFactory new];
//    [self _locaVideoGetForFront:YES];
}


-(void)_setButton:(UIButton*)button nomalImgName:(NSString*)name1 seletedImgName:(NSString*)name2{
    [button setImage:[UIImage imageNamed:name1] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:name2] forState:UIControlStateSelected];
}


-(void)_tipHide{
    [UIView animateWithDuration:0.3 animations:^{
        _tipLable.hidden = YES;
    }];
}

-(void)_tipShow:(NSString*)pTip{
    _tipLable.text  =   pTip;
    _tipLable.hidden = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_tipHide) object:nil];
    [self performSelector:@selector(_tipHide) withObject:nil afterDelay:3];
}

-(void)_changeUI_forFirst:(BOOL)bFirst{
    
    BOOL bForVideoCall = self.isVideoCallUI;
    
    _audio_bk_imageView.hidden =
    _audio_user_icon.hidden =
    _audio_user_Name.hidden =
    _center_Button.hidden = bForVideoCall;
    
//    _videoChangeCamera_Button.hidden = _localVideoView.hidden;

    if(!bFirst){
        [self _setIsHandFreeMode:(bForVideoCall?YES:_right_Button.selected)];
    }

    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:!bForVideoCall];
    
    CGFloat fButtonHY = 0;
//    UIButton* pLeftRight_H_top_equalTo = _center_Button;
    
    if(bForVideoCall){
        fButtonHY  =    _decline_Button.frame.origin.y;
        //视频
        [self _setButton:_right_Button nomalImgName:@"VoipVideoOff" seletedImgName:@"VoipVideoOn"];
        _right_Button.enabled   =   YES;
        _right_Button.selected  =   _localVideoView.hidden;
        
        //处理视频状态
        if(_remoteVideoView.hidden||0==_remoteVideoViewSize.width){
            //没有远程视频或远程视频宽度为0
            [self _videoView:_localVideoView showFullScreen:YES];
        }
        else{
            [self _fullScreenRemoteView:YES];
        }
        [self _setIsHandFreeMode:YES];
    }
    else{
        [self _hideButtonsSetAuto:NO];
        [self _hideButtons:NO];
        fButtonHY  =    _center_Button.frame.origin.y;
        [self _setButton:_right_Button nomalImgName:@"VoipSpeakerOn" seletedImgName:@"VoipSpeakerOff"];
        _right_Button.enabled   =   ![ACUtility isHeadsetPluggedIn];
        _right_Button.selected  =   _isHandFreeModeForAudio;
        [self _setIsHandFreeMode:_isHandFreeModeForAudio];
    }
    

    [_left_Button setFrame_y:fButtonHY];
    [_right_Button setFrame_y:fButtonHY];
    
//    [@[_left_Button,_right_Button] mas_updateConstraints:^(MASConstraintMaker *make) {
//        make.top.mas_equalTo(fButtonHY);
//    }];
//    
    [_videoCallVC setNeedsStatusBarAppearanceUpdate]; //检查状态条
    
    if(!bForVideoCall){
        //音频模式下，检查竖屏
        [self _orientationScreen];
    }
}

#define showTipDealyTime    2.5 //显示提示延时，然后关闭

-(void)_stopWithTip:(NSString*)pTip{
    
    if(nil==_webRTC_Config){
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _stop];
        [ACVideoCallVC hide];
        
        [ACUtility showTip:0==pTip.length?NSLocalizedString(@"Check_Network", nil):pTip
                     dalay:showTipDealyTime];
    });
    
    //    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)forceTerminate_Talk{
    //在调用这个之前，已经清除了ACVideoCall
    [self _stop];
    //    [self dismissViewControllerAnimated:animated completion:nil];
}


-(void)_hideButtons:(BOOL)bHide{
    _left_Button.hidden =   bHide;
    _right_Button.hidden = bHide;
    _decline_Button.hidden = bHide;
    _minButton.hidden = bHide;

    _videoChangeCamera_Button.hidden = _localVideoView.hidden||bHide;
    
    //    _right_Lable.hidden = bHide;
    //    _left_Lable.hidden = bHide;
    //    _center_Lable.hidden =  bHide;
    //    _time_Lable.hidden =    bHide;
    
}

//-(void)_timeStickFunc{
//    int nDif = (int)([NSDate timeIntervalSinceReferenceDate]-_nTimeBegin);
//    _time_Lable.text = [NSString stringWithFormat:@"%d:%02d",nDif/60,nDif%60];
//}

-(void)_initLocalVideoView{
    if(nil==_localVideoView){
        _localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
//        _localVideoView.backgroundColor  = [UIColor redColor];
        _localVideoView.delegate = self;
        _localVideoView.tag = 1;
//        _localVideoView.translatesAutoresizingMaskIntoConstraints = YES;
        [self.view addSubview:_localVideoView];
    }
}
-(UIView*)minTipBkView{
    if(nil==_minTipBkView){
        _minTipBkView   =   [[UIView alloc] init];
        _minTipBkView.backgroundColor   =   [UIColor whiteColor];
        [self.view addSubview:_minTipBkView];
        
        [_minTipBkView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(10);
            make.right.equalTo(self.view.mas_right).offset(-10);
            make.centerY.equalTo(self.view);
        }];
        
        
        UILabel*    pLable  =   [ACUtility lableCenterWithColor:[UIColor blackColor]
                                                       fontSize:14
                                                        andText:NSLocalizedString(@"Speaker will start working after minimized",nil)];
        [_minTipBkView addSubview:pLable];
        [pLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(5);
            make.right.equalTo(_minTipBkView.mas_right).offset(-5);
            make.top.mas_equalTo(10);
        }];
        
        UIView* pLine = [[UIView alloc] init];
        pLine.backgroundColor = [UIColor grayColor];
        [_minTipBkView addSubview:pLine];
        [pLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(_minTipBkView);
            make.height.mas_equalTo(1);
            make.left.mas_equalTo(0);
            make.top.equalTo(pLable.mas_bottom).offset(10);
        }];
        
        UIButton* pButton = [ACUtility buttonWithTarget:self
                                                 action:@selector(_onMinOk:)
                                          withTextOrImg:NSLocalizedString(@"OK",nil)];
//        pButton.backgroundColor = [UIColor redColor];
        [pButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_minTipBkView addSubview:pButton];
        
        [pButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(10);
            make.right.equalTo(_minTipBkView.mas_right).offset(-10);
            make.top.equalTo(pLine).offset(5);
            make.height.mas_equalTo(30);
        }];
        
        [_minTipBkView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(pButton.mas_bottom).offset(5);
        }];
        
        [_minTipBkView setRectRound:5];
    }
    return _minTipBkView;
}

#define BUTTON_BK_VIEW_Bottom_Offset    -40

-(void)_initButtons{
    
    for(UIView* pView in _videoCallVC.needRemoveViewsBeforTalk){
        [pView removeFromSuperview];
    }
    _videoCallVC.needRemoveViewsBeforTalk = nil;
    
    _videoChangeCamera_Button   =   [ACUtility buttonWithTarget:self
                                                         action:@selector(_video_ChangeCamera:)
                                                        withImg:@"voip_camera_icons"];
    [self.view addSubview:_videoChangeCamera_Button];
    [_videoChangeCamera_Button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.with.height.mas_equalTo(60);
        make.left.mas_equalTo(8);
        make.top.mas_equalTo(20);
    }];
    
    _button_bk_view =   [[UIView alloc] init];
    _button_bk_view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_button_bk_view];
    [_button_bk_view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(320);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(157);
        make.bottom.equalTo(self.view.mas_bottom).offset(BUTTON_BK_VIEW_Bottom_Offset);
    }];
    _left_Button    =   [ACUtility buttonWithTarget:self
                                             action:@selector(_onLeftButton:)
                                            withImg:@"VoipVoiceBanOn"];
    [_left_Button setImage:[UIImage imageNamed:@"VoipVoiceBanOff"] forState:UIControlStateSelected];
    [_button_bk_view addSubview:_left_Button];
    
    _right_Button  =   [ACUtility buttonWithTarget:self
                                            action:@selector(_onRightButton:)
                                           withImg:@"VoipSpeakerOn"];
    [_button_bk_view addSubview:_right_Button];
    
    _center_Button  =   [ACUtility buttonWithTarget:self
                                             action:@selector(_onCenterButton:)
                                            withImg:@"VoipVideoOn"];
    [_button_bk_view addSubview:_center_Button];
    

    _decline_Button  =   [ACUtility buttonWithTarget:self
                                             action:@selector(_onDeclineButton:)
                                             withImg:@"videocall_no"];
    [_button_bk_view addSubview:_decline_Button];
 
    
    _button_bk_view.autoresizesSubviews =   NO;
    
    CGRect rect = CGRectMake(0, 0, 60, 60);
    
    rect.origin.x   =   130;    rect.origin.y   =   2;
    _center_Button.frame    =   rect;
    rect.origin.y   =   95;
    _decline_Button.frame   =   rect;
    
    rect.origin.x   =   30;
    _left_Button.frame  =   rect;
    rect.origin.x   =   230;
    _right_Button.frame =   rect;
    
    
    
    /*
    [@[_left_Button,_decline_Button,_right_Button] mas_distributeViewsAlongAxis:MASAxisTypeHorizontal
                                                            withFixedItemLength:60
                                                                    leadSpacing:40
                                                                    tailSpacing:40];

    
    [_center_Button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.width.and.height.mas_equalTo(60);
        make.left.equalTo(_decline_Button);
    }];
    
    [_decline_Button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(60);
        make.top.mas_equalTo(65);
    }];

    
    [@[_left_Button,_right_Button] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(60);
        make.top.mas_equalTo(65);
    }];
    */
    

    


    
    
    _tipLable.textAlignment = NSTextAlignmentCenter;
    _tipLable.font  =   [UIFont systemFontOfSize:18];
    _tipLable.hidden=   YES;
    [_tipLable mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.centerY.equalTo(self.view);
        make.width.equalTo(self.view);
    }];
    
    _audio_user_Name.textAlignment = NSTextAlignmentCenter;
    _audio_user_Name.font  =   [UIFont systemFontOfSize:20];
    [_audio_user_Name mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.and.trailing.mas_equalTo(8);
        make.top.equalTo(_audio_user_icon.mas_bottom).offset(10);
    }];
    
    _minButton  =   [ACUtility buttonWithTarget:self
                                         action:@selector(onMin:)
                                        withImg:@"voip_miz_icons"];
    [self.view addSubview:_minButton];
    [_minButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(44);
        make.height.mas_equalTo(30);
        make.centerY.equalTo(_videoChangeCamera_Button);
        make.right.equalTo(self.view);
    }];
    
    _minAudioView   =   [UIView new];
    _minAudioView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_minAudioView];
    [_minAudioView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.width.mas_equalTo(AUDIO_MIN_SIZE_W);
//        make.height.mas_equalTo(AUDIO_MIN_SIZE_H);
        make.width.equalTo(self.view);
        make.height.equalTo(self.view);
        make.top.mas_equalTo(0);
        make.left.mas_equalTo(0);
    }];
    
    _minAudioFlagImag   =   [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Voip_Minisize_Window_Icon"]];
    [_minAudioView addSubview:_minAudioFlagImag];
    [_minAudioFlagImag mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.and.height.mas_equalTo(24);
        make.centerX.equalTo(_minAudioView);
        make.top.mas_equalTo(5);
    }];
    
    _minAudioTimeLabel  =   [ACUtility lableCenterWithColor:[UIColor greenColor] fontSize:12 andText:@""];
    [_minAudioView addSubview:_minAudioTimeLabel];
    [_minAudioTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(_minAudioView);
        make.left.mas_equalTo(0);
        make.top.equalTo(_minAudioFlagImag.mas_bottom).offset(5);
    }];
}

//-(void)testFunc{
////    self.minTipBkView.hidden = NO;
//    [self _initButtons];
//    _minAudioView.hidden = YES;
//}

- (void)showTalk {
    
    //清除前面的状态
    [_videoCallVC caller_answer_clearSatat];
    
    _videoCallVC.nStat  =   ACVideoCallVCStatTalk;
    
    _webRTC_Config      =   _videoCallVC.webRTC_Config;
    _room               =   _webRTC_Config[@"SessionID"];
    
//    ITLogEX(@"%@",_webRTC_Config);
    
    [self _initButtons];

    
    _remoteViewFullScreen   =   YES;
    [self _initLocalVideoView];
    
    _remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
    _remoteVideoView.delegate = self;
    [self.view addSubview:_remoteVideoView];
    
    [self.view sendSubviewToBack:_localVideoView];
    [self.view sendSubviewToBack:_remoteVideoView];
    [self.view sendSubviewToBack:_audio_bk_imageView];
    
    [self.view bringSubviewToFront:_tipLable];
    
    [_remoteVideoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_videoViewTouch:)]];
    
    [_localVideoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_videoViewTouch:)]];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_videoBkViewTouch)]];
    
    [_minAudioView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onMax:)]];
    _minAudioView.hidden = YES;
//    [_audio_user_icon setToCircle];
    
#ifdef ACUtility_Need_Log
    if(nil==_webRTC_Config){
        _minButton.hidden = NO;
        [self _changeUI_forFirst:YES];
        return;
    }
#endif
    
    {
        //        CGRect frame = _left_Button.frame;
        //        [_left_Button removeFromSuperview];
        //        [_button_bk_view addSubview:_left_Button];
//        _left_Button.translatesAutoresizingMaskIntoConstraints = YES; //禁止使用AutoLayout布局
        
        //        [_right_Button removeFromSuperview];
        //        [_button_bk_view addSubview:_right_Button];
//        _right_Button.translatesAutoresizingMaskIntoConstraints = YES; //禁止使用AutoLayout布局
        
    }
    
//    [self _changeUI2VideoCall:0==[_webRTC_Config[@"CallType"] integerValue]];
    _localVideoView.hidden = _remoteVideoView.hidden = !(_videoCallVC.bForVideoCall);
    [self _getLocalMediaWithAudio:YES];
//    [self _changeUI_forFirst:YES];
    [self _HeadsetChanged]; //处理耳机
    
//    _audio_user_Name.text = _caller.name;
//    [ACNoteListVC_Cell setUserIcon:_caller forImageView:_audio_user_icon];
    
    [self _hideButtons:YES];
    _center_Button.hidden = YES;
    _videoChangeCamera_Button.hidden = YES;
    _decline_Button.hidden =  NO;
    //    _center_Lable.text      =   NSLocalizedString(@"VideoCall_Decline", nil);
    
    
    //应该在这里检查摄像头，麦克风权限，然后再调用下面的代码
    
    
    //连接上服务器，等待信号
    [self.view showProgressHUD];
    NSURL* url = [[NSURL alloc] initWithString:_webRTC_Config[@"server"]];
    _webSocket =    [[SRWebSocket alloc] initWithURL:url];
    _webSocket.delegate =   self;
    [_webSocket open];

    
    [UIApplication sharedApplication].idleTimerDisabled=YES;
    
    
    [self.view setNeedsUpdateConstraints];
    // 调用此方法告诉self.view检测是否需要更新约束，若需要则更新，下面添加动画效果才起作用
    [self.view updateConstraintsIfNeeded];
}

-(void)viewDidDisappear__Call{
    
    [self _orientationScreen];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [UIApplication sharedApplication].idleTimerDisabled=NO;
    [self _sendCancelStat];
//    [ACVideoCallVC hide];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    
    [_timerForMin invalidate];
    _timerForMin = nil;
}


-(UIInterfaceOrientationMask)supportedInterfaceOrientations_Call
{
    if((!_minAudioView.hidden)||
       (!self.isVideoCallUI)){
        return UIInterfaceOrientationMaskPortrait;
    }
    
#ifdef ACUtility_Need_Log
    if(nil==_webRTC_Config){
        return UIInterfaceOrientationMaskAll;
    }
#endif
    return _remoteMediaStream?UIInterfaceOrientationMaskAll:UIInterfaceOrientationMaskPortrait;
    
//    return _remoteVideoView.hidden?UIInterfaceOrientationMaskPortrait:UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden_Call{
    if(!_minAudioView.hidden){
        return NO;
    }
    return self.isVideoCallUI;
}

-(void)viewWillLayoutSubviews_Call{

    //    ITLogEX(@"%@",NSStringFromCGSize(self.view.size));
    if(_fviewWidth!=self.view.size.width){
        _fviewWidth =   self.view.size.width;

        //处理按钮和图标等的关系
        if(!self.isMinimized){
            BOOL bIsPortrait    =   self.view.size.width<self.view.size.height;
            
            [_audio_user_icon mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(bIsPortrait?@USER_ICON_IMAGE_DEFAULT_TOP:@8);
            }];
            
            [_button_bk_view mas_updateConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.view.mas_bottom).offset(bIsPortrait?BUTTON_BK_VIEW_Bottom_Offset:-8);
            }];
        }
        
        if(self.isVideoCallUI){
            if(_remoteVideoView.hidden||0==_remoteVideoViewSize.width){
                [self _videoView:_localVideoView showFullScreen:YES];
            }
            else{
                [self _fullScreenRemoteView:YES];
            }
 
            if(!_minAudioView.hidden){
                [self.view bringSubviewToFront:_minAudioView];
            }
        }
    }
}




-(CGSize)_getViewMinSize:(CGSize)theSrcSize winMinWidth:(int)video_view_min_width{
    if(theSrcSize.width>theSrcSize.height){
        theSrcSize.width   =   theSrcSize.width * (video_view_min_width/theSrcSize.height);
        theSrcSize.height    =   video_view_min_width;
    }
    else{
        theSrcSize.height   =   theSrcSize.height * (video_view_min_width/theSrcSize.width);
        theSrcSize.width    =   video_view_min_width;
    }
    return theSrcSize;
}

#define video_view_min_width_default    70.0

-(void)_videoView:(RTCEAGLVideoView*)videoView showFullScreen:(BOOL)bFullScreen{
    CGSize theSrcSize = videoView==_localVideoView?_localVideoViewSize:_remoteVideoViewSize;
    if(0==theSrcSize.width){
        ITLog(@"还没有取得视频宽高");
        return;
    }
    
    CGSize viewSize = self.view.size;
    
    if(bFullScreen){
        //按长宽比走
        CGRect frame;
        if((theSrcSize.width/theSrcSize.height)>(viewSize.width/viewSize.height)){
            frame.size.height	=	viewSize.width*(theSrcSize.height/theSrcSize.width);
            frame.size.width	=	viewSize.width;
            frame.origin.x      =   0;
            frame.origin.y      =   (viewSize.height-frame.size.height)/2;
        }
        else{
            frame.size.width	=	viewSize.height*(theSrcSize.width/theSrcSize.height);
            frame.size.height	=	viewSize.height;
            frame.origin.x      =   (viewSize.width-frame.size.width)/2;;
            frame.origin.y      =   0;
        }
        videoView.frame =   frame;
    }
    else{
#ifdef Local_View_Min_Size_W
        int video_view_min_width =  self.isMinimized?Local_View_Min_Size_W:video_view_min_width_default;
#else
        int video_view_min_width =  video_view_min_width_default;
#endif
        theSrcSize      =   [self _getViewMinSize:theSrcSize winMinWidth:video_view_min_width];
        videoView.frame =   CGRectMake(viewSize.width-theSrcSize.width,0,theSrcSize.width,theSrcSize.height);
    }
}

-(void)_fullScreenRemoteView:(BOOL)bRemoteView{
    
    _remoteViewFullScreen   =   bRemoteView;
    
    RTCEAGLVideoView* pFullView = nil;
    RTCEAGLVideoView* pNotFullView = nil;
    if(bRemoteView){
        pFullView   =   _remoteVideoView;
        pNotFullView=   _localVideoView;
    }
    else{
        pFullView   =   _localVideoView;
        pNotFullView=   _remoteVideoView;
    }
    
    [self.view sendSubviewToBack:pNotFullView];
    [self.view sendSubviewToBack:pFullView];
    
//    [UIView animateWithDuration:5 animations:^{
    [self _videoView:pFullView showFullScreen:YES];
    [self _videoView:pNotFullView showFullScreen:NO];
//    } completion:^(BOOL finished) {
//        
//    }];

}

#pragma mark Action
- (void)_video_ChangeCamera:(id)sender {
    //改变摄像头
    [self _locaVideoSetDevice:!_localVideoIsFront];
}

-(void)_orientationScreen{
    if(!(UIDeviceOrientationPortrait==[UIDevice currentDevice].orientation||
       UIDeviceOrientationPortraitUpsideDown==[UIDevice currentDevice].orientation)){
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
    }
}

- (void)onMin:(id)sender{
    _beforeMinimized_LocalVideoHidded   =   _localVideoView.hidden;
    self.minTipBkView.hidden = NO;
    [self _orientationScreen];
}

-(void)_audioMinShowTime{
    NSInteger nTime = time(NULL)-_beingTimeSeconds;
    _minAudioTimeLabel.text =   [NSString stringWithFormat:@"%02d:%02d",(int)((nTime/60)%60),(int)(nTime%60)];
}

- (void)_onMinOk:(id)sender {
    _isMinimized    =   YES;
    
    self.minTipBkView.hidden = YES;
    
    _minButton.hidden = YES;
    _minAudioView.hidden = NO;
    
    _button_bk_view.hidden = YES;
    _videoChangeCamera_Button.hidden = YES;
    _tipLable.hidden = YES;

#ifndef Local_View_Min_Size_W
    _localVideoView.hidden = YES;
#endif
    
    [self _hideButtons:YES];
    
    if(_remoteVideoView.hidden){
        
        _minAudioView.backgroundColor = [UIColor whiteColor];
        _minAudioFlagImag.hidden = NO;
        _minAudioTimeLabel.hidden = NO;
        
        _audio_user_icon.hidden = YES;
        _audio_user_Name.hidden = YES;
        _audio_bk_imageView.hidden = YES;
        [self _audioMinShowTime];
        _timerForMin    =   [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_audioMinShowTime) userInfo:nil repeats:YES];
        
        [ACVideoCallVC showMinWithSize:CGSizeMake(AUDIO_MIN_SIZE_W, AUDIO_MIN_SIZE_H)];
    }
    else{
        _minAudioView.backgroundColor = [UIColor clearColor];
        _minAudioFlagImag.hidden = YES;
        _minAudioTimeLabel.hidden = YES;
        
        [self _fullScreenRemoteView:YES];
        [ACVideoCallVC showMinWithSize:[self _getViewMinSize:_remoteVideoViewSize winMinWidth:video_view_min_width_default]];
    }
    [self _setIsHandFreeMode:YES];
    [self.view bringSubviewToFront:_minAudioView];
}

- (void)onMax:(id)sender {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    _isMinimized    =   NO;
    _minAudioView.hidden = YES;
    
    [_timerForMin invalidate];
    _timerForMin = nil;
    
    _button_bk_view.hidden = NO;
    _localVideoView.hidden =    _beforeMinimized_LocalVideoHidded;
    [ACVideoCallVC showMax];
    [self _changeUI_forFirst:NO];
    if(self.isVideoCallUI){
        [self _hideButtons:YES];
    }
}

- (IBAction)_onLeftButton:(id)sender {
    
    [UIView animateWithDuration:0.5 animations:^{
        if(self.isVideoCallUI){
            [self _hideButtonsSetAuto:NO];
            [self _hideButtons:YES];
        }
        //开关麦克
        _left_Button.selected = !_left_Button.selected;
    } completion:^(BOOL finished) {
        [self _setAudioTrack:!_left_Button.selected];
        NSString* pStat = _left_Button.selected?@"audioOff":@"audioOn";
        [self _sendEvent:@"__notice" withData:@{@"device":pStat,@"socketId":_socktID_others[0]}];
    }];
}


-(void)_sendVideoOnOffEvent:(BOOL)bOn{
    NSString* pStat = bOn?@"videoOn":@"videoOff";
    [self _sendEvent:@"__notice" withData:@{@"device":pStat,@"socketId":_socktID_others[0]}];
}

- (IBAction)_onCenterButton:(id)sender{
    //切换为视频
    [self _locaVideoSetDevice:YES];

    [UIView animateWithDuration:0.5 animations:^{
        _localVideoView.hidden = NO;
        [self _changeUI_forFirst:NO];
    } completion:^(BOOL finished) {
        [self _sendVideoOnOffEvent:YES];
    }];
}

- (IBAction)_onRightButton:(id)sender {
    if(self.isVideoCallUI){
        
        [UIView animateWithDuration:0.5 animations:^{
            _localVideoView.hidden = !_localVideoView.hidden;
            [self _locaVideoEnable:!_localVideoView.hidden];
            [self _changeUI_forFirst:NO];
            
            [self _hideButtonsSetAuto:NO];
            if(self.isVideoCallUI){
                [self _hideButtons:YES];
            }
         }completion:^(BOOL finished) {
            [self _sendVideoOnOffEvent:!_localVideoView.hidden];
        }];
    }
    else{
        //Audio
        //外放
        _isHandFreeModeForAudio = _right_Button.selected = !_right_Button.selected;
        [self _setIsHandFreeMode:_isHandFreeModeForAudio];
    }
}

- (IBAction)_onDeclineButton:(id)sender {
    //挂机
    [self forceTerminate_Talk];
}

-(void)_videoDelayHideButton{
    [self _hideButtons:YES];
}

-(void)_hideButtonsSetAuto:(BOOL)bSet{
    if(bSet){
        [self performSelector:@selector(_videoDelayHideButton) withObject:nil afterDelay:5];
    }
    else{
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(_videoDelayHideButton)
                                                   object:nil];
    }
}

-(void)_videoBkViewTouch{
    ITLogEX(@"%@",NSStringFromCGRect(self.view.frame));
    [self _hideButtonsSetAuto:NO];
    if(self.isVideoCallUI){
        if(_decline_Button.hidden){
            [self _hideButtonsSetAuto:YES];
            [self _hideButtons:NO];
        }
        else{
            [self _hideButtons:YES];
        }
    }
}

-(void)_videoViewTouch:(UITapGestureRecognizer*)pTap{
    
    UIView* videoView =     pTap.view;
    UIView* pFullVIew =     _remoteViewFullScreen?_remoteVideoView:_localVideoView;
    if(pFullVIew==videoView){
        //Full
        [self _videoBkViewTouch];
        return;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        [self _fullScreenRemoteView:!_remoteViewFullScreen];
    }];
}

#if 0
-(int)_getScreenOrientation{
    int degree = -1;
    
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationFaceUp:
            NSLog(@"屏幕朝上平躺,FaceUp");
            break;
            
        case UIDeviceOrientationFaceDown:
            NSLog(@"屏幕朝下平躺,FaceDown");
            break;
            
            //系統無法判斷目前Device的方向，有可能是斜置
        case UIDeviceOrientationUnknown:
            NSLog(@"未知方向,Unknown");
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"屏幕向左横置,LandscapeLeft");
            degree  =   90;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            degree  =   270;
            NSLog(@"屏幕向右橫置,LandscapeRight");
            break;
            
        case UIDeviceOrientationPortrait:
            NSLog(@"屏幕直立,Portrait");
            degree  =   0;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"屏幕直立，上下顛倒,PortraitUpsideDown");
            degree  =   180;
            break;
            
        default:
            NSLog(@"无法辨识");
            break;
    }
    return degree;
}

- (void)_orientChange:(NSNotification *)noti{
    
    int lcalDeg = [self _getScreenOrientation];
    if(lcalDeg<0){
        return;
    }
    /*int degree  =   ( 360 - ((lcalDeg + _remoteScreenOrientation) % 360) ) % 360;
     ITLogEX(@"%d",degree);
     
     
     if(0==degree){
     //恢复状态
     _remoteVideoView.transform  =   CGAffineTransformIdentity;
     return;
     }
     
     if(180==degree){
     //上下颠倒
     _remoteVideoView.transform  =   _localVideoView.transform = CGAffineTransformMakeScale(1.0, -1.0);
     return;
     }
     
     /*
     if(90==degree||270==degree){
     //先缩放
     CGFloat fSx =   _remoteVideoViewSize.width/_remoteVideoViewSize.height;
     //        CGFloat fAngle  = M_PI_4*(degree/360.0);
     _remoteVideoView.transform  =   CGAffineTransformMakeScale(fSx,fSx);
     _remoteVideoView.transform  =   CGAffineTransformRotate(_remoteVideoView.transform, 90==degree?(M_PI/4):(M_PI*3/4));
     }*/
    
    //    if(_localVideoIsFront){
    //        _localVideoView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    //    }
    //    else{
    //        _localVideoView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    //    }
    
    
    //renderDeg =
    
    //    NSDictionary* ntfDict = [noti userInfo];
    
    //    UIDeviceOrientation  orient = [UIDevice currentDevice].orientation;
    
    
    //     UIDeviceOrientationUnknown,
    //     UIDeviceOrientationPortrait,            // Device oriented vertically, home button on the bottom
    //     UIDeviceOrientationPortraitUpsideDown,  // Device oriented vertically, home button on the top
    //     UIDeviceOrientationLandscapeLeft,       // Device oriented horizontally, home button on the right
    //     UIDeviceOrientationLandscapeRight,      // Device oriented horizontally, home button on the left
    //     UIDeviceOrientationFaceUp,              // Device oriented flat, face up
    //     UIDeviceOrientationFaceDown             // Device oriented flat, face down
    
    //    {
    //        "eventName": "__notice",
    //        "data": {
    //            "degree": 0|90|180|270,
    //            "socketId": socket.id
    //        }
    //    }
    
    //    if(degree>=0){
    //        [self _sendEvent:@"__notice" withData:@{@"degree":@(degree),@"socketId": _socktID_others[0]}];
    //    }
}
#endif

@end


/*
 20160927:
 
 一、sinal server (web socket) 的断连重连机制。
 
	config 增加三个字段。
 
	config{
 retryWait: 1000    //断连后，等待的时间。毫秒
 signalMaxRetry: 5  //最大重试次数。
 httpMaxRetry: 5， http 相关API，最大重试次数
	}
 
	websocket.onopen= function(){
 建连成功
	}
 
	websocket.onclose = function(){
 连接关闭
	}
 
	a. onopen后
 
 如果p2p未建连成功过，
 根椐config.timeout字段，做建连超时的倒计时。
 
 
	b. onclose后，
 
 如果sinal server未建立成功过。
 wait retryWait秒，重新建连，reconnectTime++;
 reconnectTime 大于 signalMaxRetry， 结束通话，发cancel?t=0;
 
 
 如果 p2p 已成建连成功过。
 
 wait retryWait秒，重新建连.
 
 socket.send(JSON.stringify({
 "eventName": "__join",
 "data": {
 "room": room，
 "socketId": 自己的socketId，
 }
 }));
 
	
 
 
 二、 remote camera 旋转，
 
	手机旋转到90， 180， 270， 0度的时候，
 
	1. 把自己当前的方向（度数）告诉对方
 
 {
 "eventName": "__notice",
 "data": {
 "degree": 0|90|180|270,
 "socketId": socket.id
 }
 }
 
	2. 旋转远程video, 至，头上脚下
 */

