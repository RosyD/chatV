//
//  ACTopicEntityDB.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACTopicEntityDB.h"
#import "ACDBManager.h"
#import "ACEntity.h"
#import "JSONKit.h"
#import "ACMessageDB.h"
#import "ACDataCenter.h"

@implementation ACTopicEntityDB

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
            ITLog(@"topicEntity表创建失败");
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
            ITLog(@"topicEntity表删除失败");
        }
    }];
}


+(void)_saveTopicEntity:(ACTopicEntity *)topicEntity runtimeInfo:(NSString*)pInfo withIndexNo:(int)nNo withDB:(FMDatabase *)db{
    
    BOOL bUpdate = NO;
    NSString* pInfoTemp =   pInfo;
    if(0==pInfoTemp.length){
        bUpdate = YES;
        pInfoTemp = @"";
    }
    else{
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM topicEntity_runtime2 WHERE entityID='%@' ",
                         topicEntity.entityID];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet.next){
            bUpdate = YES;
            [resultSet close];
        }
    }
    
    
    //如果有此消息,Update
    if (bUpdate)
    {
        NSString *sql = [NSString stringWithFormat:@"UPDATE topicEntity_runtime2 SET info%d=? WHERE entityID=? ",nNo];
        [db executeUpdate:sql withArgumentsInArray:@[pInfoTemp,topicEntity.entityID]];
    }
    else
    {
        NSString *sql = @"INSERT INTO topicEntity_runtime2 "\
        "(entityID, info1, info2, info3, info4,info5,info6,info7,info8,info9,info10) "\
        "VALUES (?, ?, ?, ?, ? ,?, ?, ?, ?, ?, ?)";
        NSMutableArray* pArray = [[NSMutableArray alloc] initWithCapacity:11];
        [pArray addObject:topicEntity.entityID];
        for(int i=0;i<10;i++){
            [pArray addObject:@""];
        }
        pArray[nNo] = pInfoTemp;
        //            [pArray replaceObjectAtIndex:nNo withObject:pInfoTemp];
        [db executeUpdate:sql withArgumentsInArray:pArray];
    }
}

+(void)saveTopicEntity:(ACTopicEntity *)topicEntity runtimeInfo:(NSString*)pInfo withIndexNo:(int)nNo{
    if(nNo<1||nNo>10){
        return;
    }
    
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        FMDatabase_Enable_Error_logs(db);
        [self _saveTopicEntity:topicEntity runtimeInfo:pInfo withIndexNo:nNo withDB:db];
     }];
}


+(NSString*)_loadTopicEntity:(ACTopicEntity *)topicEntity runtimeInfoIndex:(int)nNo withDB:(FMDatabase *)db{
    
    NSString* pRetString = nil;
    NSString *sql = [NSString stringWithFormat:@"SELECT info%d FROM topicEntity_runtime2 WHERE entityID='%@' ",nNo,topicEntity.entityID];
    FMResultSet *resultSet = [db executeQuery:sql];
    if (resultSet){
        @autoreleasepool{
            if(resultSet.next){
                pRetString = [resultSet stringForColumnIndex:0];
            }
        }
        [resultSet close];
    }
    return pRetString;
}

+(NSString*)loadTopicEntity:(ACTopicEntity *)topicEntity runtimeInfoIndex:(int)nNo{
    if(nNo<1||nNo>10){
        return nil;
    }
    
    __block NSString* pRetString = nil;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        FMDatabase_Enable_Error_logs(db);
        pRetString = [self _loadTopicEntity:topicEntity runtimeInfoIndex:nNo withDB:db];
     }];
    return pRetString;
}

