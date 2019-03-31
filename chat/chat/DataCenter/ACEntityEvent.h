//
//  ACEntityEvent.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

enum EntityEventType
{
    EntityEventType_AddTopicEntity = 1,
    EntityEventType_UpdateTopicEntity = 2,
    EntityEventType_DeleteTopicEntity = 3,
    EntityEventType_AddTopic = 11,
    EntityEventType_DeleteTopic = 12,
    EntityEventType_TopicRead = 21,
    EntityEventType_PartTicipant = 31,
    EntityEventType_UserGroup = 41,
    EntityEventType_RequestLocation = 42,
    EntityEventType_PersonInfoUpdate = 45,
    EntityEventType_AddUrlEntity = 51,
    EntityEventType_UpdateUrlEntity = 52,
    EntityEventType_DeleteUrlEntity = 53,
    EntityEventType_Command = 61,//同步数据
    EntityEventType_Note_Readed = 81, //自己的已读Note或Comment事件
    EntityEventType_Note_New = 82,  //新增Note事件
    EntityEventType_Note_Comment = 83, //新增Comment事件
    EntityEventType_Video_Call = 91,//邀请加入会议事件
    EntityEventType_Video_Call_Reject = 92, //拒绝
    EntityEventType_Video_Call_SenderClose=93, //主叫拒绝
    EntityEventType_Video_Call_Accept_On_OtherDevice = 94, //呼叫已应同账户的两个终端被同时呼叫， 一端应答（拒绝或者接听）， 另外一端会收到这个事件
    
    EntityEventType_ShareLocationEvent = 101, //
    
    
    
    EntityEventType_WEBRTC_Call = 201,     //event.webRTCStart
    EntityEventType_WEBRTC_Rejected = 202, //event.webRTCRejected
    EntityEventType_WEBRTC_Cancelled = 203, //event.webRTCCancelled
    EntityEventType_WEBRTC_Answered = 204, //event.webRTCAnswered
    
};

@class ACBaseEntity;
@class ACTopicEntity;
@interface ACEntityEvent : NSObject

@property (nonatomic) int                   eventType;
@property (nonatomic,strong) NSString       *commandType;
@property (nonatomic,strong) NSString       *eventUid;
@property (nonatomic) NSTimeInterval        eventTime;
@property (nonatomic,strong) NSString       *setCid;

- (id)initWithEntityEventDic:(NSDictionary *)dic;

//处理Entity事件,返回是否需要更新TopicEntity最新的消息
+(ACTopicEntity*)handleEventOperateWithEventDic:(NSDictionary *)eventDic forSync:(BOOL)bForSync;

//根据updateTime将entity插入到entityArray的合适位置
+(void)insertEntityToArray:(NSMutableArray *)entityArray entity:(ACBaseEntity *)entity;

@end
