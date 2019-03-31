//
//  ACTopicEntityEvent.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACTopicEntityEvent.h"
#import "ACEntity.h"
#import "ACDataCenter.h"
#import "ACTopicEntityDB.h"
#import "ACNetCenter.h"
#import "ACMessage.h"
#import "ACVideoCall.h"


@implementation ACTopicEntityEvent

+(void)_updateTopicEntity:(ACTopicEntity *)topicEntity forMuteWithEvent:(NSDictionary *)eventDic{
    NSNumber* pMute =   [eventDic objectForKey:@"mute"]; //静音
    if(pMute){
        topicEntity.isTurnOffAlerts =   [pMute boolValue] ;
    }
}

//添加topicEntity,可创建，所以需要返回值
+(ACTopicEntity *)topicEntityEventAddEntityWithEventDic:(NSDictionary *)eventDic
{
    ACTopicEntity *topicEntity = [[ACTopicEntity alloc] initWithTopicDic:eventDic];
//    if ([topicEntity.title isEqualToString:@"SAAS"])
//    {
//        
//    }
    [ACTopicEntityEvent _updateTopicEntity:topicEntity forMuteWithEvent:eventDic];
    if ([topicEntity.mpType isEqualToString:cWallboard])
    {
        [ACDataCenter shareDataCenter].wallboardTopicEntity = topicEntity;
        [self UpdateEntityToArray:[ACDataCenter shareDataCenter].allEntityArray entity:topicEntity];
    }
    else{
        //如果将要添加的entityId对应已经存在则更新
        ACTopicEntity *entity = [[ACDataCenter shareDataCenter] findTopicEntity:topicEntity.entityID];
        if(entity){
            [entity updateWithDict:eventDic];
            //需要重新排序
            topicEntity = entity;
        }
      
        [self insertEntityToArray:[ACDataCenter shareDataCenter].topicEntityArray entity:topicEntity];
        [self insertEntityToArray:[ACDataCenter shareDataCenter].allEntityArray entity:topicEntity];
    }
    [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:topicEntity];
    return topicEntity;
}

+(void)UpdateEntityToArray:(NSMutableArray *)allEmtityArray entity:(ACBaseEntity *)entity
{
    //添加topicEntity，如果不存在则直接插入，存在则删除后插入
    for (int i = 0; i < [allEmtityArray count]; i++)
    {
        ACTopicEntity *entityT = [allEmtityArray objectAtIndex:i];
        if ([entityT isKindOfClass:[ACTopicEntity class]])
        {
            if ([entityT.entityID isEqualToString:entity.entityID])
            {
                [allEmtityArray removeObject:entityT];
                if ([entityT.title isEqualToString:@"SAAS"])
                {
                    
                }
                break;
            }
        }
    }
    [self insertEntityToArray:allEmtityArray entity:entity];
}

//删除topicEntity
+(void)topicEntityEventDeleteEntityWithEventDic:(NSDictionary *)eventDic
{
    NSString *teid = [eventDic objectForKey:kTeid];
    [ACTopicEntityDB deleteTopicEntityFromDBWithTopicEntityID:teid];
    if ([teid isEqualToString:[ACDataCenter shareDataCenter].wallboardTopicEntity.entityID])
    {
        [ACDataCenter shareDataCenter].wallboardTopicEntity = nil;
        NSMutableArray *allArray = [ACDataCenter shareDataCenter].allEntityArray;
        for (int i = 0; i < [allArray count]; i++)
        {
            ACTopicEntity *topicEntity = [allArray objectAtIndex:i];
            if ([topicEntity isKindOfClass:[ACTopicEntity class]])
            {
                if ([topicEntity.entityID isEqualToString:teid])
                {
                    [allArray removeObject:topicEntity];
                    [[ACDataCenter shareDataCenter] entityTops_remove:topicEntity.entityID];
                    return;
                }
            }
        }
        return;
    }
    
    [ACVideoCall removetopicEntity:teid];
    
    ACTopicEntity *topicEntity = [[ACDataCenter shareDataCenter] findTopicEntity:teid];
    if(topicEntity){
        [[ACDataCenter shareDataCenter].topicEntityArray removeObject:topicEntity];
        [[ACDataCenter shareDataCenter].allEntityArray removeObject:topicEntity];
        [[ACDataCenter shareDataCenter] entityTops_remove:topicEntity.entityID];
    }
    
    [ACUtility postNotificationName:kNetCenterTopicEntityDeleteNotifation object:teid];
}

//更新topicEntity
+(ACTopicEntity*)topicEntityEventUpdateEntityWithEventDic:(NSDictionary *)eventDic
{
    NSString *teid = [eventDic objectForKey:kTeid];
    if ([[ACDataCenter shareDataCenter].wallboardTopicEntity.entityID isEqualToString:teid])
    {
        [[ACDataCenter shareDataCenter].wallboardTopicEntity updateWithDict:eventDic];
        [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:[ACDataCenter shareDataCenter].wallboardTopicEntity];
        return nil;
    }
    
    NSMutableArray *topicEntityArray = [ACDataCenter shareDataCenter].topicEntityArray;
    ACTopicEntity *topicEntity = (ACTopicEntity*)[ACDataCenter findEntify:teid inArray:topicEntityArray];
    if(topicEntity){
        [ACTopicEntityEvent _updateTopicEntity:topicEntity forMuteWithEvent:eventDic];
        [topicEntity updateWithDict:eventDic];
        [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:topicEntity];
        [self insertEntityToArray:topicEntityArray entity:topicEntity];
        [self insertEntityToArray:[ACDataCenter shareDataCenter].allEntityArray entity:topicEntity];
        return topicEntity;
    }
    
    return nil;
}

+(void)updateDidReadWithTopicEntity:(ACTopicEntity *)topicEntity
{
    topicEntity.currentSequence = topicEntity.lastestSequence;
    //写到数据库
    [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:topicEntity];
    [[ACConfigs shareConfigs] updateApplicationUnreadCount];
}

@end
