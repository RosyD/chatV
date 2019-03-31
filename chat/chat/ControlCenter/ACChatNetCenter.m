//
//  ACChatNetCenter.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-10.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACChatNetCenter.h"
#import "ACMessage.h"
#import "ACAddress.h"
#import "ACNetCenter.h"
#import "ACMessageDB.h"
#import "JSONKit.h"
#import "ACNetCenter+loopInquire.h"

NSString * const kNetCenterSendMessageSuccessNotifation = @"kNetCenterSendMessageSuccessNotifation";
NSString * const kNetCenterSendMessageFailNotifation = @"kNetCenterSendMessageFailNotifation";


#define kSendTextMessageUrl [NSString stringWithFormat:@"%@/%@",[[ACNetCenter shareNetCenter] acucomServer],@"rest/apis/chat/topic"]

@interface ACChatNetCenter(){
    NSMutableArray      *_sendingMessageArray; //大文件类消息队列
    NSMutableArray      *_sendingMsgFromTCP;    //通过TCP通道发送的消息
}

@end

@implementation ACChatNetCenter

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sendingMessageArray = [[NSMutableArray alloc] initWithCapacity:10];
        _sendingMsgFromTCP = [[NSMutableArray alloc] initWithCapacity:10];

        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendingMessageArrayRemove:) name:kNetCenterSendMessageFailNotifation object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendingMessageArrayRemove:) name:kNetCenterSendMessageSuccessNotifation object:nil];
    }
    return self;
}


-(void)cancelNowSendingMessages{
    [_sendingMessageArray removeAllObjects];
    [_sendingMsgFromTCP removeAllObjects];
}


-(void)_sendMessageEnd:(ACMessage *)msg for:(NSString*)pForTip{
    ACMessage *message = nil;
    @synchronized(_sendingMessageArray){
        if(msg){
            [_sendingMessageArray removeObject:msg];
        }
        message =    _sendingMessageArray.firstObject;
    }
    if(message){
        ITLogEX(@"%@,发送下一个Msg[%d]:%@",pForTip,(int)_sendingMessageArray.count,message.messageID);
        [self _sendMessage_Func:message];
    }
    else{
        ITLogEX(@"%@,发送结束[%d]",pForTip,(int)_sendingMessageArray.count);
    }
}

//#pragma mark -notification
//
//
//-(void)sendingMessageArrayRemove:(NSNotification *)noti{
//    ACMessage *message = nil;
//    NSArray *array = noti.object;
//    if ([array count] == 2){
//        message =   [array objectAtIndex:0];
//    }
//    [self _sendMessageEnd:message];
//}

