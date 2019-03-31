//
//  ACTopicEntityEvent.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACEntityEvent.h"
#import "ACPermission.h"

@class ACTopicEntity;
@interface ACTopicEntityEvent : ACEntityEvent

//添加topicEntity,可创建，所以需要返回值
+(ACTopicEntity *)topicEntityEventAddEntityWithEventDic:(NSDictionary *)eventDic;

//删除topicEntity
+(void)topicEntityEventDeleteEntityWithEventDic:(NSDictionary *)eventDic;

//更新topicEntity
+(ACTopicEntity*)topicEntityEventUpdateEntityWithEventDic:(NSDictionary *)eventDic;

+(void)updateDidReadWithTopicEntity:(ACTopicEntity *)topicEntity;

+(void)UpdateEntityToArray:(NSMutableArray *)allEmtityArray entity:(ACBaseEntity *)entity;

@end
