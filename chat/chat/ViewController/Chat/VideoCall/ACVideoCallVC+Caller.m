//
//  ACVideoCallVC.m
//  chat
//
//  Created by Aculearn on 16/11/28.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACVideoCallVC+Caller.h"
#import "ACNoteListVC_Cell.h"
#import "ACEntity.h"
#import "ACUser.h"
#import "ACNetCenter.h"
#import "ACVideoCall.h"
#import "ACEntityEvent.h"
#import "ACVideoCallVC.h"

@implementation ACVideoCallVC (Caller)

-(void)setViewForCaller{
    UIButton* pDeButton = [ACUtility buttonWithTarget:self action:@selector(onCancel_Caller:) withTextOrImg:[UIImage imageNamed:@"videocall_no"]];
    [self.view addSubview:pDeButton];
    [pDeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-80);
        make.height.with.width.mas_equalTo(60);
    }];
    
    
    UILabel* pDeLable = [ACUtility lableCenterWithColor:[UIColor whiteColor] fontSize:17 andText:NSLocalizedString(@"Cancel", nil)];
    [self.view addSubview:pDeLable];
    [pDeLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(pDeButton.mas_bottom).offset(8);
        make.centerX.equalTo(pDeButton);
    }];
    
    if(self.videoCallTopic.isSigleChat){
        self.userNameLable.text = [NSString stringWithFormat:NSLocalizedString(@"Waiting for %@",nil),self.caller.name];
    }
    
    self.needRemoveViewsBeforTalk = @[pDeButton,pDeLable];
    self.answerCallerTipLable.hidden = YES;

    wself_define();
    [ACNetCenter callURL:[NSString stringWithFormat:@"%@/rtc/start?t=%d",[ACNetCenter urlHead_ChatWithTopic:self.videoCallTopic],self.bForVideoCall?0:1]
                  forPut:NO
            withPostData:nil
               withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
                   //                   [parent.view hideProgressHUDWithAnimated:NO];
                   NSString *descErr =  nil;
                   if(!bIsFail){
                       
                       
                       /*
                        "config" : {
                        "facingMode" : "0.5",
                        "server" : "wss:\/\/192.168.1.231:8083\/acurtc\/",
                        "volume" : 0.5,
                        "ClientDisplayName" : "tom",
                        "Title" : "tom, john",
                        "HostID" : "569c8a39659ef74ad215d724",
                        "SenderID" : "569c8a39659ef74ad215d724",
                        "stun" : null,
                        "ClientName" : "569c8a39659ef74ad215d724",
                        "SenderDisplayName" : "tom",
                        "CallType" : 1,
                        "turnPwd" : null,
                        "turn" : null,
                        "ClientID" : "569c8a39659ef74ad215d724",
                        "height" : 480,
                        "turnUser" : null,
                        "width" : 640,
                        "HostCompany" : "aculearn",
                        "SessionID" : "a088aabee07fc3ae303da78787cfeccd",
                        "teid" : "a088aabee07fc3ae303da78787cfeccd",
                        "ClientCompany" : "",
                        "VideoCall" : 1
                        },
                        */
                       
                       
                       NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
                       //                       ITLog(responseDic);
                       if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                           
                           //                           ACVideoCall* pTheVideoCall = [ACVideoCall shareVideoCall];
                           wself.webRTC_Config   =  responseDic[@"config"];
                           //收到配置信息，等待对方响应
//                           ITLog(weak_self.webRTC_Config);
                           int nExpire = [wself.webRTC_Config[@"expire"] intValue]/1000;
                           [wself caller_answer_setOutTime:nExpire<=10?30:nExpire withSelector:@selector(_outTime_Caller)];

                           [[NSNotificationCenter defaultCenter] addObserver:wself
                                                                    selector:@selector(onWebRTC_Notifition_for_Caller:)
                                                                        name:kNetCenterWebRTC_Notifition
                                                                      object:nil];
                           return;
                       }
                       else{
                           descErr = [responseDic objectForKey:kDescription];
                       }
                   }
                   
                   [wself _closeWithTip:descErr.length?descErr:NSLocalizedString(@"VideoCall_Failed", nil) withCancelType:0];
               }];

}


-(void)_closeWithTip:(NSString*)pTip withCancelType:(int)CancelType{
    [self caller_answer_clearSatat];
    self.talkInfo = nil;
    [ACVideoCallVC hide];
    
    if(CancelType&&self.webRTC_Config){
        [ACVideoCall webRTC_SendStat:CancelType withCfg:self.webRTC_Config];
    }
    
    if(pTip){
        [ACUtility showTip:pTip];
    }
    
    //    [self ACdismissViewControllerAnimated:NO completion:^{
    //        [ACUtility showTip:pTip];
    //    }];
}

-(void)onWebRTC_Notifition_for_Caller:(NSNotification*)notify{
    NSDictionary* eventDict = notify.object;
    NSInteger nEventType =  [eventDict[kNetCenterWebRTC_Notifition_type] integerValue];
    
    if(EntityEventType_WEBRTC_Answered==nEventType){
        //对方响应

        [ACVideoCallVC startWebRTC];
        //        [self ACdismissViewControllerAnimated:NO completion:^{
        //            [ACR webRTC_StartWithCfg:pCfg forUser:pCaller];
        //        }];
        return;
    }
    
    //    "VideoCall_Rejected_Calling" = "%@ 正在通话中";
    //    "VideoCall_Rejected" = "%@ 已拒绝";
    
    NSString* pTip = NSLocalizedString(@"VideoCall_Rejected", nil);
    if(EntityEventType_WEBRTC_Rejected==nEventType&&
       REJECTREASON_CALLING==[[eventDict objectForKey:@"reject"] integerValue]){
        pTip    = NSLocalizedString(@"VideoCall_Rejected_Calling", nil); //
        //对方拒绝
    }
    [self _closeWithTip:[NSString stringWithFormat:pTip,self.caller.name] withCancelType:0];
}

- (void)onCancel_Caller:(id)sender {


    [self _closeWithTip:nil withCancelType:webRTC_SendStat_Cancel_Failed];
    
    
    //    [self _clearStat];
    //    [ACVideoCall webRTC_SendStat:webRTC_SendStat_Cancel_Failed withCfg:_webRTC_Config];
    //    [self ACdismissViewControllerAnimated:YES completion:nil];
}

-(void)forceTerminate_Caller{
    [self onCancel_Caller:nil];
}

-(void)_outTime_Caller{
    //超时
    [self _closeWithTip:NSLocalizedString(@"No answer", nil) withCancelType:webRTC_SendStat_Cancel_Failed];
    //    [self _clearStat];
    //    [ACVideoCall webRTC_SendStat:webRTC_SendStat_Cancel_Failed withCfg:_webRTC_Config];
    //    [ACUtility showTip:NSLocalizedString(@"No answer", nil)];
    //    [self ACdismissViewControllerAnimated:YES completion:^{
    //    }];
}


@end
