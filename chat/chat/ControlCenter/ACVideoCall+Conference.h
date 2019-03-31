//
//  ACVideoCall.h
//  chat
//
//  Created by Aculearn on 1/23/15.
//  Copyright (c) 2015 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACVideoCall.h"


typedef enum _ForceTerminateType{
    ForceTerminate_NoUse=0,
    ForceTerminate_InMain_queue,    //在主界面被关闭
    ForceTerminate_Sender_Close,    //主叫关闭
    ForceTerminate_Cancel,          //被叫关闭
    ForceTerminate_Accept_On_OtherDevice, //呼叫已应答事件
    ForceTerminate_REJECTREASON_BUSY, //用户忙
    ForceTerminate_REJECTREASON_CALLING, //用户通话中
    
}Conference_ForceTerminateType;

@interface ACVideoCall(Conference)

+(BOOL)conference_isCalling;

-(BOOL)conference_ForceTerminate:(NSInteger)nType withTip:(NSString*)pTip;

-(void)conference_startCallForVideo:(BOOL)forVideo
    withParentController:(UIViewController*)parent
                withUser:(ACUser*)user;
-(void)conference_startCallwithCfg:(NSDictionary*)callCfg
               withParentController:(UIViewController*)parent
                           withUser:(ACUser*)user;

@end
