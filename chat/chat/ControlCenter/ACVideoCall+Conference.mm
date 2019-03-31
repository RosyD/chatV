//
//  ACVideoCall.m
//  chat
//
//  Created by Aculearn on 1/23/15.
//  Copyright (c) 2015 Aculearn. All rights reserved.
//

#import "ACVideoCall+Conference.h"
#import "videocall.h"
#import "ACUser.h"
#import "ACDataCenter.h"
#import "ACNetCenter.h"
#import "ACRootViewController.h"
#import "ACMessage.h"
#import "ACVideoCallVC.h"

void    initVideoCallConference();




static videocall* g__videoCallConference = nil;


@implementation ACVideoCall(Conference)


+(BOOL)conference_isCalling{
    return nil!=g__videoCallConference;
}

-(BOOL)cancelConference{
    if(g__videoCallConference){
        [self onAcuComListenerConferenceClosed:30 withConfig:nil];
        return YES;
    }
    return NO;
}

-(void)_conferenceClear{
    g__videoCallConference = nil;
    [self clearVideoCallInfo];
}


-(void)onAcuComListenerConferenceClosed:(int)closeType withConfig:(NSDictionary*)config{
    ITLogEX(@"%d",closeType);
    
    /*
     closeType = 20
     force Terminal confernece outside. config = nil;
     
     closeType = 30
     conference colose inside. config = nil;
     */
    
    if(20==closeType){
        //调用 forceTerminate
        if(ForceTerminate_InMain_queue==_conference_nForceTerminateType){
            closeType = 30;
        }
        
        if(_conference_pForceTerminateTip){
            NSString* pTip =    _conference_pForceTerminateTip;
            dispatch_async(dispatch_get_main_queue(), ^{
                [ACUtility ShowTip:pTip withTitle:nil];
            });
        }
    }
    
    if(30==closeType){
        //conference 主动退出
    
        if([ACUser isMySelf:[_videoCallConfig objectForKey:@"SenderID"]]){
            //是主叫
           /*
            主叫取消会议， 需要在conferenceClosed回调中， 无论是任何closeType且用户是当前会议的创建者时调用这个接口。
            URI: rest/apis/chat/{topicEntityId}/conference/{conferenceSessionId}/cancel
            Url parameters
            
            callType: 1是audio call， 0是video call
            
            Path parameters
            
            topicEntityId: 会话id
            conferenceSessionId: 会议的SessionId
            
            Method: DELETE
            Response:
            
            {
            "code" : 1,
            }
            */
            [ACNetCenter callURL:[NSString stringWithFormat:@"%@/conference/%@/cancel",[ACNetCenter urlHead_ChatWithTopicID:self.videoCallTopic.entityID],_videoCallConfig[@"SessionID"]]
                 forMethodDelete:YES withBlock:nil];
        }
        else {
            //&&_videoCallConfig
//            NSLog(@"000000000000000000000000000");
            [self _rejectVideoCall:REJECTREASON_INCALL
                      withTopicID:_videoCallConfig[kTeid]
                   withCallConfig:_videoCallConfig];
        }
    }
    [self _conferenceClear];
}

-(void)_conference_Error:(NSString*)pTip withVC:(UIViewController*)parent{
    [self _conferenceClear];
    if(0==pTip.length){
        pTip    = NSLocalizedString(@"VideoCall_Failed", nil);
    }
    if(parent){
        [parent.view showProgressHUDNoActivityWithLabelText:pTip withAfterDelayHide:0.8];
    }
    else{
        [ACUtility showTip:pTip];
    }
}

-(void)conference_startCallForVideo:(BOOL)forVideo
               withParentController:(UIViewController*)parent
                           withUser:(ACUser*)user{
    [parent.view showNetLoadingWithAnimated:YES];
    
    wself_define();
    [ACNetCenter callURL:[NSString stringWithFormat:@"%@/conference/start?t=%d",[ACNetCenter urlHead_ChatWithTopic:self.videoCallTopic],forVideo?0:1]
                  forPut:NO
            withPostData:nil
               withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
                   [parent.view hideProgressHUDWithAnimated:NO];
                   NSString* pErrTip = nil;
                   if(!bIsFail){
                       //                       NSData* pData =  request.responseData;
                       //                       [pData writeToFile:@"/Volumes/ramdisk/1.txt" atomically:NO];
                       
                       //                       NSLog(@"%d",request.responseStatusCode);
                       
                       NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
                       ITLogEX(@"%@",responseDic);
                       if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                           
                           [wself conference_startCallwithCfg:[ACVideoCall _getVideoCallConfigFromSrcDict:responseDic] withParentController:parent withUser:user];
                           return;
                       }
                       
                       pErrTip = [responseDic objectForKey:kDescription];
                   }
                   [wself _conference_Error:pErrTip withVC:parent];
               }];

}

-(void)conference_startCallwithCfg:(NSDictionary*)config
              withParentController:(UIViewController*)parent
                          withUser:(ACUser*)user{
    
    _conference_calledUserIconForAudioCall = user.icon;
    
    initVideoCallConference();
    
    [ACVideoCallVC startConferenceWithBlock:^(UIViewController *pParentForConference) {
        if([g__videoCallConference startConference:config parentController:pParentForConference]){
            _videoCallConfig  =   config;
            return;
        }
        [self _conference_Error:nil withVC:parent];
    }];
    
}

-(BOOL)conference_ForceTerminate:(NSInteger)nType withTip:(NSString*)pTip{
    if(g__videoCallConference){
        _conference_pForceTerminateTip     =   pTip;
        _conference_nForceTerminateType    =   nType;
        [g__videoCallConference forceTerminate];
        return YES;
    }
    return NO;
}


-(void)showCalledUserIcon:(UIImageView*)pIconView{
    if(_conference_calledUserIconForAudioCall.length){
        [pIconView setToCircle];
        [ACRootViewController showUserIcon200ForImageView:pIconView
                                              withIconStr:_conference_calledUserIconForAudioCall];
    }
}

@end

class ACVideoCallListener : public AcuComListener{
public:
    virtual void conferenceClosed(int closeType, NSDictionary* config){
        [[ACVideoCall shareVideoCall] onAcuComListenerConferenceClosed:closeType withConfig:config];
    }
    /*    void userRejected(NSDictionary *config){
     [[ACVideoCall shareVideoCall] onAcuComListenerUserRejected:config];
     }
     void conferenceNotification(AcuComStatus status){
     [[ACVideoCall shareVideoCall] onAcuComListenerConferenceNotification:status];
     }*/
    
    void showCalledUserIcon(UIImageView* pImageView){
        [[ACVideoCall shareVideoCall] showCalledUserIcon:pImageView];
    }
};

static  ACVideoCallListener g__theVidelCallListener;

void    initVideoCallConference(){
    if(nil==g__videoCallConference){
        g__videoCallConference  =   [[videocall alloc] init];
        [g__videoCallConference  setAcuComListener:&g__theVidelCallListener];
    }
}


