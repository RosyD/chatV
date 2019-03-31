//
//  ACVideoCallVC.m
//  chat
//
//  Created by Aculearn on 16/11/28.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACVideoCallVC.h"
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAudioPlayer.h>
#import "JHNotificationManager.h"
#import "ACEntity.h"
#import "ACUser.h"
#import "ACNoteListVC_Cell.h"
#import "ACVideoCallVC+Answer.h"
#import "ACVideoCallVC+Caller.h"
#import "ACVideoCallVCTalkInfo.h"
#import "ACVideoCall.h"
#import "ACConfigs.h"


@interface UIVideoCallWindow : UIWindow{
    CGSize  _frameMaxSize;
}
@end


@implementation UIVideoCallWindow


AC_MEM_Dealloc_implementation


-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        _frameMaxSize   =   frame.size;
        UIPanGestureRecognizer * panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(doDragWnd:)];
        [self addGestureRecognizer:panGestureRecognizer];
    }
    return self;
}

- (void) doDragWnd:(UIPanGestureRecognizer *)paramSender{
    
    CGPoint point = [paramSender translationInView:self];
    NSLog(@"%@",paramSender);
    
    
    paramSender.view.center = CGPointMake(paramSender.view.center.x + point.x, paramSender.view.center.y + point.y);
    [paramSender setTranslation:CGPointMake(0, 0) inView:self];
    
    CGRect frame =  paramSender.view.frame;
    BOOL bNeedReset = NO;
    if(frame.origin.x<0){
        frame.origin.x = 0;
        bNeedReset = YES;
    }
    else if(CGRectGetMaxX(frame)>_frameMaxSize.width) {
        frame.origin.x = _frameMaxSize.width-frame.size.width;
        bNeedReset = YES;
    }
    if(frame.origin.y<0){
        frame.origin.y = 0;
        bNeedReset = YES;
    }
    else if(CGRectGetMaxY(frame)>_frameMaxSize.height) {
        frame.origin.y = _frameMaxSize.height-frame.size.height;
        bNeedReset = YES;
    }
    
    if(paramSender.state!=UIGestureRecognizerStateBegan&&
       paramSender.state!=UIGestureRecognizerStateChanged){
        //结束了，管他什么状态
        if((frame.origin.x+frame.size.width/2)>=_frameMaxSize.width/2){
            //停靠右边
            frame.origin.x = _frameMaxSize.width-frame.size.width;
        }
        else{
            frame.origin.x  =   0;
        }
        [UIView animateWithDuration:0.2 animations:^{
            paramSender.view.frame =    frame;
        }];
    }
    else if(bNeedReset){
        paramSender.view.frame =    frame;
    }
}


-(void)showMinWithSize:(CGSize)theSize{
    [UIView animateWithDuration:0.2 animations:^{
        self.frame   =   CGRectMake(_frameMaxSize.width-theSize.width,20,theSize.width,theSize.height);
    } completion:^(BOOL finished) {
        [self.rootViewController.view setNeedsLayout];
    }];
}

-(void)showMax{
    [UIView animateWithDuration:0.2 animations:^{
        self.frame   =   CGRectMake(0,0,_frameMaxSize.width,_frameMaxSize.height);
    } completion:^(BOOL finished) {
        [self.rootViewController.view setNeedsLayout];
    }];
}


@end

static UIVideoCallWindow* g__VideoCallWnd = nil;



@interface ACVideoCallVC (){
    AVAudioPlayer*         _soundPlayer;
    startConferenceBlock   _conferenceBlock;
}

@end

@implementation ACVideoCallVC


