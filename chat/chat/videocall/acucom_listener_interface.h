//
//  acu_com_listener_interface.h
//  videocall
//
//  Created by Aculearn on 15-1-19.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#ifndef __videocall__acu_com_listener_interface__
#define __videocall__acu_com_listener_interface__

typedef enum _tagAcuComStatus
{
    AcuCom_Unknown = 0,
    AcuCom_ConferenceSession_Start_Success,
    AcuCom_ConferenceSession_Start_Fail,
}AcuComStatus;

class AcuComListener
{
public:
    virtual ~AcuComListener() {}
    
public:
    /*
     
     ----zhiyuan add begin----
     the follow NOT used.
     
     conferenceClosed方法是在Conference完全退出后回调AcuCom客户端， 告知退出的具体原因。
     closeType的类型如下，
     closeType ＝ 1
     为用户主动退出会议， config为空。
     
     closeType ＝ 5
     用户因会议解散退出， config为空。
     
     closeType ＝ 10
     用户被提出会议， config为空。
     
     closeType ＝ 100
     为用户通过弹出的对话框点击Yes退出Conference， 此时config为AcuCom客户端弹出对话框时带过去的config对象。
     ----zhiyuan add end----
     
     closeType = 20
        force Terminal confernece outside. config = nil;
     
     closeType = 30
        conference colose inside. config = nil;
     */
    virtual void conferenceClosed(int closeType, NSDictionary* config) = 0;
    
    //----zhiyuan add begin----
    
    /*
     
     the follow function NOT used.
     
     当用户选择不切换到新会议时， AcuConference需要通过此接口回调到AcuCom，
        AcuCom在通知服务器， 给发起者发送拒绝入会的事件通知。
    
    virtual void userRejected(NSDictionary *config) = 0;
    
    virtual void conferenceNotification(AcuComStatus status) = 0;
    */
    //----zhiyuan add end----
    
    virtual void showCalledUserIcon(UIImageView* pImageView)=0;
    //txb 显示用户头像
    
};

#endif /* defined(__videocall__acu_com_listener_interface__) */