+(BOOL)saveTopicEntityToDBWithTopicEntity:(ACTopicEntity *)topicEntity
{
    __block BOOL succ;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM topicEntity "\
                         "WHERE entityID='%@' ",
                         topicEntity.entityID];
        FMResultSet *resultSet = [db executeQuery:sql];
        
        //如果有此消息,Update
        if (resultSet.next)
        {
            BOOL success = NO;
            NSString *sql = @"UPDATE topicEntity SET "\
            "updateTime=?, "\
            "lastestSequence=?, "\
            "entityType=?, "\
            "title=?, "\
            "icon=?, "\
            "mpType=?, "\
            "url=?, "\
            "createTime=?, "\
            "permString=?, "\
            "currentSequence=?, "\
            "isAdmin=?, "\
            "lastestTextMessage=?, "\
            "lastestMessageType=?, "\
            "lastestMessageTime=?, "\
            "lastestMessageUserID=?, "\
            "singleChatUserID=?, "\
            "relateTeID=?, "\
            "relateType=?, "\
            "relateChatUserID=?, "\
            "createUserID=?, "\
            "isTurnOffAlerts=?, "\
            "obj=? "\
            "WHERE entityID=? ";
            
            NSArray *array = [NSArray arrayWithObjects:[NSNumber numberWithDouble:topicEntity.updateTime],[NSNumber numberWithLong:topicEntity.lastestSequence],[NSNumber numberWithInt:topicEntity.entityType],topicEntity.title,topicEntity.icon,topicEntity.mpType,topicEntity.url,[NSNumber numberWithDouble:topicEntity.createTime],topicEntity.permString,[NSNumber numberWithLong:topicEntity.currentSequence],[NSNumber numberWithBool:topicEntity.isAdmin],topicEntity.lastestTextMessage,topicEntity.lastestMessageType,[NSNumber numberWithDouble:topicEntity.lastestMessageTime],topicEntity.lastestMessageUserID,topicEntity.singleChatUserID,topicEntity.relateTeID,topicEntity.relateType,topicEntity.relateChatUserID,topicEntity.createUserID,[NSNumber numberWithBool:topicEntity.isTurnOffAlerts],topicEntity.obj,topicEntity.entityID, nil];
            
            success = [db executeUpdate:sql withArgumentsInArray:array];
            
            if (!success)
            {
                ITLog(@"topicEntity表更新记录失败");
            }
            [resultSet close];
        }
        else
        {
            BOOL success = NO;
            NSString *sql = @"INSERT INTO topicEntity "\
            "(entityID, updateTime, lastestSequence, entityType, title, icon, mpType, url, createTime, permString, currentSequence, isAdmin, lastestTextMessage, lastestMessageType, lastestMessageTime, lastestMessageUserID, singleChatUserID, relateTeID, relateType, relateChatUserID, createUserID, isTurnOffAlerts, obj) "\
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?,  ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?,?,?)";
            
            NSArray *array = [NSArray arrayWithObjects:topicEntity.entityID,[NSNumber numberWithDouble:topicEntity.updateTime],[NSNumber numberWithLong:topicEntity.lastestSequence],[NSNumber numberWithInt:topicEntity.entityType],topicEntity.title,topicEntity.icon,topicEntity.mpType,topicEntity.url,[NSNumber numberWithDouble:topicEntity.createTime],topicEntity.permString,[NSNumber numberWithLong:topicEntity.currentSequence],[NSNumber numberWithBool:topicEntity.isAdmin],topicEntity.lastestTextMessage,topicEntity.lastestMessageType,[NSNumber numberWithDouble:topicEntity.lastestMessageTime],topicEntity.lastestMessageUserID,topicEntity.singleChatUserID,topicEntity.relateTeID,topicEntity.relateType,topicEntity.relateChatUserID,topicEntity.createUserID,[NSNumber numberWithBool:topicEntity.isTurnOffAlerts],topicEntity.obj, nil];
            
            success = [db executeUpdate:sql withArgumentsInArray:array];
            
            if (!success)
            {
                ITLog(@"topicEntity表添加记录失败");
            }
            succ = success;
        }
//        [self _saveTopicEntity:topicEntity
//                   runtimeInfo:[@(topicEntity.nSharingLocalUserCount) stringValue]
//                   withIndexNo:2 withDB:db];
    }];
    return succ;
}

//删除topicEntity
+(BOOL)deleteTopicEntityFromDBWithTopicEntityID:(NSString *)topicEntityID
{
    __block BOOL succ;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM topicEntity "\
                         "WHERE entityID='%@' ",
                         topicEntityID];
        BOOL success = [db executeUpdate:sql];
        if (!success)
        {
            ITLog(@"topicEntity表删除记录失败");
        }
        succ = success;
        [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM topicEntity_runtime2 "\
                                          "WHERE entityID='%@' ",
                                          topicEntityID]];
        
    }];
    [ACMessageDB deleteMessageFromDBWithTopicEntityID:topicEntityID];
    return succ;
}

//获取topicEntityList
+(NSMutableArray *)getTopicEntityListFromDB
{
    __block NSMutableArray *topicEntityList = [NSMutableArray arrayWithCapacity:10];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM topicEntity "\
                         "ORDER BY lastestMessageTime desc"];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet)
        {
            @autoreleasepool
            {
                while (resultSet.next)
                {
                    ACTopicEntity *topicEntity = [ACTopicEntity getTopicEntityWithFMResultSet:resultSet];
                    if ([topicEntity.mpType isEqualToString:cWallboard])
                    {
                        [ACDataCenter shareDataCenter].wallboardTopicEntity = topicEntity;
                    }
                    else
                    {
//                        topicEntity.nSharingLocalUserCount = [[self _loadTopicEntity:topicEntity runtimeInfoIndex:2 withDB:db] intValue];
                        [topicEntityList addObject:topicEntity];
                    }
                }
            }
            [resultSet close];
        }
    }];
    return topicEntityList;
}

@end
