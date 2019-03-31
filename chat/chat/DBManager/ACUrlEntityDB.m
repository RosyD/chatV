//
//  ACUrlEntityDB.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACUrlEntityDB.h"
#import "ACDBManager.h"
#import "ACEntity.h"
#import "JSONKit.h"

@implementation ACUrlEntityDB

+(BOOL)createTable:(NSInteger)nDB_Ver
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"CREATE TABLE IF NOT EXISTS urlEntity ("\
                        "entityID TEXT PRIMARY KEY, "\
                        "updateTime DOUBLE, "\
                        "lastestSequence TEXT, "\
                        "entityType INTEGER, "\
                        "title TEXT, "\
                        "icon TEXT, "\
                        "mpType TEXT, "\
                        "url TEXT, "\
                        "createTime DOUBLE, "\
                        "createUserID TEXT, "\
                        "permString TEXT "\
                        ");"];
        if (!success)
        {
            ITLog(@"urlEntity表创建失败");
        }
    }];
    return NO;
}

+(void)dropTable
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"DROP TABLE IF EXISTS urlEntity;"];
        if (!success)
        {
            ITLog(@"urlEntity表删除失败");
        }
    }];
}

+(BOOL)saveUrlEntityToDBWithUrlEntity:(ACUrlEntity *)urlEntity
{
    __block BOOL succ;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM urlEntity "\
                         "WHERE entityID='%@' ",
                         urlEntity.entityID];
        FMResultSet *resultSet = [db executeQuery:sql];
        
        //如果有此消息,略过
        if (resultSet.next)
        {
            sql = [NSString stringWithFormat:@"UPDATE urlEntity SET "\
                   "updateTime='%lf', "\
                   "lastestSequence='%ld', "\
                   "entityType='%d', "\
                   "title='%@', "\
                   "icon='%@', "\
                   "mpType='%@', "\
                   "url='%@', "\
                   "createTime='%lf', "\
                   "createUserID='%@', "\
                   "permString='%@' "\
                   "WHERE entityID='%@' ",
                   urlEntity.updateTime,
                   urlEntity.lastestSequence,
                   urlEntity.entityType,
                   [urlEntity.title stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                   urlEntity.icon,
                   urlEntity.mpType,
                   urlEntity.url,
                   urlEntity.createTime,
                   urlEntity.createUserID,
                   urlEntity.permString,
                   urlEntity.entityID];
            [resultSet close];
        }
        else
        {
//            ITLog(([NSString stringWithFormat:@"%@",urlEntity.title]));
//            ITLog(([NSString stringWithFormat:@"%@",[urlEntity.title stringByReplacingOccurrencesOfString:@"'" withString:@"''"]]));
            sql = [NSString stringWithFormat:@"INSERT INTO urlEntity "\
                   "(entityID, updateTime, lastestSequence, entityType, title, icon, mpType, url, createTime, createUserID, permString) "\
                   "VALUES ('%@', '%lf', '%ld', '%d', '%@', '%@', '%@', '%@', '%lf', '%@', '%@')",
                   urlEntity.entityID,
                   urlEntity.updateTime,
                   urlEntity.lastestSequence,
                   urlEntity.entityType,
                   [urlEntity.title stringByReplacingOccurrencesOfString:@"'" withString:@"''"],
                   urlEntity.icon,
                   urlEntity.mpType,
                   urlEntity.url,
                   urlEntity.createTime,
                   urlEntity.createUserID,
                   urlEntity.permString];
        }
        BOOL success = NO;
        if (sql)
        {
            success = [db executeUpdate:sql];
        }
        
        if (!success)
        {
            ITLog(([NSString stringWithFormat:@"%@ urlEntity表添加记录失败",sql]));
        }
        succ = success;
    }];
    return succ;
}

//删除urlEntity
+(BOOL)deleteUrlEntityFromDBWithUrlEntityID:(NSString *)urlEntityID
{
    __block BOOL succ;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM urlEntity "\
                         "WHERE entityID='%@' ",
                         urlEntityID];
        BOOL success = [db executeUpdate:sql];
        if (!success)
        {
            ITLog(([NSString stringWithFormat:@"%@ urlEntity表删除记录失败",sql]));
        }
        succ = success;
    }];
    return succ;
}

//获取urlEntityList
+(NSMutableArray *)getUrlEntityListFromDB
{
    __block NSMutableArray *urlEntityList = [NSMutableArray arrayWithCapacity:10];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM urlEntity "\
                         "ORDER BY updateTime desc"];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet)
        {
            @autoreleasepool
            {
                while (resultSet.next)
                {
                    ACUrlEntity *urlEntity = [ACUrlEntity getUrlEntityWithFMResultSet:resultSet];
                    [urlEntityList addObject:urlEntity];
                }
            }
            [resultSet close];
        }
    }];
    return urlEntityList;
}

@end
