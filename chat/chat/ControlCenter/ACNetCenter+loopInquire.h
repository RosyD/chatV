//
//  ACNetCenterTcp.h
//  chat
//
//  Created by Aculearn on 15/11/27.
//  Copyright © 2015年 Aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "SRWebSocket.h"


@interface ACNetCenter(loopInquire)<GCDAsyncSocketDelegate,SRWebSocketDelegate,NSStreamDelegate>

-(void)loopInquireTcp_closeWithDelayConnect:(BOOL)bDelayConnect withWhy:(NSString*)why;

//轮询
-(void)loopInquire;

//进入后台停止轮询
-(void)deleteLoopInquireForLoginUI:(BOOL)forLogInUI;

//检查轮询,返回正常
-(BOOL)loopInquireCheckTCPConnect;


//同步数据
-(void)syncData;

//处理同步数据
-(void)doSyncData:(NSDictionary*)responseDic needCheck:(BOOL)bCheck;


//直接通过TCP通道发送Msg
+(BOOL)sendMsgFromTCP:(ACMessage*)pMsg;
+(BOOL)sendMsgFromTCP_IsReady;
@end