AC_MEM_Dealloc_implementation



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.view.backgroundColor = [UIColor blackColor];

    
    {
        _bkView =    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"voice_call_bg.jpg"]];
        [self.view addSubview:_bkView];
        
        [_bkView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(0);
            make.top.mas_equalTo(0);
            make.height.width.equalTo(self.view);
        }];
    }

    {
        _userIconImageView = [[UIImageView alloc] init];
        [self.view addSubview:_userIconImageView];
        [_userIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(100);
            make.centerX.equalTo(self.view);
            make.top.mas_equalTo(USER_ICON_IMAGE_DEFAULT_TOP);
        }];
        [_userIconImageView setRectRound:100/2];
    }

    {
        _userNameLable  =   [ACUtility lableCenterWithColor:[UIColor whiteColor] fontSize:20 andText:nil];
        [self.view addSubview:_userNameLable];

        [_userNameLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.and.trailing.mas_equalTo(8);
            make.top.equalTo(_userIconImageView.mas_bottom).offset(10);
        }];
    }
    
    {
        _answerCallerTipLable   =   [ACUtility lableCenterWithColor:[UIColor whiteColor] fontSize:18 andText:nil];
        [self.view addSubview:_answerCallerTipLable];

        [_answerCallerTipLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.and.trailing.mas_equalTo(8);
            make.top.equalTo(_userNameLable.mas_bottom).offset(8);
        }];
        
    }
    

    
    if(ACVideoCallVCStatAnswer==_nStat){
        [self setViewForAnswer];
    }
    else{
        [self setViewForCaller];
    }
    
    if(_bForVideoCall){
        _bkView.hidden = YES;
        _userIconImageView.hidden = YES;

        _userNameLable.textAlignment = NSTextAlignmentLeft;
        _userNameLable.font =   [UIFont systemFontOfSize:24];
        
        [_userNameLable mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(30);
        }];

        
        if(NO==_answerCallerTipLable.hidden){
            _answerCallerTipLable.textAlignment = NSTextAlignmentLeft;
            _answerCallerTipLable.font =   [UIFont systemFontOfSize:20];
        }
        [self.talkInfo showCameraBkView];
    }
    
    //关闭提示
    [JHNotificationManager hideNotificationView:NO];
    
    if(_videoCallTopic.isSigleChat){
        _userNameLable.text = _caller.name;
        [ACNoteListVC_Cell setUserIcon:_caller forImageView:_userIconImageView];
    }
    else{
        _userNameLable.text = _videoCallTopic.title;
        
        //组icon
        NSString* pIcon = _videoCallTopic.icon;
        
        if (pIcon){
            [_userIconImageView setImageWithIconString:pIcon
                                      placeholderImage:[UIImage imageNamed:@"icon_groupchat.png"]
                                             ImageType:ImageType_TopicEntity];
        }
        else{
            _userIconImageView.image = [UIImage imageNamed:@"icon_groupchat.png"];
        }
    }
    
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    //    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    _soundPlayer   =
    
    [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource: @"call" ofType: @"caf"]] error:nil];
    
    //    [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource: @"lineapp_ring_16k" ofType: @"wav"]] error:nil];
    
    [_soundPlayer prepareToPlay];
    [_soundPlayer setNumberOfLoops:INT_MAX];
    [_soundPlayer play];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    _needRemoveViewsBeforTalk = nil;
    
    if(_talkInfo){
        [_talkInfo viewDidDisappear__Call];
        _talkInfo   =   nil;
    }
    else{
        [self caller_answer_clearSatat];
    }
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    if(ACVideoCallVCStatTalk==_nStat){
        [_talkInfo viewWillLayoutSubviews_Call];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if(ACVideoCallVCStatTalk==_nStat){
        return [_talkInfo supportedInterfaceOrientations_Call];
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden{
    if(ACVideoCallVCStatTalk==_nStat){
        return [_talkInfo prefersStatusBarHidden_Call];
    }
    return NO;
}

-(void)_outTimerTest{
    [ACVideoCallVC hideFunc];
}

-(void)caller_answer_setOutTime:(int)expireTime withSelector:(SEL)aSelector{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:aSelector
               withObject:self
               afterDelay:expireTime];
}

-(void)caller_answer_clearSatat{
    if(_soundPlayer){
        [_soundPlayer stop];
        _soundPlayer = nil;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _nStat  =   ACVideoCallVCStatIDE;
}

-(ACVideoCallVC_TalkInfo*)talkInfo{
    if(nil==_talkInfo){
        _talkInfo   =   [[ACVideoCallVC_TalkInfo alloc] initWithCallVC:self];
        AC_MEM_Alloc(_talkInfo);
    }
    return _talkInfo;
}

-(void)forceTerminate{
    if(ACVideoCallVCStatAnswer==_nStat){
        [self forceTerminate_Answer];
    }
    else if(ACVideoCallVCStatCaller==_nStat){
        [self forceTerminate_Caller];
    }
    else if(ACVideoCallVCStatTalk==_nStat){
        [self.talkInfo forceTerminate_Talk];
    }
    _talkInfo = nil;
}

#pragma mark 全局函数

+(BOOL) isInVideoCall{
    return nil!=g__VideoCallWnd;
}

+(void)showForTopic:(ACTopicEntity*)topic withUser:(ACUser*)pUsr andExpireTime:(int)expireTime andCfg:(NSDictionary*)pCfg forVideoCall:(BOOL)bForVideoCall andBeginStat:(ACVideoCallVCStat)stat{
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    ACVideoCallVC* pVC =    [ACVideoCallVC new];
    AC_MEM_Alloc(pVC);
    pVC.videoCallTopic  =   topic;
    pVC.nAnswer_ExpireTime  =   expireTime;
    pVC.webRTC_Config   =   pCfg;
    pVC.caller          =   pUsr;
    pVC.bForVideoCall   =   bForVideoCall;
    pVC.nStat           =   stat;
    
    if(nil==g__VideoCallWnd){
        g__VideoCallWnd =   [[UIVideoCallWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        AC_MEM_Alloc(g__VideoCallWnd);
        g__VideoCallWnd.windowLevel  =   UIWindowLevelAlert+20;
    }
    g__VideoCallWnd.rootViewController = pVC;
    g__VideoCallWnd.hidden = NO;
    [g__VideoCallWnd makeKeyAndVisible];
    
    CGRect frame =  pVC.view.frame;
    frame.origin.y  =   frame.size.height;
    pVC.view.frame =  frame;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame2 =  pVC.view.frame;
        frame2.origin.y =   0;
        pVC.view.frame =  frame2;
    }];
}


+(void) showAnswerForTopic:(ACTopicEntity*)topic withUser:(ACUser*)pUsr andExpireTime:(int)expireTime andCfg:(NSDictionary*)pCfg forVideoCall:(BOOL)bForVideoCall{
    [self showForTopic:topic withUser:pUsr andExpireTime:expireTime andCfg:pCfg forVideoCall:bForVideoCall andBeginStat:ACVideoCallVCStatAnswer];
}
+(void) showCallerForTopic:(ACTopicEntity*)topic withUser:(ACUser*)pUsr forVideoCall:(BOOL)bForVideoCall{
    [self showForTopic:topic withUser:pUsr andExpireTime:0 andCfg:nil forVideoCall:bForVideoCall andBeginStat:ACVideoCallVCStatCaller];
}


+(void) showMinWithSize:(CGSize)theSize{
    [g__VideoCallWnd showMinWithSize:theSize];
}

+(void)showMax{
    [g__VideoCallWnd showMax];
}

+(void) forceTerminate{ //强行关闭
    if(nil==g__VideoCallWnd){
        return;
    }
    [(ACVideoCallVC*)g__VideoCallWnd.rootViewController forceTerminate];
    [self hide];
}

+(void) hideFunc{
    if(g__VideoCallWnd){
        g__VideoCallWnd.hidden = YES;
        g__VideoCallWnd.rootViewController = nil;
        g__VideoCallWnd = nil;
    }
}

+(void) hide{
    [self hideFunc];
    [[ACVideoCall shareVideoCall] clearVideoCallInfo];
}

+(void) startConferenceWithBlock:(startConferenceBlock) block{
    dispatch_async(dispatch_get_main_queue(),^{
        [self hideFunc];
        block([ACConfigs getTopViewController]);
    });
}

+(void) startWebRTC{
    //    NSAssert(g__VideoCallWnd,@"g__VideoCallWnd");
    [((ACVideoCallVC*)g__VideoCallWnd.rootViewController).talkInfo showTalk];
}


@end