-(BOOL)messageIsSendingWithMessage:(ACMessage *)message
{
    @synchronized(_sendingMessageArray){
        for (ACMessage *msg in _sendingMessageArray){
            if ([msg.messageID isEqualToString:message.messageID]){
                return YES;
            }
        }
    }
    @synchronized(_sendingMsgFromTCP){
        for (ACMessage *msg in _sendingMsgFromTCP){
            if ([msg.messageID isEqualToString:message.messageID]){
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark -sendMessage

-(void)_sendMessage_Func:(ACMessage *)message{
    ITLogEX(@"发送Msg:%@",message.messageID);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if(ACMessageUploadState_Transmiting==message.messageUploadState){
//            [self _GCDTransmitMsg:message];
            [self _GCDSendNomalMessage:message];
            return;
        }
        
        switch (message.messageEnumType)
        {
            case ACMessageEnumType_Text:
            {
//                [self _GCDSendTextMessage:(ACTextMessage *)message];
                [self _GCDSendNomalMessage:message];
            }
                break;
            case ACMessageEnumType_Location:
            {
//                [self _GCDSendLocationMessage:(ACLocationMessage *)message];
                [self _GCDSendNomalMessage:message];
            }
                break;
            case ACMessageEnumType_Sticker:
            {
//                [self _GCDSendStickerMessage:(ACStickerMessage *)message];
                [self _GCDSendNomalMessage:message];
            }
                break;
            case ACMessageEnumType_Audio:
            {
                [self _GCDSendAudioMessage:(ACFileMessage *)message];
            }
                break;
            case ACMessageEnumType_Image:
            {
                [self _GCDSendImageMessage:(ACFileMessage *)message];
            }
                break;
            case ACMessageEnumType_Video:
            {
                [self _GCDSendVideoMessage:(ACFileMessage *)message];
            }
                break;
            case ACMessageEnumType_File:
            {
                [self _GCDSendFileMessage:(ACFileMessage *)message];
            }
                break;
            default:
                ITLogEX(@"居然不能发送(%d) %@",message.messageEnumType,message);
                break;
        }
    });
}

-(void)sendMessage:(ACMessage *)message{
    
    if(ACMessageUploadState_Transmiting!=message.messageUploadState){
        message.messageUploadState = ACMessageUploadState_Uploading;
       if(ACMessageEnumType_Video==message.messageEnumType){
            //视频特殊处理,直接发送,不进入队列
            [ACMessageDB saveMessageToDBWithMessage:message];
            [self _sendMessage_Func:message];
            return;
       }
    }
    
    
    if(ACMessageUploadState_Transmiting==message.messageUploadState||
//       ACMessageEnumType_Text==message.messageEnumType||
       ACMessageEnumType_Location==message.messageEnumType||
       ACMessageEnumType_Sticker==message.messageEnumType){
        
        @synchronized(_sendingMsgFromTCP){
            if(![_sendingMsgFromTCP containsObject:message]){
                [ACMessageDB saveMessageToDBWithMessage:message];
                [_sendingMsgFromTCP addObject:message];
            }
        };
        
        if([ACNetCenter sendMsgFromTCP_IsReady]){
            [self sendMsgFromTCP_CheckMsgNeedSend];
        }
        return;
    }

    
    @synchronized(_sendingMessageArray){
        if(![_sendingMessageArray containsObject:message]){
            [ACMessageDB saveMessageToDBWithMessage:message];
            [_sendingMessageArray addObject:message];
        }
        
        if(_sendingMessageArray.count>1){
            //正在发送中
            return;
        }
    }
    
    [self _sendMessage_Func:message];
}

+(void)resendMessageFail:(ACMessage *)message{
    if (message.messageUploadState == ACMessageUploadState_Uploading){
        message.messageUploadState = ACMessageUploadState_UploadFailed;
    }
    else if (message.messageUploadState == ACMessageUploadState_Transmiting){
        message.messageUploadState = ACMessageUploadState_TransmitFailed;
    }
    message.currentResendCount = 0;
    NSString *sourceMessageID = message.messageID;
    [ACMessageDB saveMessageToDBWithMessage:message];
    [ACUtility postNotificationName:kNetCenterSendMessageFailNotifation object:@[message,sourceMessageID]];
}

-(void)resendMessageFail:(ACMessage *)message{
    [ACChatNetCenter resendMessageFail:message];
    
#ifdef ACUtility_Need_Log
    [self _sendMessageEnd:message for:[NSString stringWithFormat:@"发送失败(%@)",message.messageID]];
#else
    [self _sendMessageEnd:message for:@"发送失败"];
#endif
}
+(void)sendMessage:(ACMessage *)message SuccessWithSourceMsgID:(NSString*)sourceMessageID{
    [ACUtility postNotificationName:kNetCenterSendMessageSuccessNotifation object:@[message,sourceMessageID]];
}

-(void)sendMessage:(ACMessage *)message SuccessWithSourceMsgID:(NSString*)sourceMessageID{
    [ACChatNetCenter sendMessage:message SuccessWithSourceMsgID:sourceMessageID];
#ifdef ACUtility_Need_Log
    [self _sendMessageEnd:message for:[NSString stringWithFormat:@"发送成功(%@)",sourceMessageID]];
#else
    [self _sendMessageEnd:message for:@"发送成功"];
#endif
}

-(void)sendMsgFromTCP_Success:(NSDictionary*)pResult{ //发送TCP成功
    @synchronized(_sendingMsgFromTCP){
        NSString* sourceMessageID = pResult[@"cid"];
        for (ACMessage *msg in _sendingMsgFromTCP){
            if ([msg.messageID isEqualToString:sourceMessageID]){
                [msg updateWithDic:pResult];
                [ACMessageDB saveMessageToDBWithMessage:msg];
                [ACChatNetCenter sendMessage:msg SuccessWithSourceMsgID:sourceMessageID];
                [_sendingMsgFromTCP removeObject:msg]; //一定放在这里，否则上一行会出现错误,msg可能为nil
                return;
            }
        }
    }
}


#define  resendMessage_Max_Count    4

-(void)sendMsgFromTCP_CheckMsgNeedSend{    //检查是否有信息需要发送
    @synchronized(_sendingMsgFromTCP){
        if(0==_sendingMsgFromTCP.count){
            return;
        }
        
        NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];

        for (NSInteger i=0;i<_sendingMsgFromTCP.count;i++){
            ACMessage *message =    _sendingMsgFromTCP[i];
            if (message.currentResendCount >= resendMessage_Max_Count){ //23
                [ACChatNetCenter resendMessageFail:message];
                [_sendingMsgFromTCP removeObjectAtIndex:i];
                i--;
            }
            else if((nowTime-message.timeForSendFromTCP)>30){ //超过30秒
                if(![ACNetCenter sendMsgFromTCP:message]){
                    return;
                }
                message.currentResendCount ++;
                message.timeForSendFromTCP = nowTime;
            }
        }
    };
}


-(void)resendMessage:(ACMessage *)message
{
    
    //消息重发,大概耗时2-3分钟
    static float resendTime[23] = {0.3, 1.0, 3.0, 5.0, 7.0, 10.0, 20.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0};
    if (message.currentResendCount < resendMessage_Max_Count) //23
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(resendTime[message.currentResendCount] * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
            ITLogEX(@"ResendCount(%d) %@",message.currentResendCount,message);
            [self _sendMessage_Func:message];
        });
        message.currentResendCount++;
    }
    else{
        [self resendMessageFail:message];
    }
}

