//
//  ACMessageEvent.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-11.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACMessageEvent.h"
#import "ACMessage.h"
#import "ACDataCenter.h"
#import "ACEntity.h"
#import "ACUser.h"
#import "ACUserDB.h"
#import "ACNetCenter.h"
#import "ACConfigs.h"
#import "ACMessageDB.h"
#import "ACEntityEvent.h"
#import "ACTopicEntityDB.h"
#import "ACChatMessageViewController.h"
#import "ACNetCenter.h"
#import "ACConfigs.h"
#import "JHNotificationManager.h"

NSString *const kMessageAddNotification = @"kMessageAddNotification";

@implementation ACMessageEvent

//添加message
+(void)messageAddWithDic:(NSDictionary *)dic
{
    NSDictionary *messageDic = [dic objectForKey:@"t"];

    //创建topic对象
    ACMessage *message = [ACMessage messageWithDic:messageDic];
//    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:kUserID];
    BOOL turnsOffAlerts = NO;
    for (ACTopicEntity *entity in [ACDataCenter shareDataCenter].topicEntityArray)
    {
        if ([entity.entityID isEqualToString:message.topicEntityID])
        {
            turnsOffAlerts = entity.isTurnOffAlerts;
            if (entity.topicPerm.destruct == ACTopicPermission_DestructMessage_Deny){
                //不是阅后即焚
                [ACMessageDB saveMessageToDBWithMessage:message];
            }

            if ([ACUser isMySelf:message.sendUserID]){
                [self updateTopicEntity:entity LastInfoWithMessage:message hadRead:YES];
                
#if TARGET_IPHONE_SIMULATOR
                if(entity.lastestTextMessage.length)
                {
                    [JHNotificationManager notificationWithMessage:entity.lastestTextMessage
                                                      withUserInfo:entity.entityID];
                }
#endif
            }
            else
            {
                [self updateTopicEntity:entity LastInfoWithMessage:message hadRead:NO];
//        if (![ACNetCenter shareNetCenter].isForeground)
                if(entity.lastestTextMessage.length&&
                   (!entity.isTurnOffAlerts)&&
                   [ACConfigs notificationCfgIsOn:NotificationCfg_ON|NotificationCfg_BannerOn])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString* pTip = entity.lastestTextMessage;
                        UIViewController* topView = [ACConfigs getTopViewController];
                        if([topView isKindOfClass:[ACChatMessageViewController class]]){
                            ACChatMessageViewController* chatMsgVC = (ACChatMessageViewController*)topView;
                            if([chatMsgVC.topicEntity.entityID isEqualToString:entity.entityID]){
                                //就在当前页
                                pTip = nil;
                            }
                        }
                        
                        if(pTip&&ACTopicPermission_DestructMessage_Deny!=entity.topicPerm.destruct){
                            ACUser *user = [ACUserDB getUserFromDBWithUserID:entity.lastestMessageUserID];
                            if(user){
                                pTip = [NSString stringWithFormat:NSLocalizedString(@"New message from %@", nil),user.name];
                            }else{
                                pTip = nil;
                            }
                        }
                        
                        if(pTip){
                            [JHNotificationManager notificationWithMessage:pTip
                                                              withUserInfo:@{JHNotification_UserInfo_topicID:entity.entityID}];
                        }
                    });
                    
//                    enum ACMessageEnumType type = [ACMessage getMessageEnumTypeWithMessageType:message.messageType];
//                    NSString *content = [message isKindOfClass:[ACTextMessage class]]?((ACTextMessage *)message).content:@"";

                    //发送通知
//                    UILocalNotification *notification = [[UILocalNotification alloc] init];
//                    notification.alertBody = entity.lastestTextMessage;
////                    notification.alertAction = @"哈哈";
//                    notification.soundName = turnsOffAlerts?nil:UILocalNotificationDefaultSoundName;
//                    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
                }
            }

            break;
        }
    }


    [ACUtility postNotificationName:kMessageAddNotification object:message];

    if ((!turnsOffAlerts) && (![ACUser isMySelf:message.sendUserID]))
    {
        if([ACConfigs notificationCfgIsOn:NotificationCfg_ON]){
        //播放声音，震动
            if ([ACConfigs notificationCfgIsOn:NotificationCfg_SoundOn]){
                [[ACConfigs shareConfigs] newMessageSoundPlay];
            }
            else{
                [ACConfigs shareConfigs].player = nil;
            }
            if ([ACConfigs notificationCfgIsOn:NotificationCfg_VibarteOn]){
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            }
        }
        else{
            [ACConfigs shareConfigs].player = nil;
        }
    }
}

//+(void)updateTopicEntityHadReadWithMessage:(ACMessage *)message
//{
//    __strong ACTopicEntity *entityTmp = nil;
//    //修改对应的topicEntity对象
//    for (ACTopicEntity *entity in [ACDataCenter shareDataCenter].topicEntityArray)
//    {
//        if ([entity.entityID isEqualToString:message.topicEntityID])
//        {
//            long hadReadSeq = entityTmp.lastestSequence > message.seq?message.seq:entityTmp.lastestSequence;
//            entityTmp.currentSequence = hadReadSeq;
//            if (entity.perm.destruct == ACTopicPermission_DestructMessage_Allow)
//            {
//                entity.lastestTextMessage = nil;
//            }
//            
//            entityTmp = entity;
//            break;
//        }
//    }
//    
//    if (entityTmp)
//    {
//        //写到数据库
//        [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:entityTmp];
//    }
//    
//    [[ACConfigs shareConfigs] updateApplicationUnreadCount];
//}

