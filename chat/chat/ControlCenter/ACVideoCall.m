//
//  ACVideoCall.m
//  chat
//
//  Created by Aculearn on 1/23/15.
//  Copyright (c) 2015 Aculearn. All rights reserved.
//

#import "ACVideoCall.h"
#import "ACEntityEvent.h"
#import "ACNetCenter.h"
#import "ACUser.h"
#import "ACDataCenter.h"
#import "ACRootViewController.h"
#import "UIView+Additions.h"
#import "UINavigationController+Additions.h"
#import "ACVideoCallVC.h"
#import "ACMessage.h"
#import "ACVideoCall+Conference.h"



#define EntityEventType_Video_Call_Direct_Accept -100
//处理EntityEventType_Video_Call直接接受，不显示CallVC

@implementation ACVideoCall

static ACVideoCall *g__shareVideoCall = nil;

+(instancetype)shareVideoCall{
    if(nil==g__shareVideoCall){
        g__shareVideoCall = [[ACVideoCall alloc] init];
    }
    return g__shareVideoCall;
}

+(void)removetopicEntity:(NSString*)pTopicID{ //删除Top
    if(g__shareVideoCall&&
       g__shareVideoCall.videoCallTopic&&
       [g__shareVideoCall.videoCallTopic.entityID isEqualToString:pTopicID]){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL bShowTip = [ACVideoCallVC isInVideoCall];
            [self cancelVidelCallInMain_queue];
            if(bShowTip){
                [ACUtility showTip:NSLocalizedString(@"VideoCall_Cancel", nil)];
            }
        });
    }
}
//-(BOOL)isVideoCall{
//    return [[_videoCallConfig objectForKey:@"CallType"] intValue]==0;
//}
//
//-(BOOL)isGroupCall{
//    return [[_videoCallConfig objectForKey:@"VideoCall"] intValue]==0;
//}



+(BOOL)inVideoCall{
    return [ACVideoCallVC isInVideoCall]||
            [ACVideoCall conference_isCalling];
}

+(BOOL)inVideoCallAndShowTip{
    if([self inVideoCall]){
//        NSString* pTip = @"";
//        if([[self shareVideoCall] getIsVideoCall]){
//            pTip    =   NSLocalizedString(@"正在视频聊天，请稍后再试",nil);
//        }
//        else{
//            pTip    =   NSLocalizedString(@"VideoCall_Incoming",nil);
//        }
        [ACUtility showTip:NSLocalizedString(@"Device is in using, please try later",nil)];
        return YES;
    }
    return NO;
}


+(void)cancelVidelCallInMain_queue{
    ACVideoCall* pShare = [ACVideoCall shareVideoCall];
    [pShare conference_ForceTerminate:ForceTerminate_InMain_queue withTip:nil];
    [ACVideoCallVC forceTerminate];
    [pShare clearVideoCallInfo];
}


+(NSDictionary*)_getVideoCallConfigFromSrcDict:(NSDictionary*)pSrcConfig{
    NSMutableDictionary* pRet = [[NSMutableDictionary alloc] initWithDictionary:[pSrcConfig objectForKey:@"config"]];
    
    /*
     ConferenceConfig对象里增加了以下属性， 以下属性是由AcuCom mobile填写的。
     LocalTitle: Ken Tan, //呼叫会话的标题， 单聊时是对方的名字， 组聊时是组聊的名字。
     LocalIcon: /home/user/1.png, //会话的本地图标， 是手机上的本地路径。
     */
    
    /*
    NSString* pLocalTitle = nil;
    if([pRet getisGroupCall]){
        ACTopicEntity* pTopicEntity = [[ACDataCenter shareDataCenter] findTopicEntity:[pRet objectForKey:kTeid]];
        pLocalTitle = pTopicEntity.title;
    }
    else{
        NSDictionary* pUsrDict = [pSrcConfig objectForKey:@"user"];
        if(pUsrDict){
            pLocalTitle =   [pUsrDict objectForKey:kName];
        }
        else{
            pLocalTitle = [[NSUserDefaults standardUserDefaults] objectForKey:kName];
        }
    }*/
    ACTopicEntity* pTopicEntity = [[ACDataCenter shareDataCenter] findTopicEntity:pRet[kTeid]];
    NSString* pLocalTitle = pTopicEntity.showTitle;
    
    if(pLocalTitle){
        [pRet setObject:pLocalTitle forKey:@"LocalTitle"];
    }
    return pRet;
}


