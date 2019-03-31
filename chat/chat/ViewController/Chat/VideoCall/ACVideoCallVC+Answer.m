//
//  ACVideoCallVC.m
//  chat
//
//  Created by Aculearn on 16/11/28.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACVideoCallVC+Answer.h"
#import "ACVideoCall.h"
#import "ACEntity.h"
#import "ACEntityEvent.h"
#import "ACNetCenter.h"
#import "ACVideoCallVC.h"


#if DEBUG
//    #define ACVideoCall_View_Delay_Time 5
#endif

#ifndef ACVideoCall_View_Delay_Time
    #define ACVideoCall_View_Delay_Time  60
#endif
@implementation ACVideoCallVC(Answer)

-(void)setViewForAnswer{
    
    UIButton* pDeButton = [ACUtility buttonWithTarget:self action:@selector(onDecline:) withTextOrImg:[UIImage imageNamed:@"videocall_no"]];
    [self.view addSubview:pDeButton];
    
    UILabel* pDeLable = [ACUtility lableCenterWithColor:[UIColor whiteColor] fontSize:17 andText:NSLocalizedString(@"VideoCall_Decline", nil)];
    [self.view addSubview:pDeLable];
    [pDeLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(pDeButton.mas_bottom).offset(8);
        make.centerX.equalTo(pDeButton);
    }];
    
    UIButton* pOkButton = [ACUtility buttonWithTarget:self action:@selector(onAnswer:) withTextOrImg:[UIImage imageNamed:@"videocall_yes"]];
    [self.view addSubview:pOkButton];
    
    UILabel* pOkLable = [ACUtility lableCenterWithColor:[UIColor whiteColor] fontSize:17 andText:NSLocalizedString(@"VideoCall_Answer", nil)];
    [self.view addSubview:pOkLable];
    [pOkLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(pOkButton.mas_bottom).offset(8);
        make.centerX.equalTo(pOkButton);
    }];
    
    NSArray* pButtons = @[pDeButton,pOkButton];
    [pButtons mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedItemLength:60 leadSpacing:60 tailSpacing:60];
    [pButtons mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.with.width.mas_equalTo(60);
        make.bottom.equalTo(self.view.mas_bottom).offset(-80);
    }];
    
    self.nAnswer_RejectType            =   REJECTREASON_BUSY; //REJECTREASON_BUSYTIMEOUT;
    
    if(self.videoCallTopic.isSigleChat){
        self.answerCallerTipLable.text =     self.bForVideoCall?NSLocalizedString(@"VideoCall_Video_Incoming",nil):
        NSLocalizedString(@"VideoCall_Incoming",nil);
    }
    else{
        self.answerCallerTipLable.text =   self.bForVideoCall?NSLocalizedString(@"VideoCall_Group_Video_Incoming",nil):
        NSLocalizedString(@"VideoCall_Group_Incoming",nil);
    }
    
    self.needRemoveViewsBeforTalk = @[pDeButton,pDeLable,pOkLable,pOkButton];
    
    [self caller_answer_setOutTime:self.nAnswer_ExpireTime<10?ACVideoCall_View_Delay_Time:self.nAnswer_ExpireTime withSelector:@selector(_outTime_Answer)];

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onWebRTC_Notifition_for_Answer:)
                                                 name:kNetCenterWebRTC_Notifition
                                               object:nil];

}


-(void)onWebRTC_Notifition_for_Answer:(NSNotification*)notify{
    NSDictionary* eventDict = notify.object;
    //atype=0:  "atype" : 1, //ANSWERTYPE_REJECTED = 0; ANSWERTYPE_ANSWERED = 1;
    if(EntityEventType_WEBRTC_Answered==[eventDict[kNetCenterWebRTC_Notifition_type] integerValue]){
        self.nAnswer_RejectType = REJECTREASON_ALREADY;
        [self slideOutFunc:YES];
        
        NSString* pTip = [eventDict[kNetCenterWebRTC_Notifition_info][@"atype"] intValue]?
        NSLocalizedString(@"Answered on other device", nil):NSLocalizedString(@"VideoCall_Cancel", nil);
        
        [ACUtility showTip:pTip];
    }
}


-(void)slideOutFunc:(BOOL)animated{

    [self caller_answer_clearSatat];
    [[ACVideoCall shareVideoCall] onUser:self.caller Accept:self.nAnswer_RejectType];
    
    if(REJECTREASON_UserAccept!=self.nAnswer_RejectType){
        self.talkInfo = nil;
        [ACVideoCallVC hide];
    }
}

-(void)forceTerminate_Answer{
    //    [self onDecline:nil];
    
    self.nAnswer_RejectType = REJECTREASON_BUSY;
    [self slideOutFunc:NO];
    
    //    [self dismissViewControllerAnimated:NO completion:completion];
}

-(void)_outTime_Answer{
    [self onDecline:nil];
}


#pragma mark -- Active

- (void)onDecline:(id)sender {
    self.nAnswer_RejectType = REJECTREASON_BUSY;
    [self slideOutFunc:YES];
}


- (void)onAnswer:(UIButton*)sender {
    self.nAnswer_RejectType = REJECTREASON_UserAccept;
    [self.view showProgressHUD];
    [self slideOutFunc:NO];
}


@end
