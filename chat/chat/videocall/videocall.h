//
//  videocall.h
//  videocall
//
//  Created by Aculearn on 15-1-16.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "acucom_listener_interface.h"

/*
    Video Call的Conference和AcuCom之间的接口定义
 */


@interface videocall : NSObject

/*
 1，启动或加入会议接口
 boolean startConference(Config config)
 参数
 config: 是一个JSON对象， 内容如下， AcuCom客户端只需要填写有注释部分参数， 其余的通过AcuCom服务器下载获得， 然后拼接成完整对象后作为参数调用此接口。
 {
     SessionID: chatId, //AcuCom的会话ID
     HostID: creatorId, //AcuCom会话的创建者ID,
     HostCompany: aculearn,	//AcuCom会话的创建者公司domain,
     
     ClientID: userId, //发起者或者加入者的用户ID
     ClientName: kevin, //发起者或者加入者的账户名
     ClientDisplayName: Kevin Wu, //发起者或者
     ClientCompany: aculearn, //
     Title: AcuCom Feedback, //会议名称， 即AcuCom的会话名称
     VideoCall: 1, //1是1对1的视频会议， 0是多人视频会议
     CallType: 1, //1是语音呼叫， 0是视频呼叫
     
     Description: ,
     Port: 7350,
     SSL: 0,
     MaxUser: 10000,
     MaxSpeaker: 10000,
     MaxSpeed: 4096,
     StartMode: 0,
     ConfMode: 1,
     VideoQuality: 0,
     QualityPower: 4,
     HDMode: 1,
     FrameRatePower: 1,
     AllowAllRecord: 1,
     AutoAccept: 0,
     EncryptAV: 0,
     Server: 192.168.1.8,
     Moderator: 1,
 }
 返回值
 boolean， true为成功， false为失败
 
 此接口的AcuCom业务逻辑会是
 点击发起视频会议按钮时发送请求到服务器， 请求成功服务器会返回Config的后半部分， 然后调用此接口启动视频会议。
 */

- (BOOL)startConference:(NSDictionary*)config
       parentController:(UIViewController*)parent;

- (void)cancelConference;

- (UIViewController*)getMsgController;

/*
 2，检查视频会议是否处于启动中
 boolean isConferenceActive()
 返回值
 boolean， true为活跃， false为不活跃
 
 此接口的AcuCom业务逻辑会是
 在收到其他启动视频会议事件时检查此接口， 如果不活跃就启动视频会议， 如果活跃就让视频会议弹出确认对话框询问用户是否切换到另外一个会议。
 */

- (BOOL)isConferenceActive;

/*
 3，通知收到消息
 void messageNotification(String msgSumary, String chatGroupTitle, String chatGroupId)
 参数
 msgSumary， 消息的摘要信息， 如Kevin：明天去哪儿玩？ 或者ZhiYuan： send a file
 chatGroupTitle, 消息所属会话的标题
 chatGroupId， 会话ID
 
 此接口的AcuCom业务逻辑会是
 收到消息后在视频会议活跃时生成消息摘要， 并通过此接口告知Conference， Conference会做出适当通知。
 */

- (void)messageNotification:(NSString*)msgSumary
             chatGroupTitle:(NSString*)groupTitle
                chatGroupId:(NSString*)groupId;

/*
 4，在视频会议中弹出YesNo对话框
 
 这个方法专用于接收到其他会话的视频会议弹出是否切换视频会议的对话框， 
 如果点了是， 需要通过AcuComListener#conferenceClosed告知AcuCom会议已退出， 可以开始新的会议；
 如果点了否， 需要通过AcuComListener#userRejected告知AcuCom
 void incomingCallDialog(String title, String content, String yesName, String noName, Conifg config)
 
 参数
 title， 指定弹出对话框的标题
 content， 指定弹出对话框的内容
 yesName， yes按钮的文字
 noName， no按钮的文字
 config， 这是收到的其他视频会议信息， 需要在用户点击切换会议后发回到AcuCom客户端。 （在接收到新视频请求的事件中， 会附带启动会议的绝大部分参数， 包含会议名称等， 通过这些参数再加上往前用户的个人信息构成这个config对象）。 Conference不需要关心该对象的内容。
 
 */

- (void)incomingCallDialog:(NSString*)dlgTitle
                dlgContent:(NSString*)content
                dlgYesName:(NSString*)yesName
                 dlgNoName:(NSString*)noName
                    config:(NSDictionary*)config;

/*
 5，设置AcuCom客户端回调接口， 设置到Conference中的AcuCom回调对象， 
 在Conference状态变化时， 通过该对象通知到AcuCom客户端。
    
    void setAcuComListener(AcuComListener listener);
    
     interface AcuComListener {
     void conferenceClosed(int closeType, Config config);
     }
 
 */

- (void)setAcuComListener:(AcuComListener*)listener;

/*
6，接收到会议相关的通知
void conferenceNotification(Integer type, String msgSumary, String sessionId)
参数
type， 1为用户拒绝加入会议， 2为用户已同意加入会议。
msgSumary， 通知的摘要信息， 如“Ken拒绝了您的呼叫”等
sessionId， 会议的SessionID

当在单聊情况下， 如果被叫方拒绝加入会议， 
 AcuCom通过此接口通知AcuConference， 
 此时AcuConference需要告知用户， 对方以拒绝， 
 点击Okay后退出会议。
当在群聊的情况下， 如果被叫方拒绝加入会议， 
 AcuCom通过此接口通知AcuConference， 
 此时AcuConference需要通过某种方式现实给发起者， 
 某用户拒绝加入会议。 
 这种情况下只会在发起者才能收到此通知。

type 2为用户已同意加入会议目前是保留类型， 暂时不用实现。
 */
- (void)conferenceNotification:(int)type
                     msgSumary:(NSString*)sumary
                       session:(NSString*)sessinId;


- (void)forceTerminate;

@end