+(void)webRTC_SendStat:(int)stat withCfg:(NSDictionary*)webRTCCfg{
    if(webRTCCfg){
        NSString* pURL_Head =   [NSString stringWithFormat:@"%@/rtc/%@",[ACNetCenter urlHead_ChatWithTopicID:webRTCCfg[kTeid]],webRTCCfg[@"SessionID"]];
        
        ;
        if(webRTC_SendStat_FirstSuccess==stat){
            //#define webRTC_SendStat_FirstSuccess    0       //p2p 首次建连成功(connected)后。只调用一次。
            [ACNetCenter callURL:[NSString stringWithFormat:@"%@/state?t=1",pURL_Head]
                 forMethodDelete:NO
                       withBlock:nil];
            return;
        }
        
        if(webRTC_SendStat_Cancel_Failed==stat||
           webRTC_SendStat_Cancel_Success==stat){
//#define webRTC_SendStat_Cancel_Failed   1       //p2p连接没有成功前
//#define webRTC_SendStat_Cancel_Success  2       //p2p连接成功后（只要成功过）
            [ACNetCenter callURL:[NSString stringWithFormat:@"%@/cancel?t=%d",pURL_Head,webRTC_SendStat_Cancel_Failed==stat?0:1]
                 forMethodDelete:YES
                       withBlock:nil];
        }
        else{
            return;
        }
    }
    else if(webRTC_SendStat_FirstSuccess==stat){
        return;
    }

    [[ACVideoCall shareVideoCall] clearVideoCallInfo];
}


+(void)startCallForVideo:(BOOL)forVideo
         withTopicEntity:(ACTopicEntity*)topicEntity
    withParentController:(UIViewController*)parent
            withUser:(ACUser*)user{
/*
 callType: 1是audio call， 0是video call
*/
    ACVideoCall* pVideoCall =   [ACVideoCall shareVideoCall];
    BOOL    isSigleChat =   topicEntity.isSigleChat;
    
    [pVideoCall clearVideoCallInfo];
    
    pVideoCall->_isForWebRTC    =   isSigleChat;
    pVideoCall->_videoCallTopic =   topicEntity;

    if(isSigleChat){
        [ACVideoCallVC showCallerForTopic:topicEntity withUser:user forVideoCall:forVideo];

        return;
    }
    
    [pVideoCall conference_startCallForVideo:forVideo
                        withParentController:parent
                                    withUser:user];
}

-(void)clearVideoCallInfo{
    _videoCallTopic     =   nil;
    _videoCallConfig    =   nil;
    _isForWebRTC        =   NO;
    _conference_nForceTerminateType    =   ForceTerminate_NoUse;
    _conference_pForceTerminateTip  =   nil;
    [ACVideoCallVC hideFunc];
}

-(void)checkAppLanuchVideoCall{
    if(_userInfoForLaunchOption){
        NSDictionary* pTemp =   _userInfoForLaunchOption;
        _userInfoForLaunchOption = nil;
        ITLogEX(@"VideoCall Have userInfoForLaunchOption %@",pTemp);
        [self onAppNotificationUserInfo:pTemp];
    }
}