+(NSDictionary*)getMsgSendDict:(ACMessage *)msg{
    if(ACMessageUploadState_Transmiting==msg.messageUploadState&&
       [msg isKindOfClass:[ACFileMessage class]]){
        ACFileMessage* pFileMsg = (ACFileMessage*)msg;
        NSMutableDictionary *contentDic = [NSMutableDictionary dictionaryWithDictionary:[msg.content objectFromJSONString]];
        NSString *filePath = [ACAddress getFileMsgAddressWithFileMsg:pFileMsg];
        long length = [ACUtility getFileSizeWithPath:filePath];
        if (length != 0){
            [contentDic setObject:[NSNumber numberWithLong:length] forKey:kLength];
            msg.content = [contentDic JSONString];
        }
        return [pFileMsg getTransmitDic];
    }
    
    return [msg getDic];
}

-(void)_GCDSendNomalMessage:(ACMessage *)msg{
//case ACFile_Type_SendText:
//case ACFile_Type_SendSticker:
//case ACFile_Type_SendLocation:
//case ACFile_Type_TransmitMsg:
    NSString * const acSendTextMessageUrl = kSendTextMessageUrl;
    [[ACNetCenter shareNetCenter] startDownloadWithFileName:nil
                                                   fileType:ACFile_Type_SendText
                                                  urlString:acSendTextMessageUrl
                                                saveAddress:nil
                                                tempAddress:nil
                                           progressDelegate:nil
                                             postDictionary:[ACChatNetCenter getMsgSendDict:msg]
                                              postPathArray:nil
                                                     object:msg
                                              requestMethod:requestMethodType_Post];
}

