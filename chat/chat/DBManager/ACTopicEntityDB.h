//
//  ACTopicEntityDB.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACTopicEntity;
@interface ACTopicEntityDB : NSObject

+(BOOL)createTable:(NSInteger)nDB_Ver;

+(void)dropTable;

+(BOOL)saveTopicEntityToDBWithTopicEntity:(ACTopicEntity *)topicEntity;//先select，有update，没有insert

//删除topicEntity
+(BOOL)deleteTopicEntityFromDBWithTopicEntityID:(NSString *)topicEntityID;

//获取topicEntityList
+(NSMutableArray *)getTopicEntityListFromDB;



//runtimeInfo nNo:(1-4) 1:草稿
+(NSString*)loadTopicEntity:(ACTopicEntity *)topicEntity runtimeInfoIndex:(int)nNo;
+(void)saveTopicEntity:(ACTopicEntity *)topicEntity runtimeInfo:(NSString*)pInfo withIndexNo:(int)nNo;

@end


//草稿
#define ACTopicEntityDB_TopicEntityDraft_save(topic_____Entity,p____Info)\
    [ACTopicEntityDB saveTopicEntity:(topic_____Entity) runtimeInfo:p____Info withIndexNo:1]

#define ACTopicEntityDB_TopicEntityDraft_load(topic_____Entity)\
    [ACTopicEntityDB loadTopicEntity:(topic_____Entity) runtimeInfoIndex:1]

/*
//位置共享 runtimeInfoIndex:2
#define ACTopicEntityDB_TopicEntityShareLocation_save(topic_____Entity)\
    [ACTopicEntityDB saveTopicEntity:(topic_____Entity) runtimeInfo:[@(topic_____Entity.nSharingLocalUserCount) stringValue] withIndexNo:2]

#define ACTopicEntityDB_TopicEntityShareLocation_load(topic_____Entity)\
    topic_____Entity.nSharingLocalUserCount = [[ACTopicEntityDB loadTopicEntity:(topic_____Entity) runtimeInfoIndex:2] intValue]*/