-(void)joinCall:(int)nCallType
    withTopicEntity:(ACTopicEntity*)topicEntity
        withSenderID:(NSString*)pUserID  withErrTipView:(UIView*)_pErrTipView  forWebRTC:(BOOL)forWebRTC{
    //nCallType 0:VideoCall 1:AudioCall
    __weak UIView* pErrTipView = _pErrTipView;
    [pErrTipView showProgressHUD];
    
    _isForWebRTC    =   forWebRTC;
    
    NSString* pURL = [NSString stringWithFormat:@"%@/%@/join?t=%d&s=%@",[ACNetCenter urlHead_ChatWithTopicID:topicEntity.entityID],_isForWebRTC?@"rtc":@"conference",nCallType,pUserID];
    
    wself_define();
    [ACNetCenter callURL:pURL
                  forPut:NO
            withPostData:nil
               withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
                   [pErrTipView hideProgressHUDWithAnimated:NO];
                   if(!bIsFail){
                       NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
                       ITLog(responseDic);
                       if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                           [wself _onVideoCallEvent:pErrTipView?EntityEventType_Video_Call_Direct_Accept:(forWebRTC?EntityEventType_WEBRTC_Call:EntityEventType_Video_Call)
                                          withDict:responseDic fromEvent:NO withErrTipView:pErrTipView];
                           return ;
                       }
                   }
                   [pErrTipView showNetErrorHUD];
               }];

}
-(BOOL)onAppNotificationUserInfo:(NSDictionary*)userInfo{
    if(nil==userInfo){
        ITLogEX(@"nil==userInfo");
        return NO;
    }
    
    if(_userInfoForLaunchOption&& //重复了
       _userInfoForLaunchOption!=userInfo&&
       [_userInfoForLaunchOption.description isEqualToString:userInfo.description]){
        ITLogEX(@"已有旧的状态了，重复");
        return YES;
    }
    
    int nEventTyep = [[userInfo objectForKey:@"eventType"] intValue];
    if(!(EntityEventType_Video_Call==nEventTyep||EntityEventType_WEBRTC_Call==nEventTyep)){
        ITLogEX(@"eventType(%d)!=%d",nEventTyep,EntityEventType_Video_Call);
        return NO;
    }
    
    int nCallType = [[userInfo objectForKey:@"callType"] intValue];
    long long lExpireTime  = [[userInfo objectForKey:@"expireTime"] longLongValue]/1000;
//        time_t nowTime = time(NULL);
    ACTopicEntity* pTopicEntity = [[ACDataCenter shareDataCenter] findTopicEntity:[userInfo objectForKey:@"topicEntityId"]];
    if(pTopicEntity&&
       (0==nCallType||1==nCallType)&&
       time(NULL)<lExpireTime){
     
        if(LoginState_logined != [ACConfigs shareConfigs].loginState){
            ITLog(@"还没有登录，等待登录后处理VideoCall");
            //待会再调这个函数
            _userInfoForLaunchOption =  userInfo;
            return YES;
        }
//        if(EntityEventType_WEBRTC_Call==nEventTyep){
//            [self  joinWebRTCFromRemoteNotify:userInfo];
//        }
//        else
        
        {
            [self joinCall:nCallType
                 withTopicEntity:pTopicEntity
              withSenderID:[userInfo objectForKey:@"senderId"]
            withErrTipView:nil
                 forWebRTC:EntityEventType_WEBRTC_Call==nEventTyep];
        }
    }
#ifdef ACUtility_Need_Log
    else{
        ITLog(@"VidelCall 超时或其他状态");
    }
#endif
    return YES;
}