/*
-(void)_GCDSendTextMessage:(ACTextMessage *)textMessage
{
    NSString * const acSendTextMessageUrl = kSendTextMessageUrl;
    
    NSDictionary *postDic = [textMessage getDic];
    
    NSString *fileName = @"textMessage.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendText isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendText isTemp:YES subDirName:nil];
    [[ACNetCenter shareNetCenter] startDownloadWithFileName:fileName fileType:ACFile_Type_SendText urlString:acSendTextMessageUrl saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:postDic postPathArray:nil object:textMessage requestMethod:requestMethodType_Post];
}


-(void)_GCDSendLocationMessage:(ACLocationMessage *)locationMessage
{
    NSString * const acSendLocationMessageUrl = kSendTextMessageUrl;
    
    NSDictionary *postDic = [locationMessage getDic];
    
    NSString *fileName = @"locationMessage.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendLocation isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendLocation isTemp:YES subDirName:nil];
    [[ACNetCenter shareNetCenter] startDownloadWithFileName:fileName fileType:ACFile_Type_SendLocation urlString:acSendLocationMessageUrl saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:postDic postPathArray:nil object:locationMessage requestMethod:requestMethodType_Post];
}


-(void)_GCDSendStickerMessage:(ACStickerMessage *)stickerMessage
{
    NSString * const acSendStickerMessageUrl = kSendTextMessageUrl;
    
    NSDictionary *postDic = [stickerMessage getDic];
    
    NSString *fileName = @"stickerMessage.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendSticker isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendSticker isTemp:YES subDirName:nil];
    [[ACNetCenter shareNetCenter] startDownloadWithFileName:fileName fileType:ACFile_Type_SendSticker urlString:acSendStickerMessageUrl saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:postDic postPathArray:nil object:stickerMessage requestMethod:requestMethodType_Post];
}

-(void)_GCDTransmitMsg:(ACMessage *)msg{
    if ([msg isKindOfClass:[ACFileMessage class]]){
        NSMutableDictionary *contentDic = [NSMutableDictionary dictionaryWithDictionary:[msg.content objectFromJSONString]];
        NSString *filePath = [ACAddress getFileMsgAddressWithFileMsg:(ACFileMessage *)msg];
        long length = [ACUtility getFileSizeWithPath:filePath];
        if (length != 0){
            [contentDic setObject:[NSNumber numberWithLong:length] forKey:kLength];
            msg.content = [contentDic JSONString];
        }
    }
    
    
    NSString *url = [NSString stringWithFormat:@"%@/rest/apis/chat/topic",[[ACNetCenter shareNetCenter] acucomServer]];
    
    NSDictionary *postDic = [msg isKindOfClass:[ACFileMessage class]]?[(ACFileMessage *)msg getTransmitDic]:[msg getDic];
    [[ACNetCenter shareNetCenter] startDownloadWithFileName:nil
                                                   fileType:ACFile_Type_TransmitMsg
                                                  urlString:url
                                                saveAddress:nil
                                                tempAddress:nil
                                           progressDelegate:nil
                                             postDictionary:postDic
                                              postPathArray:nil
                                                     object:msg
                                              requestMethod:requestMethodType_Post];
}
*/

-(NSString *)_getFileUrlWithTopicEntityID:(NSString *)entityID type:(NSString *)type duration:(int)duration location:(CLLocationCoordinate2D)location
{
    NSString *urlString = [NSString stringWithFormat:@"%@/uploadex?type=%@",[ACNetCenter urlHead_ChatWithTopicID:entityID],type];
    if (duration)
    {
        urlString = [urlString stringByAppendingFormat:@"&duration=%d",duration];
    }
    if (location.latitude && location.longitude)
    {
        urlString = [urlString stringByAppendingFormat:@"&la=%lf&lo=%lf",location.latitude,location.longitude];
    }
    return urlString;
}



////发送image消息
//-(void)sendImageMessages:(NSArray *)imageMessages
//{
//    for(ACFileMessage* imageMessage in imageMessages){
//        [self sendMessage:imageMessage];
//    }
//}

