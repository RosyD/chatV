//
//  ACVideoCallVC.h
//  chat
//
//  Created by Aculearn on 16/11/28.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>


#define USER_ICON_IMAGE_DEFAULT_TOP 150     //头像缺省位置Y

typedef void (^startConferenceBlock)(UIViewController* pParentForConference);

typedef NS_ENUM(NSUInteger, ACVideoCallVCStat) {
    ACVideoCallVCStatIDE, //空闲
    ACVideoCallVCStatCaller,
    ACVideoCallVCStatAnswer,
    ACVideoCallVCStatTalk
};

@class ACUser;
@class ACTopicEntity;
@class ACVideoCallVC_TalkInfo;

@interface ACVideoCallVC : UIViewController

@property (strong, nonatomic)   ACUser*             caller;        //呼叫用户
@property (weak,nonatomic)      ACTopicEntity*      videoCallTopic;
@property (nonatomic)           BOOL                bForVideoCall;
@property (nonatomic)           ACVideoCallVCStat   nStat;     //当前VC状态


//----

@property (strong, nonatomic) UIImageView *bkView;
@property (strong, nonatomic) UIImageView *userIconImageView;
@property (strong, nonatomic) UILabel     *userNameLable;
@property (strong, nonatomic) UILabel     *answerCallerTipLable; //TIP


@property (strong, nonatomic)   NSDictionary*           webRTC_Config;
@property (strong, nonatomic)   NSArray<UIView*>*       needRemoveViewsBeforTalk;


//------- answer
@property (nonatomic)           int         nAnswer_RejectType;
@property (nonatomic)           int         nAnswer_ExpireTime; //超时时间

//------- caller


//------- talk
@property (strong, nonatomic)   ACVideoCallVC_TalkInfo* talkInfo;



-(void)caller_answer_setOutTime:(int)expireTime withSelector:(SEL)aSelector;
-(void)caller_answer_clearSatat;



//------- 全局函数
+(void) showAnswerForTopic:(ACTopicEntity*)topic withUser:(ACUser*)pUsr andExpireTime:(int)expireTime andCfg:(NSDictionary*)pCfg forVideoCall:(BOOL)bForVideoCall;
+(void) showCallerForTopic:(ACTopicEntity*)topic withUser:(ACUser*)pUsr forVideoCall:(BOOL)bForVideoCall;

+(BOOL) isInVideoCall;
+(void) forceTerminate; //强行关闭
+(void) hide;
+(void) hideFunc; //仅仅是隐藏window
+(void) startConferenceWithBlock:(startConferenceBlock) block;
+(void) startWebRTC;
+(void) showMinWithSize:(CGSize)theSize;
+(void) showMax;



@end