-(void)_rejectVideoCall:(ACVideoCallRejectType)nType
           withTopicID:(NSString*)topicEntityId //会话id
        withCallConfig:(NSDictionary *)config {
//conferenceSessionId //会议的SessionId
//creatorId //创建者用户ID， 对应Config对象里的SenderID
    
    NSString* pURL = @"";
    NSString* pURL_Head = [ACNetCenter urlHead_ChatWithTopicID:topicEntityId];
//    if(_isForWebRTC){
//        pURL = [NSString stringWithFormat:@"%@/rtc/user/%@/reject?r=%d",pURL_Head,config[@"SenderID"],(int)nType];
//    }
//    else{
        pURL = [NSString stringWithFormat:@"%@/%@/%@/user/%@/reject?r=%d",
                pURL_Head,_isForWebRTC?@"rtc":@"conference",
                config[@"SessionID"],
                config[@"SenderID"],(int)nType];
//    }
    
    [ACNetCenter callURL:pURL
                  forMethodDelete:YES
               withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
                   if(!bIsFail){
//                       NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
//                       if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
//                           [self onVideoCallEvent:EntityEventType_Video_Call withDict:responseDic];
//                           return ;
//                       }
                   }
               }];
}



-(void)_onVideoCallEvent:(int)nEventType withDict:(NSDictionary*)eventDict  fromEvent:(BOOL)bFromEvent withErrTipView:(UIView*)pErrTipView{
    
    /*
     邀请加入会议事件
     在收到加入会议事件后， 如果当前没有活跃的会议， 则弹出呼叫页面， 接听后启动会议
     
     {
     ......
     "eventType" : 91,
     "teid" : "topicEntityId",
     "terminal" : "ios", //发起会议的终端
     "config" : {Conference config json object}, //用于启动会议的Config对象
     "user" : {User json object}, //发起会议的用户
     ......
     }
     
     
     config =             {
     AMVersion = 8;
     AllowAllRecord = 1;
     AutoAccept = 0;
     CallType = 0;
     ClientCompany = "";
     ClientDisplayName = tom;
     ClientID = 548962cf73c615b99fba9784;
     ClientName = 548962cf73c615b99fba9784;
     ConfMode = 1;
     Description = "";
     EncryptAV = 0;
     FrameRatePower = 1;
     HDMode = 1;
     HostCompany = john;
     HostID = 5458852c3004d589430c3b9a;
     MaxSpeaker = 10000;
     MaxSpeed = 4096;
     MaxUser = 10000;
     Moderator = 1;
     Port = 7350;
     QualityPower = 4;
     SSL = 0;
     SenderDisplayName = john;
     SenderID = 5458852c3004d589430c3b9a;
     Server = "192.168.1.8";
     SessionID = cbee1450222a8f297e98c5b3425dace5;
     StartMode = 0;
     Title = "john, tom";
     VideoCall = 1;
     VideoQuality = 0;
     teid = cbee1450222a8f297e98c5b3425dace5;
     };

     
     */
    ITLogEX(@"%@",eventDict);
    if(EntityEventType_Video_Call==nEventType||
       EntityEventType_WEBRTC_Call==nEventType||
       EntityEventType_Video_Call_Direct_Accept==nEventType){

        NSDictionary* videoCallConfig = [ACVideoCall _getVideoCallConfigFromSrcDict:eventDict];
        if(nil==videoCallConfig){
            ITLog(@"没有cofig");
            return;
        }
        
        NSString* topicEntityId = videoCallConfig[kTeid];
        
        if(_videoCallTopic){
            
            if([topicEntityId isEqualToString:_videoCallTopic.entityID]){
                ITLog(([NSString stringWithFormat:@"已在通话中:%@",topicEntityId]));
                //已在同一个通话中
                return;
            }
            
            //已经有通话,直接拒绝,返回 用户正在通话中
            [self _rejectVideoCall:REJECTREASON_CALLING
                       withTopicID:topicEntityId
                    withCallConfig:videoCallConfig];
            
            return;
        }
        
        ACTopicEntity* pTopic = [[ACDataCenter shareDataCenter] findTopicEntity:topicEntityId];
        
        if(nil==pTopic){//||(bFromEvent&&pTopic.isTurnOffAlerts)){
            //静音则不处理
    #ifdef ACUtility_Need_Log
            if(nil==pTopic||pTopic.isTurnOffAlerts){
                ITLogEX(@"Topic(%@) ",pTopic?@"静音":@"没有Find");
            }
    #endif
            _isForWebRTC = EntityEventType_WEBRTC_Call==nEventType;
            
            [self _rejectVideoCall:REJECTREASON_BUSY
                       withTopicID:topicEntityId
                    withCallConfig:videoCallConfig];
            return;
        }

        if(EntityEventType_Video_Call_Direct_Accept!=nEventType){
            _isForWebRTC =  EntityEventType_WEBRTC_Call==nEventType;
        }
        
        _videoCallTopic     =   pTopic;
        _videoCallConfig    =   videoCallConfig;
        _conference_calledUserIconForAudioCall  =   nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            ACUser* pUer =  [[ACUser alloc] initWithDict:eventDict[@"user"]];
            
            if(EntityEventType_Video_Call_Direct_Accept==nEventType){
                _conference_calledUserIconForAudioCall = eventDict[@"user"][@"icon"];
                [self onUser:pUer Accept:REJECTREASON_UserAccept];
            }
            else{
                int expireTime  =   0;
                if(EntityEventType_WEBRTC_Call==nEventType){
                    expireTime    =   [_videoCallConfig[@"expire"] intValue]/1000;
                }
                [ACVideoCallVC showAnswerForTopic:_videoCallTopic
                                         withUser:pUer
                                    andExpireTime:expireTime
                                           andCfg:_videoCallConfig
                                     forVideoCall:[[_videoCallConfig objectForKey:@"CallType"] intValue]==0];
            }
        });

        return;
    }

    if(EntityEventType_Video_Call_Reject==nEventType||
       EntityEventType_Video_Call_SenderClose==nEventType||
       EntityEventType_WEBRTC_Cancelled==nEventType){
        /*
         "eventType" : 92,
         "teid" : "topicEntityId",
         "terminal" : "android" //拒绝会议的终端
         "csid" : "conferenceSessionId", //会议的sessionId
         "reject" : 1, //拒绝原因
         "user" : {User json object}, //拒绝会议的用户
         
         主叫拒绝事件， 如果发起方取消掉本次呼叫， 这个事件会被推送到所有被叫方
         {
         ......
         "eventType" : 93,
         "teid" : "topicEntityId",
         "terminal" : "android" //拒绝会议的终端
         "csid" : "conferenceSessionId", //会议的sessionId
         ......
         }
         
         */
        NSString* topicEntityId = eventDict[kTeid];
        if(_videoCallTopic&&
           [_videoCallTopic.entityID isEqualToString:topicEntityId]){
            
            //取得拒绝原因
            Conference_ForceTerminateType nTerminateType = ForceTerminate_Sender_Close;
            NSString* pTip = nil;
            if(_videoCallTopic.isSigleChat){ //单聊才显示拒绝原因
            
                pTip = NSLocalizedString(@"VideoCall_Cancel", nil);
            
                if(EntityEventType_Video_Call_Reject==nEventType){
                    NSString* pUserName = [((NSDictionary*) [eventDict objectForKey:@"user"]) objectForKey:kName];
                    NSInteger nRejectType = [[eventDict objectForKey:@"reject"] integerValue];
                    if(REJECTREASON_CALLING==nRejectType){
                        nTerminateType  =   ForceTerminate_REJECTREASON_CALLING;
                        pTip    = [NSString stringWithFormat:NSLocalizedString(@"VideoCall_Rejected_Calling", nil),pUserName];
                    }
                    else if(REJECTREASON_BUSY==nRejectType){
                        nTerminateType  =   ForceTerminate_REJECTREASON_BUSY;
                        pTip    = [NSString stringWithFormat:NSLocalizedString(@"VideoCall_Rejected", nil),pUserName];
                    }
                    else{
                        nTerminateType  =   ForceTerminate_Cancel;
    //                    pTip =  NSLocalizedString(@"VideoCall_Cancel", nil);
                    }
                }
    //            else{
    //                pTip    =   NSLocalizedString(@"VideoCall_Cancel", nil);
    //            }
            }
            
            if([self conference_ForceTerminate:nTerminateType withTip:pTip]){
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString* pTip2 = pTip;
                if(EntityEventType_WEBRTC_Cancelled==nEventType){
                    //出一个提示对话框，关闭
                    NSNumber* pCTytpe = eventDict[@"ctype"];
                    if(pCTytpe){
                        if(1==[pCTytpe intValue]){
                            pTip2 = NSLocalizedString(@"VideoCall_End", nil);
                        }
                        else{
                            pTip2 = NSLocalizedString(@"VideoCall_Cancel", nil);
                        }
                    }
                }

                [ACVideoCallVC forceTerminate];
                if(pTip2.length){
                    [ACUtility showTip:pTip2];
                }
                [self clearVideoCallInfo];
            });
            return;
        }
        return;
    }
    
    if(EntityEventType_Video_Call_Accept_On_OtherDevice==nEventType){
/*
 呼叫已应答事件， 同账户的两个终端被同时呼叫， 一端应答（拒绝或者接听）， 另外一端会收到这个事件
 {
 ......
 "eventType" : 94,
 "teid" : "topicEntityId",
 "terminal" : "android" //拒绝会议的终端
 "csid" : "conferenceSessionId", //会议的sessionId
 "atype" : 1, //ANSWERTYPE_REJECTED = 0; ANSWERTYPE_ANSWERED = 1;
 ......
 }
 */
        if([_videoCallTopic.entityID isEqualToString:eventDict[kTeid]]){
            if([self conference_ForceTerminate:ForceTerminate_Accept_On_OtherDevice withTip:nil]){
                return;
            }
            
            
            [ACVideoCallVC forceTerminate];
            [self clearVideoCallInfo];
        }
        return;
        
    }
}