+(void)updateTopicEntity:(ACTopicEntity *)entity LastInfoWithMessage:(ACMessage *)message hadRead:(BOOL)hadRead
{
    if(nil==entity){
        for (ACTopicEntity *entityTemp in [ACDataCenter shareDataCenter].topicEntityArray) {
            if ([entityTemp.entityID isEqualToString:message.topicEntityID]){
                entity = entityTemp;
                break;
            }
        }
        if(nil==entity){
            return;
        }
    }

    /*test*/
    if ([entity.mpType isEqualToString:cWallboard])
    {

    }
    /*test*/
    entity.lastestMessageTime = message.createTime;
    entity.updateTime = message.createTime;
    entity.lastestMessageType = message.messageType;
    entity.lastestMessageUserID = message.sendUserID;
    entity.lastestSequence = message.seq;
    if (hadRead)
    {
        entity.currentSequence = message.seq;
    }
    if (entity.topicPerm.destruct == ACTopicPermission_DestructMessage_Allow && hadRead)
    {
        entity.lastestTextMessage = nil;
    }
    else{
        enum ACMessageEnumType type = [ACMessage getMessageEnumTypeWithMessageType:message.messageType];
        NSString *content = [message isKindOfClass:[ACTextMessage class]]?((ACTextMessage *)message).content:@"";
        entity.lastestTextMessage = [self getLasestTextMessageWithMessageType:type
                                                                      content:content
                                                                       userID:entity.lastestMessageUserID
                                                                     userName:nil
                                                                    topicType:entity.mpType
                                                            TopicDestructType:entity.topicPerm.destruct];
    }

    //未读数更新
    if (hadRead)
    {
//        long hadReadSeq = entity.lastestSequence > message.seq?message.seq:entity.lastestSequence;
//        entity.currentSequence = hadReadSeq;
        entity.currentSequence =    MIN(entity.lastestSequence,message.seq);
    }
//    [ACUtility postNotificationName:kUpdateUnReadCountNotification object:nil];
    
    //写到数据库
    [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:entity];

    //写到内存
    [ACEntityEvent insertEntityToArray:[ACDataCenter shareDataCenter].topicEntityArray entity:entity];
    [ACEntityEvent insertEntityToArray:[ACDataCenter shareDataCenter].allEntityArray entity:entity];

    [[ACConfigs shareConfigs] updateApplicationUnreadCount];
}




+(NSString *)getLasestTextMessageWithMessageType:(int)type
                                         content:(NSString *)content
                                          userID:(NSString *)userID
                                        userName:(NSString *)userName
                                       topicType:(NSString *)mpType
                               TopicDestructType:(int)destructType
{
    if(destructType!=ACTopicPermission_DestructMessage_Deny){
        return NSLocalizedString(@"Secret chat", nil);
    }
    
    BOOL isSelfSend = NO;
    NSString *name = userName;
    if([mpType isEqualToString:cSystemChat]) {
        name    =   NSLocalizedString(@"System", nil);
    }
    else {
        isSelfSend = [ACUser isMySelf:userID];

        if (0 == userName.length) {
            if (0 == userID.length) {
                return nil;
            }
            ACUser *user = [ACUserDB getUserFromDBWithUserID:userID];
            name = user.name;
            if (name.length == 0) {
                name = @"";
                if (!isSelfSend) {
                    return nil;
                }
                ITLog(([NSString stringWithFormat:@"%@ %@", userID, user.name]));
            }
        }
    }

    if (![content isKindOfClass:[NSString class]])
    {
        content = nil;
    }
    if (type == ACMessageEnumType_Text && [content length] == 0)
    {
        return @"";
    }

    NSString *lastestTextMessage = nil;
    switch (type)
    {
        case ACMessageEnumType_Text:
        {
            lastestTextMessage = isSelfSend?[NSString stringWithFormat:@"%@",content]:[NSString stringWithFormat:@"%@: %@",name,content];
        }
            break;
        case ACMessageEnumType_ShareLocation:
        case ACMessageEnumType_Videocall:
        case ACMessageEnumType_Audiocall:
        {
            lastestTextMessage  =   content;
        }
            break;
            
        case ACMessageEnumType_Location:
        {
            lastestTextMessage = isSelfSend?NSLocalizedString(@"You sent a location", nil):[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Location from", nil),name];
        }
            break;
        case ACMessageEnumType_Sticker:
        {
            lastestTextMessage = isSelfSend?NSLocalizedString(@"You sent a sticker", nil):[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Sticker from", nil),name];
        }
            break;
        case ACMessageEnumType_Audio:
        {
            lastestTextMessage = isSelfSend?NSLocalizedString(@"You sent an audio", nil):[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Audio from", nil),name];
        }
            break;
        case ACMessageEnumType_Image:
        {
            lastestTextMessage = isSelfSend?NSLocalizedString(@"You sent a image", nil):[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Image from", nil),name];
        }
            break;
        case ACMessageEnumType_Video:
        {
            lastestTextMessage = isSelfSend?NSLocalizedString(@"You sent a video", nil):[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Video from", nil),name];
        }
            break;
        case ACMessageEnumType_File:
        {
            lastestTextMessage = isSelfSend?NSLocalizedString(@"You sent a file", nil):[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"File from", nil),name];
        }
            break;
        case ACMessageEnumType_System:
        {
            lastestTextMessage  =   content;
        }
            break;
        case ACMessageEnumType_Unknow:
        {
            lastestTextMessage  =   NSLocalizedString(@"Unsupported message type for current version.", nil);
        }
            break;
        default:
        {
            lastestTextMessage = @"";
        }
            break;
    }
    return lastestTextMessage;
}

@end
