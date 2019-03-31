//
//  ACTopicEntity.m
//  chat
//
//  Created by 李朝霞 on 2017/2/17.
//  Copyright © 2017年 李朝霞. All rights reserved.
//

#import "ACTopicEntity.h"
#import "ACDBManager.h"

@implementation ACTopicEntity

+(BOOL)createTable:(NSInteger)nDB_Ver
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"CREATE TABLE IF NOT EXISTS topicEntity ("\
                        "entityID TEXT PRIMARY KEY, "\
                        "updateTime DOUBLE, "\
                        "lastestSequence INTEGER, "\
                        "entityType INTEGER, "\
                        "title TEXT, "\
                        "icon TEXT, "\
                        "mpType TEXT, "\
                        "url TEXT, "\
                        "createTime DOUBLE, "\
                        "permString TEXT, "\
                        "currentSequence INTEGER, "\
                        "isAdmin INTEGER, "\
                        "lastestTextMessage TEXT, "\
                        "lastestMessageType TEXT, "\
                        "lastestMessageTime DOUBLE, "\
                        "lastestMessageUserID TEXT, "\
                        "singleChatUserID TEXT, "\
                        "relateTeID TEXT, "\
                        "relateType TEXT, "\
                        "relateChatUserID TEXT, "\
                        "createUserID TEXT, "\
                        "isTurnOffAlerts INTEGER, "\
                        "obj TEXT"\
                        ");"];
        
        
        [db executeUpdate:
         @"CREATE TABLE IF NOT EXISTS topicEntity_runtime2 ("\
         "entityID TEXT PRIMARY KEY, "\
         "info1 TEXT, "\
         "info2 TEXT, "\
         "info3 TEXT, "\
         "info4 TEXT, "\
         "info5 TEXT, "\
         "info6 TEXT, "\
         "info7 TEXT, "\
         "info8 TEXT, "\
         "info9 TEXT, "\
         "info10 TEXT"\
         ");"];
        
        
        if (!success)
        {
            NSLog(@"topicEntity表创建失败");
        }
    }];
    return NO;
}

+(void)dropTable
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:@"DROP TABLE IF EXISTS topicEntity;"];
        
        [db executeUpdate:@"DROP TABLE IF EXISTS topicEntity_runtime2;"];
        
        if (!success)
        {
            NSLog(@"topicEntity表删除失败");
        }
    }];
}


//创建topicEntity从数据库
+(ACTopicEntity *)getTopicEntityWithFMResultSet:(FMResultSet *)resultSet
{
    __autoreleasing ACTopicEntity *topicEntity = [[ACTopicEntity alloc] init];
    
    topicEntity.entityID = [resultSet stringForColumn:@"entityID"];
    topicEntity.title = [resultSet stringForColumn:@"title"];
    topicEntity.icon = [resultSet stringForColumn:@"icon"];
    topicEntity.mpType = [resultSet stringForColumn:@"mpType"];
    topicEntity.singleChatUserID = [resultSet stringForColumn:@"singleChatUserID"];
    
    return topicEntity;
}



@end
