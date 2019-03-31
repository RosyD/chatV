//
//  ACEntityEvent.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACEntityEvent.h"
#import "ACTopicEntityEvent.h"
#import "ACNetCenter.h"
#import "ACUrlEntityEvent.h"
#import "ACMessageEvent.h"
#import "ACEntity.h"
#import "ACReadEvent.h"
#import "ACLBSCenter.h"
#import "ACLocationAlert.h"
#import "ACLocationSettingViewController.h"
#import "ACVideoCall.h"
#import "ACDataCenter.h"
#import "JHNotificationManager.h"
#import "ACNoteMessage.h"
#import "ACNoteDetailVC.h"
#import "ACTopicEntityDB.h"
#import "ACNetCenter.h"


extern  NSString*  const shareLocalNotifyForUserInfoChangeEvent;

@implementation ACEntityEvent

#define kCommandType    @"commandType"
#define kEventTime      @"eventTime"
#define kEventType      @"eventType"
#define kEventUid       @"eventUid"

- (id)initWithEntityEventDic:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        self.commandType = [dic objectForKey:kCommandType];
        self.eventTime = [[dic objectForKey:kEventTime] doubleValue];
        self.eventType = [[dic objectForKey:kEventType] intValue];
        self.eventUid = [dic objectForKey:kEventUid];
        self.setCid = [dic objectForKey:kSetCid];
    }
    return self;
}

//处理Entity事件,,返回是否需要更新最新的消息
+(ACTopicEntity*)handleEventOperateWithEventDic:(NSDictionary *)eventDic  forSync:(BOOL)bForSync
{
    ACTopicEntity* pRet = nil;
    ACEntityEvent *event = [[ACEntityEvent alloc] initWithEntityEventDic:eventDic];
    switch (event.eventType)
    {
        case EntityEventType_AddTopicEntity:
        {
            pRet    =   [ACTopicEntityEvent topicEntityEventAddEntityWithEventDic:eventDic];
//            [ACNetCenter downloadLastestMessageWithTopicEntity:[ACTopicEntityEvent topicEntityEventAddEntityWithEventDic:eventDic]];
        }
            break;
        case EntityEventType_UpdateTopicEntity:
        {
            pRet    =   [ACTopicEntityEvent topicEntityEventUpdateEntityWithEventDic:eventDic];
//            [ACNetCenter downloadLastestMessageWithTopicEntity:[ACTopicEntityEvent topicEntityEventUpdateEntityWithEventDic:eventDic]];
        }
            break;
        case EntityEventType_DeleteTopicEntity:
        {
            [ACTopicEntityEvent topicEntityEventDeleteEntityWithEventDic:eventDic];
        }
            break;
        case EntityEventType_AddTopic:
        {
            [ACMessageEvent messageAddWithDic:eventDic];
        }
            break;
        case EntityEventType_TopicRead:
        {
            [ACReadEvent updateReadSeqEventWithDic:eventDic];
        }
            break;
        case EntityEventType_RequestLocation:
        {
//            if ([[ACLBSCenter shareLBSCenter] userAllowLocation])
//            {
//                [[ACLBSCenter shareLBSCenter] locationAlertWithDic:eventDic];
//            }
            [ACLBSCenter locationAlertWithDic:eventDic];
        }
            break;
        case EntityEventType_PersonInfoUpdate:
        {
            [[ACConfigs shareConfigs] savePersonInfoWithUserDic:eventDic];
        }
            break;
        case EntityEventType_AddUrlEntity:
        {
            [ACUrlEntityEvent urlEntityEventAddEntityWithEventDic:eventDic];
        }
            break;
        case EntityEventType_UpdateUrlEntity:
        {
            [ACUrlEntityEvent urlEntityEventUpdateEntityWithEventDic:eventDic];
        }
            break;
        case EntityEventType_DeleteUrlEntity:
        {
            [ACUrlEntityEvent urlEntityEventDeleteEntityWithEventDic:eventDic];
        }
            break;
        case EntityEventType_Command:
        {
            if ([event.commandType isEqualToString:@"sync"])
            {
                [ACNetCenter shareNetCenter].cancelID = event.setCid;
                [[ACNetCenter shareNetCenter] syncData];
            }
        }
            break;
        default:
            break;
    }
    
    switch (event.eventType)
    {
        case EntityEventType_AddTopicEntity:
        case EntityEventType_UpdateTopicEntity:
        case EntityEventType_DeleteTopicEntity:
        {
            [ACUtility postNotificationName:kNetCenterUpdateTopicEntityInfoNotifation object:@(event.eventType)];
        }
            break;
        case EntityEventType_AddUrlEntity:
        case EntityEventType_UpdateUrlEntity:
        case EntityEventType_DeleteUrlEntity:
        {
            [ACUtility postNotificationName:kNetCenterUpdateUrlEntityInfoNotifation object:nil];
        }
            break;
        case EntityEventType_Note_Readed:
        {
            //通过通道收到Note已读事件， 如果updateTime大于currentNoteTime， 则赋值给currentNoteTime。 如果lateNoteTime小于currentNoteTime， 就在小铃铛上取消掉红点。
            NSNumber* pNoteTime =   [eventDic objectForKey:@"noteTime"];
            if(pNoteTime){
                [[ACConfigs shareConfigs] chageNoteLastTime:-1L andCurTime:[pNoteTime longLongValue]];
            }
        }
            break;
        case EntityEventType_Note_New:
        case EntityEventType_Note_Comment:
        {
            //收到新增Note或新增Comment事件时， 判断如果updateTime大于latestNoteTime， 就赋值给latestNoteTime。 如果lateNoteTime大于currentNoteTime， 就在小铃铛上显示红点。
            NSDictionary* pNoteOrComment = [eventDic objectForKey:EntityEventType_Note_New==event.eventType?@"n":@"c"];
            if(pNoteOrComment){
                NSNumber* pUpdateTime  =   [pNoteOrComment objectForKey:@"updateTime"];
                if(pUpdateTime){
                    [[ACConfigs shareConfigs] chageNoteLastTime:[pUpdateTime longLongValue] andCurTime:-1L];
                }
            }
            
            
            if(EntityEventType_Note_Comment==event.eventType&&
               [ACConfigs notificationCfgIsOn:NotificationCfg_ON|NotificationCfg_CommentBannerOn]&&
               ACNoteObject_Type_Comment==[[pNoteOrComment objectForKey:@"type"] intValue]){
                ACNoteComment* pObj = [[ACNoteComment alloc] initWithDict:pNoteOrComment];
                if(!pObj.creator.isMyself){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ACTopicEntity* pTopic = [[ACDataCenter shareDataCenter] findTopicEntity:pObj.teid];
                        if(pTopic&&(!pTopic.isTurnOffAlerts)){
                            [JHNotificationManager notificationWithMessage:pObj.contentForNotify
                                                          withUserInfo:@{JHNotification_UserInfo_topicID:pObj.teid,JHNotification_UserInfo_noteID:pObj.noteId}];
                        }
                    });
                }
            }
            
        }
            break;
        case EntityEventType_Video_Call:
        {
            [[ACVideoCall shareVideoCall] onVideoCallEvent:event.eventType withDict:eventDic];
        }
            break;
        case EntityEventType_Video_Call_Reject:
        case EntityEventType_Video_Call_SenderClose:
        case EntityEventType_Video_Call_Accept_On_OtherDevice:
        {
            [[ACVideoCall shareVideoCall] onVideoCallEvent:event.eventType withDict:eventDic];
        }
            break;
            
        case EntityEventType_ShareLocationEvent:
        {
            ACTopicEntity* pTopic = [[ACDataCenter shareDataCenter] findTopicEntity:eventDic[kTeid]];
            if(pTopic){
                [pTopic setSharingLocalUserCountAndSaveToDB:[eventDic[@"userCount"] intValue]];
                [ACUtility postNotificationName:shareLocalNotifyForUserInfoChangeEvent object:eventDic];
            }
        }
            break;
            
        case EntityEventType_WEBRTC_Call:     //event.webRTCStart
        case EntityEventType_WEBRTC_Cancelled: //event.webRTCCancelled
            [[ACVideoCall shareVideoCall] onVideoCallEvent:event.eventType withDict:eventDic];
            break;
        case EntityEventType_WEBRTC_Rejected: //event.webRTCRejected
        case EntityEventType_WEBRTC_Answered: //event.webRTCAnswered
            ITLog(event.eventType==EntityEventType_WEBRTC_Rejected?@"EntityEventType_WEBRTC_Rejected":@"EntityEventType_WEBRTC_Answered");
            
            ITLogEX(@"%@",eventDic);
            
            [ACUtility postNotificationName:kNetCenterWebRTC_Notifition
                                                                object:@{kNetCenterWebRTC_Notifition_type:@(event.eventType),
                                                                         kNetCenterWebRTC_Notifition_info:eventDic}];
            break;
            
        default:
            break;
    }
    return pRet;
}

