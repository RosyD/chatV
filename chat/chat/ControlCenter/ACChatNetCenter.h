//
//  ACChatNetCenter.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-10.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSrc    @"src"
#define kThumb  @"thumb"

@class ACMessage;
@class ACTextMessage;
@class ACLocationMessage;
@class ACStickerMessage;
@class ACFileMessage;
@interface ACChatNetCenter : NSObject


-(BOOL)messageIsSendingWithMessage:(ACMessage *)message;
//自动判断message类型
-(void)sendMessage:(ACMessage *)message;

//重发消息
-(void)resendMessage:(ACMessage *)message;
+(void)resendMessageFail:(ACMessage *)message;
-(void)resendMessageFail:(ACMessage *)message;

//发送消息成功
+(void)sendMessage:(ACMessage *)message SuccessWithSourceMsgID:(NSString*)sourceMessageID;
-(void)sendMessage:(ACMessage *)message SuccessWithSourceMsgID:(NSString*)sourceMessageID;

//放弃当前发送的消息
-(void)cancelNowSendingMessages;

-(void)sendMsgFromTCP_Success:(NSDictionary*)pResult; //发送TCP成功
-(void)sendMsgFromTCP_CheckMsgNeedSend;    //检查是否有信息需要发送

+(NSDictionary*)getMsgSendDict:(ACMessage *)message; //取得发送的信息

@end
