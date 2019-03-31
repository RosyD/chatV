//
//  ACVideoCall.h
//  chat
//
//  Created by Aculearn on 1/23/15.
//  Copyright (c) 2015 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    REJECTREASON_UserAccept = 0,    //用户接受了
    
    /**
     * 在没有视频会议时用户主动点击拒绝
     */
    REJECTREASON_BUSY = 1,
    /**
     * 用户没有接听视频会议
     */
    REJECTREASON_BUSYTIMEOUT = 10,
    /**
     * 用户正在视频会议中时， 用户主动点击拒绝
     */
    REJECTREASON_INCALL = 20,
    /**
     * 用户正在视频会议中时， 用户没有点击切换视频的对话框导致超时
     */
    REJECTREASON_INCALLTIMEOUT = 30,
    /**
     * 用户已经进入该视频会议， 自动拒绝
     */
    REJECTREASON_ALREADY = 40,
    
    /**
     * 用户正在被叫中， 用户拒绝
     */
    REJECTREASON_CALLING = 50,
    /**
     * 用户正在被叫中， 超时拒绝
     */
    REJECTREASON_CALLINGTIMEOUT = 60,
} ACVideoCallRejectType;



@class ACUser;
@class ACTopicEntity;

@interface ACVideoCall : NSObject{
    
    NSDictionary*       _videoCallConfig;
    NSDictionary*       _userInfoForLaunchOption; //程序启动时的信息
    
    BOOL                _isForWebRTC;     //使用webRTC

    //---------------Conference---------------
    NSString*           _conference_calledUserIconForAudioCall; //语音呼叫时需要的用户头像ID
    NSInteger           _conference_nForceTerminateType;
    NSString*           _conference_pForceTerminateTip;
}

//@property   (nonatomic,weak,readonly,getter=getCaller) ACUser* caller;
//@property   (nonatomic,strong,readonly,getter=getGroupIcon) NSString* groupIcon;
//@property   (nonatomic,strong,readonly,getter=getGroupShowName) NSString* groupShowName;
//@property   (nonatomic,strong,readonly) NSString* callTip;
//@property   (nonatomic,readonly)    BOOL isVideoCall;
//@property   (nonatomic,readonly)    BOOL isGroupCall;
@property   (nonatomic,weak,readonly) ACTopicEntity* videoCallTopic;




+(instancetype)shareVideoCall;
-(void)clearVideoCallInfo; //清除呼叫信息

+(void)startCallForVideo:(BOOL)forVideo
       withTopicEntity:(ACTopicEntity*)topicEntity
    withParentController:(UIViewController*)parent
            withUser:(ACUser*)user;
+(void)cancelVidelCallInMain_queue; //在主线程中调用
+(BOOL)inVideoCall; //正在VideoCall
+(BOOL)inVideoCallAndShowTip; //判断当前状态，如果在Videocall状态则提示
+(void)removetopicEntity:(NSString*)pTopicID; //删除Top



//-(BOOL)startConference:(NSDictionary*)config
//              parentController:(UIViewController*)parent;
-(void)checkAppLanuchVideoCall;

-(void)onVideoCallEvent:(int)nEventType withDict:(NSDictionary*)eventDict;

-(BOOL)onAppNotificationUserInfo:(NSDictionary*)userInfo;

-(void)joinCall:(int)nCallType
    withTopicEntity:(ACTopicEntity*)topicEntity
       withSenderID:(NSString*)pUserID
     withErrTipView:(UIView*)pErrTipView
          forWebRTC:(BOOL)forWebRTC;


//通过界面接受Call
-(void)onUser:(ACUser*)user Accept:(ACVideoCallRejectType)nType;

//*****************************webRTC*******************

#define webRTC_SendStat_FirstSuccess    0       //p2p 首次建连成功(connected)后。只调用一次。
#define webRTC_SendStat_Cancel_Failed   1       //p2p连接没有成功前
#define webRTC_SendStat_Cancel_Success  2       //p2p连接成功后（只要成功过）

//+(void)webRTC_SetTallVC:(ACVideoCall_WebRTC_VC*)vc withCfg:(NSDictionary*)webRTCCfg;
+(void)webRTC_SendStat:(int)stat withCfg:(NSDictionary*)webRTCCfg;




//内部使用

-(void)_rejectVideoCall:(ACVideoCallRejectType)nType
            withTopicID:(NSString*)topicEntityId //会话id
         withCallConfig:(NSDictionary *)config;
+(NSDictionary*)_getVideoCallConfigFromSrcDict:(NSDictionary*)pSrcConfig;

@end
