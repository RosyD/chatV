//
//  ACUrlEntityEvent.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACEntityEvent.h"

@interface ACUrlEntityEvent : ACEntityEvent

//添加urlEntity,不可创建，所以没返回值
+(void)urlEntityEventAddEntityWithEventDic:(NSDictionary *)eventDic;

//删除urlEntity
+(void)urlEntityEventDeleteEntityWithEventDic:(NSDictionary *)eventDic;

//更新urlEntity
+(void)urlEntityEventUpdateEntityWithEventDic:(NSDictionary *)eventDic;

@end
