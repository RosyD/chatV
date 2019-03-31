//
//  ACUrlEntityEvent.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACUrlEntityEvent.h"
#import "ACEntity.h"
#import "ACDataCenter.h"
#import "ACUrlEntityDB.h"

#define kUeid   @"ueid"

@implementation ACUrlEntityEvent

//添加urlEntity,不可创建，所以没返回值
+(void)urlEntityEventAddEntityWithEventDic:(NSDictionary *)eventDic
{
    ACUrlEntity *urlEntity = [[ACUrlEntity alloc] initWithUrlEventDic:eventDic];
    NSMutableArray *allEmtityArray = [ACDataCenter shareDataCenter].allEntityArray;
    NSMutableArray *urlEmtityArray = [ACDataCenter shareDataCenter].urlEntityArray;
    
    //如果将要添加的entityId对应已经存在则更新
    for (ACUrlEntity *entity in urlEmtityArray)
    {
        if ([entity.entityID isEqualToString:urlEntity.entityID])
        {
            [entity updateEntityWithEventDic:eventDic];
            [ACUrlEntityDB saveUrlEntityToDBWithUrlEntity:entity];
            return;
        }
    }
    
    [ACUrlEntityDB saveUrlEntityToDBWithUrlEntity:urlEntity];
    [self insertEntityToArray:urlEmtityArray entity:urlEntity];
    [self insertEntityToArray:allEmtityArray entity:urlEntity];
}

//删除urlEntity
+(void)urlEntityEventDeleteEntityWithEventDic:(NSDictionary *)eventDic
{
    NSString *ueid = [eventDic objectForKey:kUeid];
    
    NSMutableArray *urlArray = [ACDataCenter shareDataCenter].urlEntityArray;
    NSMutableArray *allArray = [ACDataCenter shareDataCenter].allEntityArray;
    for (int i = 0; i < [urlArray count]; i++)
    {
        ACUrlEntity *urlEntity = [urlArray objectAtIndex:i];
        if ([urlEntity.entityID isEqualToString:ueid])
        {
            [ACUrlEntityDB deleteUrlEntityFromDBWithUrlEntityID:urlEntity.entityID];
            [urlArray removeObject:urlEntity];
            [allArray removeObject:urlEntity];
            break;
        }
    }
}

//更新urlEntity
+(void)urlEntityEventUpdateEntityWithEventDic:(NSDictionary *)eventDic
{
    NSString *ueid = [eventDic objectForKey:kUeid];
    
    NSMutableArray *allEmtityArray = [ACDataCenter shareDataCenter].allEntityArray;
    NSMutableArray *urlEmtityArray = [ACDataCenter shareDataCenter].urlEntityArray;
    for (int i = 0; i < [urlEmtityArray count]; i++)
    {
        ACUrlEntity *urlEntity = [urlEmtityArray objectAtIndex:i];
        if ([urlEntity.entityID isEqualToString:ueid])
        {
            [urlEntity updateEntityWithEventDic:eventDic];
            [ACUrlEntityDB saveUrlEntityToDBWithUrlEntity:urlEntity];
            [self insertEntityToArray:urlEmtityArray entity:urlEntity];
            [self insertEntityToArray:allEmtityArray entity:urlEntity];
            break;
        }
    }
}

@end