-(void)_GCDSendImageMessage:(ACFileMessage *)imageMessage
{
    ITLogEX(@"Send Image MessageID= %@,ResendCount(%d)",imageMessage.messageID,imageMessage.currentResendCount);

    NSString * const acSendImageMessageUrl = [NSString stringWithFormat:@"%@/uploadex",[ACNetCenter urlHead_ChatWithTopicID:imageMessage.topicEntityID]];
    
    NSString *firstPath = [ACAddress getAddressWithFileName:imageMessage.resourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
    NSString *secondPath = [ACAddress getAddressWithFileName:imageMessage.thumbResourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
    
    NSArray *postPathArray = [NSArray arrayWithObjects:firstPath,secondPath, nil];
    
    NSDictionary *postDic = [imageMessage getDic];
    
    NSString *fileName = @"imageMessage.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendImage_Json isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendImage_Json isTemp:YES subDirName:nil];
    [[ACNetCenter shareNetCenter] startDownloadWithFileName:fileName fileType:ACFile_Type_SendImage_Json urlString:acSendImageMessageUrl saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:postDic postPathArray:postPathArray object:imageMessage requestMethod:requestMethodType_Post];
}

-(void)_GCDSendAudioMessage:(ACFileMessage *)audioMessage
{
    NSString * const acSendAudioMessageUrl = [self _getFileUrlWithTopicEntityID:audioMessage.topicEntityID type:audioMessage.messageType duration:audioMessage.duration location:audioMessage.messageLocation];
    
    NSString *firstPath = [ACAddress getAddressWithFileName:audioMessage.resourceID fileType:ACFile_Type_AudioFile isTemp:NO subDirName:nil];
    NSArray *postPathArray = [NSArray arrayWithObjects:firstPath, nil];
    
    NSDictionary *postDic = [audioMessage getDic];
    
    NSString *fileName = @"audioMessage.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendAudio_Json isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendAudio_Json isTemp:YES subDirName:nil];
    [[ACNetCenter shareNetCenter] startDownloadWithFileName:fileName fileType:ACFile_Type_SendAudio_Json urlString:acSendAudioMessageUrl saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:postDic postPathArray:postPathArray object:audioMessage requestMethod:requestMethodType_Post];
}


-(void)_GCDSendFileMessage:(ACFileMessage *)fileMessage
{
    
    NSString * const acSendAudioMessageUrl = [self _getFileUrlWithTopicEntityID:fileMessage.topicEntityID type:fileMessage.messageType duration:fileMessage.duration location:fileMessage.messageLocation];
    
    NSString *extension = [[[fileMessage name] componentsSeparatedByString:@"."] lastObject];
    NSString *firstPath = [ACAddress getAddressWithFileName:fileMessage.resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
    NSArray *postPathArray = [NSArray arrayWithObjects:firstPath, nil];
    
    NSDictionary *postDic = [fileMessage getDic];
    
    NSString *fileName = @"fileMessage.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendFile_Json isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendFile_Json isTemp:YES subDirName:nil];
    [[ACNetCenter shareNetCenter] startDownloadWithFileName:fileName fileType:ACFile_Type_SendFile_Json urlString:acSendAudioMessageUrl saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:postDic postPathArray:postPathArray object:fileMessage requestMethod:requestMethodType_Post];

    /*
    NSString * const acSendFileMessageUrl = [self getFileUrlWithTopicEntityID:fileMessage.topicEntityID type:fileMessage.messageType duration:fileMessage.duration location:fileMessage.messageLocation];
    
    NSString *firstPath = [ACAddress getAddressWithFileName:fileMessage.resourceID fileType:ACFile_Type_File isTemp:NO subDirName:nil];
    NSString *secondPath = [ACAddress getAddressWithFileName:fileMessage.thumbResourceID fileType:ACFile_Type_VideoThumbFile isTemp:NO subDirName:nil];
    NSArray *postPathArray = [NSArray arrayWithObjects:firstPath,secondPath, nil];
    
    NSDictionary *postDic = [videoMessage getDic];
    NSString *fileName = @"videoMessage.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendVideo_Json isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendVideo_Json isTemp:YES subDirName:nil];
    [[ACNetCenter shareNetCenter] startDownloadWithFileName:fileName fileType:ACFile_Type_SendVideo_Json urlString:acSendAudioMessageUrl saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:postDic postPathArray:postPathArray object:videoMessage requestMethod:requestMethodType_Post];*/
}




-(void)_GCDSendVideoMessage:(ACFileMessage *)videoMessage
{
    NSString * const acSendAudioMessageUrl = [self _getFileUrlWithTopicEntityID:videoMessage.topicEntityID type:videoMessage.messageType duration:videoMessage.duration location:videoMessage.messageLocation];
    
    NSString *firstPath = [ACAddress getAddressWithFileName:videoMessage.resourceID fileType:ACFile_Type_VideoFile isTemp:NO subDirName:nil];
    NSString *secondPath = [ACAddress getAddressWithFileName:videoMessage.thumbResourceID fileType:ACFile_Type_VideoThumbFile isTemp:NO subDirName:nil];
    NSArray *postPathArray = [NSArray arrayWithObjects:firstPath,secondPath, nil];
    
    NSDictionary *postDic = [videoMessage getDic];
    NSString *fileName = @"videoMessage.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendVideo_Json isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SendVideo_Json isTemp:YES subDirName:nil];
    [[ACNetCenter shareNetCenter] startDownloadWithFileName:fileName fileType:ACFile_Type_SendVideo_Json urlString:acSendAudioMessageUrl saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:postDic postPathArray:postPathArray object:videoMessage requestMethod:requestMethodType_Post];
}





@end