-(void)onVideoCallEvent:(int)nEventType withDict:(NSDictionary*)eventDict{
    [self _onVideoCallEvent:nEventType withDict:eventDict fromEvent:YES withErrTipView:nil];
}


-(void)onUser:(ACUser*)user Accept:(ACVideoCallRejectType)nType{
    
    if(REJECTREASON_UserAccept==nType){
         NSString* pURL = @"";
        NSString* pURL_Head = [ACNetCenter urlHead_ChatWithTopic:_videoCallTopic];
//            if(_isForWebRTC){
//                pURL    =   [NSString stringWithFormat:@"%@/rtc/answered?t=%d",pURL_Head,1];
//            }
//            else{
        pURL    =   [NSString stringWithFormat:@"%@/%@/%@/answered?t=%d",
                     pURL_Head,
                     _isForWebRTC?@"rtc":@"conference",
                     _videoCallConfig[@"SessionID"],1];
//            }
        
        wself_define();
        [ACNetCenter callURL:pURL
                      forPut:YES
                withPostData:nil
                   withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
                       if(_isForWebRTC){
                           if(!bIsFail){
                               NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
                               ITLog(responseDic);
                               if(ResponseCodeType_Nomal==[responseDic[kCode] intValue]){
                                   [ACVideoCallVC startWebRTC];
                                   return ;
                               }
                           }
                           [ACUtility showTip:NSLocalizedString(@"Check_Network", nil)];
                           [wself clearVideoCallInfo];
                       }
                   }];
        
        if(_isForWebRTC){
            //等待Event
            return;
        }
        
        [self conference_startCallwithCfg:_videoCallConfig
                            withParentController:nil
                                        withUser:user];

        return;
    }
    
    if(REJECTREASON_BUSY==nType&&_videoCallTopic){
        [self _rejectVideoCall:REJECTREASON_BUSY
                  withTopicID:_videoCallTopic.entityID
               withCallConfig:_videoCallConfig];
    }
    
    [self clearVideoCallInfo];
}


@end