//根据updateTime将entity插入到entityArray的合适位置
+(void)insertEntityToArray:(NSMutableArray *)entityArray entity:(ACBaseEntity *)entity
{
/*    if ([entity isKindOfClass:[ACTopicEntity class]] && [((ACTopicEntity *)entity).title isEqualToString:@"SAAS"])
    {
        
    }*/
    
    //空的话不走循环直接添加到array中
    if ([entityArray count] == 0)
    {
        //设置置顶
        entity.isToped = [[ACDataCenter shareDataCenter] entityTops_find:entity.entityID]>=0;
        
        [entityArray addObject:entity];
        return;
    }
    
    
    __strong ACBaseEntity *entityTmp = nil;
    if ([entityArray containsObject:entity])
    {
        if(entity.isToped){
            //已经置顶了，就根据时间排序了
            return;
        }
        entityTmp = entity;
        [entityArray removeObject:entity];
    }
    
    //topicEntity用lastestMsgTime
    NSTimeInterval sortUseTime = 0;
    if ([entity isKindOfClass:[ACTopicEntity class]])
    {
        sortUseTime = ((ACTopicEntity *)entity).lastestMessageTime;
    }
    //urlEntity用updateTime
    else if ([entity isKindOfClass:[ACUrlEntity class]])
    {
        sortUseTime = ((ACTopicEntity *)entity).updateTime;
    }
    
    for (int i = 0; i < [entityArray count]; i++)
    {
        ACBaseEntity *entityTmp = [entityArray objectAtIndex:i];
        if(entityTmp.isToped){
            //置顶不比较
            continue;
        }
        
        NSTimeInterval sortUseTimeTmp = 0;
        if ([entityTmp isKindOfClass:[ACTopicEntity class]])
        {
            sortUseTimeTmp = ((ACTopicEntity *)entityTmp).lastestMessageTime;
        }
        else if ([entityTmp isKindOfClass:[ACUrlEntity class]])
        {
            sortUseTimeTmp = ((ACTopicEntity *)entityTmp).updateTime;
        }
        
        if (sortUseTimeTmp < sortUseTime)
        {
            if (entity == nil)
            {
                
            }
            [entityArray insertObject:entity atIndex:i];
            break;
        }
    }
    if (![entityArray containsObject:entity])
    {
        [entityArray addObject:entity];
    }
}

@end
